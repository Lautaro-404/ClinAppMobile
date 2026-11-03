// Edge Function: mp-oauth
// Deno / Supabase Edge Runtime
// Maneja el inicio autenticado (POST) y el callback (GET) de Mercado Pago OAuth
// protegiendo contra CSRF/secuestro de vinculación (C6) y guardando tokens en merchant_secrets (C2).

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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

function jsonResponse(body: unknown, status: number, req: Request) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': getCorsOrigin(req),
      Vary: 'Origin',
    },
  });
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': getCorsOrigin(req),
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        Vary: 'Origin',
      },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const clientId = Deno.env.get('MP_APP_ID');
  const clientSecret = Deno.env.get('MP_CLIENT_SECRET');
  const redirectUri = `${supabaseUrl}/functions/v1/mp-oauth`;

  if (!clientId || !clientSecret || !supabaseUrl || !serviceKey) {
    return new Response('Configuración de aplicación incompleta en el servidor', { status: 500 });
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  // ── Modo 1: POST autenticado para iniciar vinculación y emitir state de un solo uso ──
  if (req.method === 'POST') {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'No autorizado' }, 401, req);
    }

    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    const {
      data: { user },
      error: authError,
    } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      return jsonResponse({ error: 'Sesión inválida o expirada' }, 401, req);
    }

    let body: { merchant_id?: string };
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: 'Cuerpo JSON inválido' }, 400, req);
    }

    const merchantId = body.merchant_id;
    if (!merchantId || typeof merchantId !== 'string') {
      return jsonResponse({ error: 'Falta merchant_id' }, 400, req);
    }

    const [{ data: merchant }, { data: profile }] = await Promise.all([
      supabaseAdmin.from('merchants').select('id, owner_id').eq('id', merchantId).single(),
      supabaseAdmin.from('profiles').select('rol').eq('id', user.id).single(),
    ]);

    if (!merchant) {
      return jsonResponse({ error: 'Comercio no encontrado' }, 404, req);
    }

    const esAdmin = profile?.rol === 'admin';
    const esDueno = merchant.owner_id === user.id;

    if (!esAdmin && !esDueno) {
      return jsonResponse({ error: 'No tenés permisos sobre este comercio' }, 403, req);
    }

    const nonce = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: stateError } = await supabaseAdmin.from('oauth_states').insert({
      nonce,
      merchant_id: merchantId,
      user_id: user.id,
      expires_at: expiresAt,
    });

    if (stateError) {
      console.error('Error al crear estado OAuth:', stateError);
      return jsonResponse({ error: 'No se pudo iniciar la vinculación' }, 500, req);
    }

    const authUrl = new URL('https://auth.mercadopago.com.ar/authorization');
    authUrl.searchParams.set('client_id', clientId);
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('platform_id', 'mp');
    authUrl.searchParams.set('state', nonce);
    authUrl.searchParams.set('redirect_uri', redirectUri);

    return jsonResponse({ auth_url: authUrl.toString() }, 200, req);
  }

  // ── Modo 2: GET callback de Mercado Pago ─────────────────────────────────
  const url = new URL(req.url);
  const code = url.searchParams.get('code');
  const stateNonce = url.searchParams.get('state');

  if (!code || !stateNonce) {
    return new Response('Faltan parámetros de vinculación', { status: 400 });
  }

  // Consumir el nonce de un solo uso y verificar expiración
  const { data: oauthState, error: stateLookupError } = await supabaseAdmin
    .from('oauth_states')
    .delete()
    .eq('nonce', stateNonce)
    .select('merchant_id, expires_at')
    .single();

  if (stateLookupError || !oauthState) {
    return new Response('Estado de vinculación inválido o ya utilizado', { status: 403 });
  }

  if (new Date(oauthState.expires_at) < new Date()) {
    return new Response('La solicitud de vinculación expiró. Intentá de nuevo.', { status: 403 });
  }

  try {
    // 1. Intercambiar el Authorization Code por el Access Token
    const tokenResponse = await fetch('https://api.mercadopago.com/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        grant_type: 'authorization_code',
        code,
        redirect_uri: redirectUri,
      }).toString(),
    });

    if (!tokenResponse.ok) {
      const errText = await tokenResponse.text();
      console.error('Error de MP OAuth:', errText);
      return new Response('Error al autorizar con Mercado Pago', { status: 502 });
    }

    const tokenData = (await tokenResponse.json()) as {
      access_token: string;
      refresh_token: string;
      user_id: number;
    };

    // 2. Guardar los tokens en la tabla privada merchant_secrets (solo service_role)
    const { error: dbError } = await supabaseAdmin.from('merchant_secrets').upsert({
      merchant_id: oauthState.merchant_id,
      mp_access_token: tokenData.access_token,
      mp_refresh_token: tokenData.refresh_token,
      mp_user_id: tokenData.user_id.toString(),
      updated_at: new Date().toISOString(),
    });

    if (dbError) {
      console.error('Error DB:', dbError);
      return new Response('Error al guardar credenciales', { status: 500 });
    }

    // 3. Redirigir de vuelta a la app (panel del local)
    const frontendUrl = Deno.env.get('FRONTEND_URL') || 'https://clin-app-ivory.vercel.app';
    return Response.redirect(`${frontendUrl}/panel/vinculacion-exitosa`, 302);
  } catch (error) {
    console.error('Excepción en mp-oauth:', error);
    return new Response('Error interno', { status: 500 });
  }
});
