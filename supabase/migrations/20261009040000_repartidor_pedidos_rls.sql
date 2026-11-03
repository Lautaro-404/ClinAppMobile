-- =============================================================
-- Migración: Permisos RLS y función atómica para repartidores
-- =============================================================

-- 1. Actualizar políticas de orders para repartidor
-- Permitir ver pedidos asignados al usuario O disponibles para retirar
DROP POLICY IF EXISTS "Pedidos – repartidor SELECT asignados" ON public.orders;
DROP POLICY IF EXISTS "Pedidos – repartidor SELECT disponibles y asignados" ON public.orders;

CREATE POLICY "Pedidos – repartidor SELECT disponibles y asignados"
  ON public.orders FOR SELECT
  USING (
    courier_id = auth.uid()
    OR (courier_id IS NULL AND estado = 'listo_para_retirar')
  );

-- Permitir tomar pedidos disponibles o actualizar pedidos asignados propios
DROP POLICY IF EXISTS "Pedidos – repartidor UPDATE asignados" ON public.orders;
DROP POLICY IF EXISTS "Pedidos – repartidor UPDATE tomar y gestionar" ON public.orders;

CREATE POLICY "Pedidos – repartidor UPDATE tomar y gestionar"
  ON public.orders FOR UPDATE
  USING (
    courier_id = auth.uid()
    OR (courier_id IS NULL AND estado = 'listo_para_retirar')
  )
  WITH CHECK (
    courier_id = auth.uid()
  );

-- 2. Permisos para que el repartidor pueda ver la dirección de entrega
DROP POLICY IF EXISTS "Direcciones – repartidor SELECT pedidos" ON public.addresses;
CREATE POLICY "Direcciones – repartidor SELECT pedidos"
  ON public.addresses FOR SELECT
  USING (
    profile_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.address_id = addresses.id
        AND (
          o.courier_id = auth.uid()
          OR (o.courier_id IS NULL AND o.estado = 'listo_para_retirar')
        )
    )
  );

-- 3. Permisos para que el repartidor pueda ver datos básicos del cliente (nombre, teléfono)
DROP POLICY IF EXISTS "Perfiles – repartidor SELECT clientes de pedidos" ON public.profiles;
CREATE POLICY "Perfiles – repartidor SELECT clientes de pedidos"
  ON public.profiles FOR SELECT
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.user_id = profiles.id
        AND (
          o.courier_id = auth.uid()
          OR (o.courier_id IS NULL AND o.estado = 'listo_para_retirar')
        )
    )
  );

-- 4. Permisos para que el repartidor pueda ver el método de pago (para saber si cobra en efectivo)
DROP POLICY IF EXISTS "Pagos – repartidor SELECT pedidos" ON public.payments;
CREATE POLICY "Pagos – repartidor SELECT pedidos"
  ON public.payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = payments.order_id
        AND (
          o.courier_id = auth.uid()
          OR (o.courier_id IS NULL AND o.estado = 'listo_para_retirar')
        )
    )
  );

-- 5. Permitir que clientes y administradores vean la ubicación del repartidor asignado a su pedido
DROP POLICY IF EXISTS "Ubicación courier – SELECT clientes de pedido" ON public.courier_locations;
CREATE POLICY "Ubicación courier – SELECT clientes de pedido"
  ON public.courier_locations FOR SELECT
  USING (
    courier_id = auth.uid()
    OR public.current_user_rol() = 'admin'
    OR EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.courier_id = courier_locations.courier_id
        AND o.estado IN ('listo_para_retirar', 'en_camino')
        AND o.user_id = auth.uid()
    )
  );

-- 6. Agregar courier_locations a Realtime si no está
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'courier_locations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.courier_locations;
  END IF;
END $$;

-- 7. Función RPC atómica para tomar pedidos de forma segura
CREATE OR REPLACE FUNCTION public.tomar_pedido(p_order_id UUID)
RETURNS public.orders AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_courier_id UUID := auth.uid();
BEGIN
  IF v_courier_id IS NULL THEN
    RAISE EXCEPTION 'No autorizado' USING ERRCODE = '42501';
  END IF;

  -- Bloquear fila para evitar condiciones de carrera si dos repartidores presionan a la vez
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

  IF v_order.estado NOT IN ('listo_para_retirar', 'en_preparacion') THEN
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

GRANT EXECUTE ON FUNCTION public.tomar_pedido(UUID) TO authenticated;
