-- Habilitar extensión pg_net si no existe
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Función para invocar el webhook
CREATE OR REPLACE FUNCTION notify_order_status_changed()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url text := 'https://fgispkpvxftxdlnbnvpo.supabase.co/functions/v1/send-push';
  anon_key text := current_setting('request.jwt.claim.anon_key', true); -- O podemos dejar que se pase desde la constante del config
BEGIN
  -- Usamos pg_net para enviar la notificación
  perform net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || current_setting('request.jwt.claim.role', true)),
      body := jsonb_build_object('record', row_to_json(NEW), 'old_record', row_to_json(OLD))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
DROP TRIGGER IF EXISTS order_status_changed_push ON public.orders;
CREATE TRIGGER order_status_changed_push
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_order_status_changed();
