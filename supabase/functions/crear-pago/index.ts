// Edge Function: crear-pago
// Deno / Supabase Edge Runtime
// Crea una preferencia de pago en Mercado Pago para un pedido existente.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const DEFAULT_ALLOWED_ORIGINS = [
  'https://clin-app-ivory.vercel.app',
  'https://clin.app',
  'https://www.clin.app',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
];

function getCorsOrigin(req?: Request): string {
  const envOrigins = Deno.env.get('ALLOWED_ORIGINS');
  const allowed = envOrigins
    ? envOrigins.split(',').map((o) => o.trim()).filter(Boolean)
    : DEFAULT_ALLOWED_ORIGINS;
  const reqOrigin = req?.headers.get('Origin') ?? '';
  if (reqOrigin && allowed.includes(reqOrigin)) {
    return reqOrigin;
  }
  return allowed[0] ?? 'https://clin-app-ivory.vercel.app';
}

function jsonOk(data: unknown, status = 200, req?: Request) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': getCorsOrigin(req),
      Vary: 'Origin',
    },
  });
}

function jsonError(mensaje: string, status = 400, req?: Request) {
  return new Response(JSON.stringify({ error: mensaje }), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': getCorsOrigin(req),
      Vary: 'Origin',
    },
  });
}

// ─── Handler principal ───────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': getCorsOrigin(req),
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        Vary: 'Origin',
      },
    });
  }

  // ── 1. Autenticación ──────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return jsonError('No autorizado', 401, req);

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN') ?? '';
  const appBaseUrl = Deno.env.get('APP_BASE_URL') ?? 'https://clin.app';

  if (!mpAccessToken) {
    console.error('MP_ACCESS_TOKEN no configurado');
    return jsonError('Configuración de pagos incompleta', 500, req);
  }

  const supabaseUser = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const supabaseAdmin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseUser.auth.getUser();

  if (authError || !user) return jsonError('No autorizado', 401, req);

  // ── 2. Parsear cuerpo ─────────────────────────────────────────────────────
  let body: { order_id: string };
  try {
    body = await req.json();
  } catch {
    return jsonError('Cuerpo JSON inválido', 400, req);
  }

  const { order_id } = body;
  if (!order_id || typeof order_id !== 'string') return jsonError('Falta order_id', 400, req);

  // ── 3. Verificar pedido en la BD ──────────────────────────────────────────
  const { data: order, error: orderError } = await supabaseAdmin
    .from('orders')
    .select('id, user_id, total, subtotal, envio, propina, descuento, estado, merchant_id, merchants(name, comision_porcentaje)')
    .eq('id', order_id)
    .single();

  if (orderError || !order) return jsonError('Pedido no encontrado', 404, req);
  if (order.user_id !== user.id) return jsonError('No autorizado', 403, req);
  if (order.estado !== 'pago_pendiente') {
    return jsonError(`El pedido no está en estado de pago pendiente (estado: ${order.estado})`, 400, req);
  }
  if (order.total <= 0) return jsonError('El total del pedido es inválido', 400, req);

  // ── 4. Obtener datos del perfil del usuario y credenciales MP del comercio ─
  const [{ data: profile }, { data: merchantSecret }] = await Promise.all([
    supabaseAdmin
      .from('profiles')
      .select('nombre, telefono')
      .eq('id', user.id)
      .single(),
    supabaseAdmin
      .from('merchant_secrets')
      .select('mp_access_token')
      .eq('merchant_id', order.merchant_id)
      .maybeSingle(),
  ]);

  // ── 5. Crear preferencia en Mercado Pago ──────────────────────────────────
  type MerchantRef = { name: string; comision_porcentaje?: number | null } | null;
  const merchantData = order.merchants as MerchantRef;
  const merchantName = merchantData?.name ?? 'Clin';
  const totalEnPesos = order.total / 100; // MP recibe en unidad entera (pesos)

  // Split de pagos (Marketplace) desde tabla privada merchant_secrets
  const tokenLocal = (merchantSecret as { mp_access_token?: string | null } | null)?.mp_access_token;
  const usarSplit = !!tokenLocal;
  // El token a usar: si el local está vinculado, usamos el suyo. Si no, usamos el de la app.
  const tokenMPFinal = usarSplit ? tokenLocal : mpAccessToken;

  let marketplaceFee: number | undefined = undefined;
  if (usarSplit) {
    const porcentaje = merchantData?.comision_porcentaje ?? 10;
    // Comisión sobre el subtotal de los productos
    const feeComision = Math.floor((order.subtotal * porcentaje) / 100);
    // El marketplace fee incluye la comisión de la app, el envío y la propina (que la app le pagará luego al repartidor)
    const feeTotalCentavos = feeComision + order.envio + order.propina;
    marketplaceFee = feeTotalCentavos / 100;
    
    // Validar que el fee no sea mayor al total (caso extremo con cupones grandes)
    if (marketplaceFee >= totalEnPesos) {
      marketplaceFee = totalEnPesos - 1; // Debe quedar algo para el seller, o no usar split
      if (marketplaceFee < 0) marketplaceFee = 0;
    }
  }

  const preferenceBody: any = {
    items: [
      {
        id: order_id,
        title: `Pedido en ${merchantName}`,
        description: `Pedido Clin #${order_id.slice(0, 8).toUpperCase()}`,
        quantity: 1,
        currency_id: 'ARS',
        unit_price: totalEnPesos,
      },
    ],
    payer: {
      email: user.email ?? undefined,
      name: profile?.nombre ?? undefined,
      phone: profile?.telefono
        ? { area_code: '', number: profile.telefono }
        : undefined,
    },
    back_urls: {
      success: `${appBaseUrl}/pago/resultado?estado=aprobado&pedido=${order_id}`,
      failure: `${appBaseUrl}/pago/resultado?estado=rechazado&pedido=${order_id}`,
      pending: `${appBaseUrl}/pago/resultado?estado=pendiente&pedido=${order_id}`,
    },
    auto_return: 'approved',
    external_reference: order_id,
    // Notificaciones IPN (webhook)
    notification_url: `${supabaseUrl}/functions/v1/webhook-mercadopago`,
    statement_descriptor: 'CLIN DELIVERY',
    expires: false,
    metadata: {
      order_id,
      user_id: user.id,
    },
  };

  if (usarSplit && marketplaceFee && marketplaceFee > 0) {
    preferenceBody.marketplace_fee = marketplaceFee;
  }

  const mpResponse = await fetch('https://api.mercadopago.com/checkout/preferences', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenMPFinal}`,
    },
    body: JSON.stringify(preferenceBody),
  });

  if (!mpResponse.ok) {
    const mpError = await mpResponse.text();
    console.error('Error al crear preferencia MP:', mpResponse.status, mpError);
    return jsonError('Error al inicializar el pago. Intentá de nuevo.', 502);
  }

  const preference = await mpResponse.json() as {
    id: string;
    init_point: string;
    sandbox_init_point: string;
  };

  // ── 6. Guardar preference_id en el registro de pago ───────────────────────
  // Buscamos el payment ya creado por crear-pedido y le actualizamos el external_id
  const { data: existingPayment } = await supabaseAdmin
    .from('payments')
    .select('id')
    .eq('order_id', order_id)
    .eq('method', 'mercado_pago')
    .maybeSingle();

  if (existingPayment) {
    await supabaseAdmin
      .from('payments')
      .update({ external_id: preference.id, status: 'preferencia_creada' })
      .eq('id', existingPayment.id);
  } else {
    await supabaseAdmin.from('payments').insert({
      order_id,
      method: 'mercado_pago',
      amount: order.total,
      status: 'preferencia_creada',
      external_id: preference.id,
    });
  }

  // ── 7. Respuesta ──────────────────────────────────────────────────────────
  // sandbox_init_point para pruebas, init_point para producción
  const esSandbox = tokenMPFinal.startsWith('TEST-');
  const checkoutUrl = esSandbox ? preference.sandbox_init_point : preference.init_point;

  return jsonOk({
    preference_id: preference.id,
    checkout_url: checkoutUrl,
  });
});
