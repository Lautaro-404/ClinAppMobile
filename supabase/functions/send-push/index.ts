import { serve } from "https://deno.land/std@0.192.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import webpush from "https://esm.sh/web-push@3.6.4"

webpush.setVapidDetails(
  Deno.env.get('VAPID_SUBJECT') ?? 'mailto:soporte@clin.com.ar',
  Deno.env.get('VAPID_PUBLIC_KEY') ?? '',
  Deno.env.get('VAPID_PRIVATE_KEY') ?? ''
);

function timingSafeEqualStr(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

async function sendFcmNotification(
  token: string,
  title: string,
  body: string,
  orderId: string,
): Promise<{ success: boolean; shouldDelete: boolean }> {
  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');

  if (fcmServerKey) {
    try {
      const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          to: token,
          notification: {
            title,
            body,
            sound: 'default',
          },
          data: {
            order_id: orderId,
            url: `/pedidos/${orderId}`,
            title,
            body,
          },
          priority: 'high',
        }),
      });

      if (!response.ok) {
        return {
          success: false,
          shouldDelete: response.status === 404 || response.status === 410,
        };
      }

      const resJson = await response.json();
      const hasError = resJson.results?.[0]?.error;
      const isInvalid =
        hasError === 'NotRegistered' || hasError === 'InvalidRegistration';
      return { success: !hasError, shouldDelete: isInvalid };
    } catch (err) {
      console.error('Error enviando FCM:', err);
      return { success: false, shouldDelete: false };
    }
  }

  console.warn(
    `[send-push] Suscripción móvil detectada (${token.slice(0, 10)}...). Configurá FCM_SERVER_KEY en los secretos de Supabase para habilitar despacho FCM.`,
  );
  return { success: false, shouldDelete: false };
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Método no permitido' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 405,
    })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const webhookSecret = Deno.env.get('PUSH_WEBHOOK_SECRET') ?? ''

    // 1. Verificar secreto de webhook si está configurado, o service_role key
    if (webhookSecret) {
      const providedSecret = req.headers.get('x-webhook-secret') ?? ''
      if (!timingSafeEqualStr(providedSecret, webhookSecret)) {
        return new Response(JSON.stringify({ error: 'No autorizado' }), {
          headers: { 'Content-Type': 'application/json' },
          status: 401,
        })
      }
    } else {
      const authHeader = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '').trim()
      const esServiceRole = serviceRoleKey && timingSafeEqualStr(authHeader, serviceRoleKey)
      const esTriggerInterno = authHeader === 'authenticated' || authHeader === 'postgres' || authHeader === 'service_role'
      if (!esServiceRole && !esTriggerInterno) {
        return new Response(JSON.stringify({ error: 'No autorizado' }), {
          headers: { 'Content-Type': 'application/json' },
          status: 401,
        })
      }
    }

    const payload = await req.json()
    const record = payload?.record
    const oldRecord = payload?.old_record

    if (!record?.id || !oldRecord || record.estado === oldRecord.estado) {
      return new Response(JSON.stringify({ message: "Sin cambio de estado" }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    })

    // 2. Re-leer el pedido real desde la BD para no confiar en el payload entrante
    const { data: orderReal, error: orderErr } = await supabaseAdmin
      .from('orders')
      .select('id, user_id, estado, updated_at')
      .eq('id', String(record.id))
      .single()

    if (orderErr || !orderReal) {
      return new Response(JSON.stringify({ error: 'Pedido no encontrado' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 404,
      })
    }

    // Verificar que el estado actual en BD coincida con el reportado y sea reciente (<= 2 min)
    const updatedMs = new Date(orderReal.updated_at).getTime()
    if (
      orderReal.estado !== record.estado ||
      orderReal.user_id !== record.user_id ||
      Number.isNaN(updatedMs) ||
      Date.now() - updatedMs > 2 * 60 * 1000
    ) {
      return new Response(JSON.stringify({ error: 'Estado de pedido no verificado' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 403,
      })
    }

    let title = ""
    let message = ""

    switch (orderReal.estado) {
      case 'confirmado':
        title = "¡Pedido Confirmado!"
        message = "Tu pedido ha sido confirmado y está siendo preparado."
        break
      case 'en_camino':
        title = "¡Pedido en Camino!"
        message = "Tu pedido ya salió del local y va hacia vos."
        break
      case 'entregado':
        title = "¡Pedido Entregado!"
        message = "¡Esperamos que lo disfrutes!"
        break
      case 'cancelado':
      case 'rechazado':
        title = "Pedido Cancelado"
        message = "Tu pedido ha sido cancelado. Contactá a soporte para más detalles."
        break
      default:
        return new Response(JSON.stringify({ message: "Estado ignorado" }), {
          headers: { 'Content-Type': 'application/json' },
          status: 200,
        })
    }

    await supabaseAdmin.from('notifications').insert({
      user_id: orderReal.user_id,
      title,
      message,
      is_read: false,
    })

    // Buscar suscripciones PUSH del usuario real del pedido
    const { data: subs } = await supabaseAdmin
      .from('push_subscriptions')
      .select('*')
      .eq('user_id', orderReal.user_id)

    if (subs && subs.length > 0) {
      const pushPayload = JSON.stringify({
        title,
        body: message,
        url: `/pedidos/${orderReal.id}`,
      })

      for (const sub of subs) {
        const isFcm =
          sub.p256dh === 'fcm' ||
          sub.p256dh === 'android' ||
          sub.p256dh === 'ios' ||
          sub.p256dh === 'mobile' ||
          sub.auth === 'fcm' ||
          !sub.endpoint.startsWith('http');

        if (isFcm) {
          const { shouldDelete } = await sendFcmNotification(
            sub.endpoint,
            title,
            message,
            String(orderReal.id),
          );
          if (shouldDelete) {
            await supabaseAdmin.from('push_subscriptions').delete().eq('id', sub.id);
          }
          continue;
        }

        const pushSubscription = {
          endpoint: sub.endpoint,
          keys: {
            p256dh: sub.p256dh,
            auth: sub.auth,
          },
        }

        try {
          await webpush.sendNotification(pushSubscription, pushPayload)
        } catch (err: unknown) {
          const statusCode = (err as { statusCode?: number })?.statusCode
          if (statusCode === 410 || statusCode === 404) {
            await supabaseAdmin.from('push_subscriptions').delete().eq('id', sub.id)
          } else {
            console.error('Error sending push:', err)
          }
        }
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Error en send-push:', error)
    return new Response(JSON.stringify({ error: 'Error al procesar la notificación' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
