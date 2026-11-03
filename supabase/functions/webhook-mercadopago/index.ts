// Edge Function: webhook-mercadopago
// Deno / Supabase Edge Runtime
// Recibe notificaciones IPN de Mercado Pago, verifica la firma HMAC-SHA256,
// consulta el estado del pago y actualiza payments + orders.
// Es idempotente: procesar dos veces la misma notificación no duplica nada.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createHmac } from 'https://deno.land/std@0.177.0/node/crypto.ts';

// ─── Tipos de Mercado Pago ────────────────────────────────────────────────────

interface MpPaymentResponse {
  id: number;
  status: string; // approved | pending | rejected | cancelled | refunded | charged_back
  status_detail: string;
  external_reference: string; // nuestro order_id
  transaction_amount: number;
  currency_id: string;
  date_approved: string | null;
  date_last_updated: string;
  order: { id: number; type: string } | null;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function jsonOk(data: unknown = { ok: true }) {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

function jsonError(mensaje: string, status = 400) {
  return new Response(JSON.stringify({ error: mensaje }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function timingSafeEqualStr(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

/**
 * Verifica la firma HMAC-SHA256 que Mercado Pago incluye en el header
 * x-signature para evitar notificaciones falsas.
 * Docs: https://www.mercadopago.com.ar/developers/es/docs/your-integrations/notifications/webhooks
 */
async function verificarFirmaMP(req: Request, _rawBody: string, secret: string): Promise<boolean> {
  const signature = req.headers.get('x-signature');
  const requestId = req.headers.get('x-request-id');
  const dataId = new URL(req.url).searchParams.get('data.id');

  if (!signature || !requestId || !dataId) {
    // En modo sandbox MP puede no enviar la firma
    const esSandbox = Deno.env.get('MP_ACCESS_TOKEN')?.startsWith('TEST-') ?? false;
    if (esSandbox) {
      console.warn('Firma ausente: modo sandbox, se omite verificación');
      return true;
    }
    return false;
  }

  // El formato es: ts=<timestamp>,v1=<hmac>
  const partes = Object.fromEntries(signature.split(',').map((p) => p.split('=')));
  const ts = partes['ts'];
  const v1 = partes['v1'];

  if (!ts || !v1) return false;

  // Mensaje firmado: id;request-id;ts;
  const mensaje = `id:${dataId};request-id:${requestId};ts:${ts};`;

  const hmac = createHmac('sha256', secret);
  hmac.update(mensaje);
  const calculado = hmac.digest('hex');

  return timingSafeEqualStr(calculado, v1);
}

/**
 * Traduce el estado de MP a nuestro estado de orden.
 */
function mpStatusToOrderStatus(
  mpStatus: string,
): 'confirmado' | 'cancelado' | null {
  switch (mpStatus) {
    case 'approved':
      return 'confirmado';
    case 'rejected':
    case 'cancelled':
    case 'charged_back':
      return 'cancelado';
    default:
      // pending, in_process, authorized -> no cambiamos el estado de la orden
      return null;
  }
}

// ─── Handler principal ───────────────────────────────────────────────────────

serve(async (req: Request) => {
  const mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN') ?? '';
  const mpWebhookSecret = Deno.env.get('MP_WEBHOOK_SECRET') ?? '';
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  if (!mpAccessToken) {
    console.error('MP_ACCESS_TOKEN no configurado');
    return jsonError('Configuración incompleta', 500);
  }

  // ── 1. Leer cuerpo raw ────────────────────────────────────────────────────
  const rawBody = await req.text();

  // ── 2. Verificar firma ────────────────────────────────────────────────────
  if (mpWebhookSecret) {
    const firmaValida = await verificarFirmaMP(req, rawBody, mpWebhookSecret);
    if (!firmaValida) {
      console.error('Firma de webhook inválida');
      return jsonError('Firma inválida', 401);
    }
  }

  // ── 3. Parsear notificación ───────────────────────────────────────────────
  let notif: { type?: string; data?: { id?: string }; action?: string };
  try {
    notif = JSON.parse(rawBody);
  } catch {
    return jsonError('JSON inválido');
  }

  // MP envía distintos tipos de notificaciones; solo procesamos pagos
  if (notif.type !== 'payment' && notif.action !== 'payment.created' && notif.action !== 'payment.updated') {
    console.log('Notificación ignorada, tipo:', notif.type, 'action:', notif.action);
    return jsonOk({ ignorado: true });
  }

  // El ID del pago puede venir en data.id o en el query string (IPN legacy)
  const url = new URL(req.url);
  const queryDataId = url.searchParams.get('data.id') ?? url.searchParams.get('id');
  if (queryDataId && notif.data?.id && String(queryDataId) !== String(notif.data.id)) {
    return jsonError('Discrepancia en el ID de pago firmado', 401);
  }

  const mpPaymentId = notif.data?.id ?? queryDataId;

  if (!mpPaymentId) {
    console.error('No se encontró ID de pago en la notificación');
    return jsonError('ID de pago ausente');
  }

  // En producción (token no-TEST), MP_WEBHOOK_SECRET es obligatorio para procesar un pago
  if (!mpWebhookSecret && !mpAccessToken.startsWith('TEST-')) {
    console.error('MP_WEBHOOK_SECRET no configurado en producción');
    return jsonError('Configuración de webhook incompleta', 500);
  }

  // ── 4. Consultar estado real del pago en MP ───────────────────────────────
  const mpRes = await fetch(`https://api.mercadopago.com/v1/payments/${encodeURIComponent(String(mpPaymentId))}`, {
    headers: { Authorization: `Bearer ${mpAccessToken}` },
  });

  if (!mpRes.ok) {
    console.error('Error al consultar pago en MP:', mpRes.status, await mpRes.text());
    return jsonError('Error al consultar Mercado Pago', 502);
  }

  const mpPayment = (await mpRes.json()) as MpPaymentResponse;
  const orderId = mpPayment.external_reference;

  if (!orderId) {
    console.error('Pago de MP sin external_reference:', mpPaymentId);
    return jsonOk({ ignorado: true, razon: 'sin external_reference' });
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  // ── 5. Idempotencia: verificar si ya procesamos este pago con este estado ──
  const { data: paymentExistente } = await supabaseAdmin
    .from('payments')
    .select('id, status, external_id')
    .eq('order_id', orderId)
    .eq('method', 'mercado_pago')
    .maybeSingle();

  const nuevoStatusPago = mpPayment.status; // approved, rejected, pending...

  if (paymentExistente && paymentExistente.status === nuevoStatusPago) {
    console.log(`Pago ${mpPaymentId} ya procesado con status: ${nuevoStatusPago}. Ignorando.`);
    return jsonOk({ idempotente: true });
  }

  const montoPagadoCentavos = Math.round((mpPayment.transaction_amount ?? 0) * 100);

  // ── 6. Actualizar tabla payments ──────────────────────────────────────────
  if (paymentExistente) {
    await supabaseAdmin
      .from('payments')
      .update({
        status: nuevoStatusPago,
        external_id: String(mpPayment.id),
      })
      .eq('id', paymentExistente.id);
  } else {
    // Caso borde: el pago no existía (puede pasar si el webhook llega antes que crear-pago termine)
    await supabaseAdmin.from('payments').insert({
      order_id: orderId,
      method: 'mercado_pago',
      amount: montoPagadoCentavos, // en centavos
      status: nuevoStatusPago,
      external_id: String(mpPayment.id),
    });
  }

  // ── 7. Actualizar estado de la orden ──────────────────────────────────────
  const nuevoEstadoOrden = mpStatusToOrderStatus(nuevoStatusPago);

  if (nuevoEstadoOrden) {
    // Solo actualizamos si el pedido está en estado que lo permite
    // (pago_pendiente → confirmado o cancelado)
    const { data: orden } = await supabaseAdmin
      .from('orders')
      .select('id, estado, total')
      .eq('id', orderId)
      .single();

    if (orden && orden.estado === 'pago_pendiente') {
      const totalEsperado = (orden as { total?: number }).total;
      if (
        nuevoEstadoOrden === 'confirmado' &&
        typeof totalEsperado === 'number' &&
        totalEsperado > 0 &&
        montoPagadoCentavos < totalEsperado
      ) {
        console.error(
          `Monto pagado insuficiente para pedido ${orderId}: pagado=${montoPagadoCentavos}, esperado=${totalEsperado}`,
        );
        return jsonError('El monto abonado no coincide con el total del pedido', 400);
      }

      if (
        nuevoEstadoOrden === 'confirmado' &&
        mpPayment.currency_id &&
        mpPayment.currency_id !== 'ARS'
      ) {
        console.error(`Moneda inválida en pago ${mpPaymentId}: ${mpPayment.currency_id}`);
        return jsonError('Moneda de pago inválida', 400);
      }

      await supabaseAdmin
        .from('orders')
        .update({ estado: nuevoEstadoOrden })
        .eq('id', orderId);

      console.log(`Pedido ${orderId}: pago_pendiente → ${nuevoEstadoOrden} (MP status: ${nuevoStatusPago})`);
    } else {
      console.log(`Pedido ${orderId} ya en estado ${orden?.estado}, no se actualiza.`);
    }
  }

  return jsonOk({
    procesado: true,
    order_id: orderId,
    mp_payment_id: mpPaymentId,
    mp_status: nuevoStatusPago,
    nuevo_estado_orden: nuevoEstadoOrden,
  });
});
