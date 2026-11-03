-- Actualizar el RPC tomar_pedido para permitir aceptar pedidos 'aceptado_por_local'
CREATE OR REPLACE FUNCTION public.tomar_pedido(p_order_id UUID)
RETURNS public.orders AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_courier_id UUID := auth.uid();
BEGIN
  IF v_courier_id IS NULL THEN
    RAISE EXCEPTION 'No autorizado' USING ERRCODE = '42501';
  END IF;

  -- Bloquear fila para evitar condiciones de carrera
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido no encontrado' USING ERRCODE = 'P0002';
  END IF;

  IF v_order.courier_id IS NOT NULL THEN
    RAISE EXCEPTION 'El pedido ya fue tomado por otro repartidor' USING ERRCODE = 'P0001';
  END IF;

  IF v_order.estado NOT IN ('listo_para_retirar', 'en_preparacion', 'aceptado_por_local') THEN
    RAISE EXCEPTION 'El pedido no está disponible para ser tomado' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.orders
  SET courier_id = v_courier_id,
      updated_at = now()
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  RETURN v_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Actualizar las políticas RLS
DROP POLICY IF EXISTS "Pedidos – repartidor SELECT disponibles y asignados" ON public.orders;

CREATE POLICY "Pedidos – repartidor SELECT disponibles y asignados"
  ON public.orders FOR SELECT
  USING (
    courier_id = auth.uid()
    OR (courier_id IS NULL AND estado IN ('listo_para_retirar', 'en_preparacion', 'aceptado_por_local'))
  );

DROP POLICY IF EXISTS "Pedidos – repartidor UPDATE tomar y gestionar" ON public.orders;

CREATE POLICY "Pedidos – repartidor UPDATE tomar y gestionar"
  ON public.orders FOR UPDATE
  USING (
    courier_id = auth.uid()
    OR (courier_id IS NULL AND estado IN ('listo_para_retirar', 'en_preparacion', 'aceptado_por_local'))
  );
