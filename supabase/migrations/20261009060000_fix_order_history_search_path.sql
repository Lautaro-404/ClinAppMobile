-- Fix missing public schema prefix in log_order_status_change trigger
CREATE OR REPLACE FUNCTION public.log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.estado IS DISTINCT FROM OLD.estado THEN
    INSERT INTO public.order_status_history (order_id, estado, notes)
    VALUES (
      NEW.id,
      NEW.estado,
      NULLIF(COALESCE(current_setting('app.panel_notas', true), ''), '')
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
