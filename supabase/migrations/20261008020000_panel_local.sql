-- =============================================================
--  Panel de comercios (/panel)
--  Migración: 20261008020000_panel_local.sql
--
--  Contenido:
--   1. orders.tiempo_estimado_min (lo informa el local al aceptar)
--   2. order_item_options (opciones elegidas en cada ítem, snapshot)
--   3. Índices para el tablero y para las políticas RLS nuevas
--   4. RLS: el local ve dirección, cliente y método de pago de SU pedido
--   5. Realtime sobre orders (aviso de pedidos nuevos)
--   6. Historial de estados con notas (motivo de rechazo / tiempo estimado)
--   7. RPC panel_cambiar_estado(): única vía del panel para cambiar estado
-- =============================================================

-- -------------------------------------------------------------
-- 1. Tiempo estimado informado por el local
-- -------------------------------------------------------------
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS tiempo_estimado_min INTEGER;

-- -------------------------------------------------------------
-- 2. Opciones seleccionadas por ítem
--     Se guarda una copia del nombre/modificador para que el
--     pedido histórico no cambie si el menú cambia después.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_item_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_item_id UUID NOT NULL REFERENCES public.order_items(id) ON DELETE CASCADE,
  option_id UUID REFERENCES public.product_options(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  price_modifier INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.order_item_options ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_order_item_options_item
  ON public.order_item_options(order_item_id);
CREATE INDEX IF NOT EXISTS idx_order_item_options_option
  ON public.order_item_options(option_id);

-- -------------------------------------------------------------
-- 3. Índices de apoyo
-- -------------------------------------------------------------
-- La política RLS de addresses/ profiles recorre orders por dirección.
CREATE INDEX IF NOT EXISTS idx_orders_address
  ON public.orders(address_id);
-- Consulta principal del tablero: pedidos de mi comercio, más nuevos primero.
CREATE INDEX IF NOT EXISTS idx_orders_merchant_created
  ON public.orders(merchant_id, created_at DESC);

-- -------------------------------------------------------------
-- 4. RLS nuevas
-- -------------------------------------------------------------

-- 4a. Opciones de los ítems: cliente ve las de sus pedidos,
--     local las de los pedidos de su comercio.
DROP POLICY IF EXISTS "Items del pedido – cliente SELECT de sus pedidos"
  ON public.order_item_options;
CREATE POLICY "Items del pedido – cliente SELECT de sus pedidos"
  ON public.order_item_options FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      WHERE oi.id = order_item_options.order_item_id
        AND o.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Items del pedido – local SELECT de su merchant"
  ON public.order_item_options;
CREATE POLICY "Items del pedido – local SELECT de su merchant"
  ON public.order_item_options FOR SELECT
  USING (
    (SELECT public.current_user_rol()) = 'local'
    AND EXISTS (
      SELECT 1
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      JOIN public.merchants m ON m.id = o.merchant_id
      WHERE oi.id = order_item_options.order_item_id
        AND m.owner_id = (SELECT auth.uid())
    )
  );

-- 4b. Dirección de entrega del pedido (antes solo la veía su dueña).
DROP POLICY IF EXISTS "Direcciones – local SELECT de pedidos de su merchant"
  ON public.addresses;
CREATE POLICY "Direcciones – local SELECT de pedidos de su merchant"
  ON public.addresses FOR SELECT
  USING (
    (SELECT public.current_user_rol()) = 'local'
    AND EXISTS (
      SELECT 1
      FROM public.orders o
      JOIN public.merchants m ON m.id = o.merchant_id
      WHERE o.address_id = addresses.id
        AND m.owner_id = (SELECT auth.uid())
    )
  );

-- 4c. Datos básicos del cliente que hizo el pedido.
DROP POLICY IF EXISTS "Perfiles – local SELECT clientes de su merchant"
  ON public.profiles;
CREATE POLICY "Perfiles – local SELECT clientes de su merchant"
  ON public.profiles FOR SELECT
  USING (
    (SELECT public.current_user_rol()) = 'local'
    AND EXISTS (
      SELECT 1
      FROM public.orders o
      JOIN public.merchants m ON m.id = o.merchant_id
      WHERE o.user_id = profiles.id
        AND m.owner_id = (SELECT auth.uid())
    )
  );

-- 4d. Método de pago del pedido.
DROP POLICY IF EXISTS "Pagos – local SELECT de pedidos de su merchant"
  ON public.payments;
CREATE POLICY "Pagos – local SELECT de pedidos de su merchant"
  ON public.payments FOR SELECT
  USING (
    (SELECT public.current_user_rol()) = 'local'
    AND EXISTS (
      SELECT 1
      FROM public.orders o
      JOIN public.merchants m ON m.id = o.merchant_id
      WHERE o.id = payments.order_id
        AND m.owner_id = (SELECT auth.uid())
    )
  );

-- -------------------------------------------------------------
-- 5. Realtime: el tablero escucha INSERT/UPDATE de orders
--    (Postgreste aplica RLS con el JWT de quien se suscribe,
--    así cada local recibe solo sus pedidos.)
-- -------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
      SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    )
    AND NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'orders'
    ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
END $$;

-- -------------------------------------------------------------
-- 6. Historial de estados: guardamos las notas del cambio
--    (motivo de rechazo, tiempo estimado, etc.)
--    El valor lo deja la RPC de la sección 7 con set_config().
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.estado IS DISTINCT FROM OLD.estado THEN
    INSERT INTO order_status_history (order_id, estado, notes)
    VALUES (
      NEW.id,
      NEW.estado,
      NULLIF(COALESCE(current_setting('app.panel_notas', true), ''), '')
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------
-- 7. RPC: cambiar el estado de un pedido desde el panel
--     - valida rol local y que sea dueño del merchant
--     - valida la transición de estados
--     - escribe el historial (vía el trigger) con las notas
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.panel_cambiar_estado(
  p_pedido_id UUID,
  p_estado public.order_status,
  p_notas TEXT DEFAULT NULL,
  p_tiempo_estimado_min INTEGER DEFAULT NULL
)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rol public.user_role;
  v_pedido public.orders%ROWTYPE;
  v_dueno BOOLEAN;
  v_motivo TEXT := NULLIF(COALESCE(p_notas, ''), '');
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  SELECT rol INTO v_rol FROM public.profiles WHERE id = v_uid;
  IF v_rol IS DISTINCT FROM 'local' THEN
    RAISE EXCEPTION 'No tenés permisos para gestionar pedidos';
  END IF;

  SELECT * INTO v_pedido
  FROM public.orders
  WHERE id = p_pedido_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido no encontrado';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.merchants
    WHERE id = v_pedido.merchant_id AND owner_id = v_uid
  ) INTO v_dueno;

  IF NOT v_dueno THEN
    RAISE EXCEPTION 'No tenés permisos sobre este pedido';
  END IF;

  -- Estados que el panel puede escribir
  IF p_estado NOT IN ('aceptado_por_local', 'rechazado', 'en_preparacion', 'listo_para_retirar') THEN
    RAISE EXCEPTION 'Estado % no permitido desde el panel', p_estado;
  END IF;

  -- Transiciones válidas
  IF NOT (
       (p_estado = 'aceptado_por_local'
         AND v_pedido.estado IN ('creado', 'pago_pendiente', 'confirmado'))
    OR (p_estado = 'rechazado'
         AND v_pedido.estado IN ('creado', 'pago_pendiente', 'confirmado'))
    OR (p_estado = 'en_preparacion'
         AND v_pedido.estado IN ('aceptado_por_local', 'en_preparacion'))
    OR (p_estado = 'listo_para_retirar'
         AND v_pedido.estado IN ('aceptado_por_local', 'en_preparacion'))
  ) THEN
    RAISE EXCEPTION 'No se puede pasar de % a %', v_pedido.estado, p_estado;
  END IF;

  -- Reglas por estado
  IF p_estado = 'rechazado' AND v_motivo IS NULL THEN
    RAISE EXCEPTION 'Indicá el motivo del rechazo';
  END IF;

  IF p_estado = 'aceptado_por_local'
     AND (p_tiempo_estimado_min IS NULL
          OR p_tiempo_estimado_min < 1
          OR p_tiempo_estimado_min > 240) THEN
    RAISE EXCEPTION 'Tiempo estimado inválido';
  END IF;

  -- Deja las notas para el trigger del historial (transacción local)
  PERFORM set_config('app.panel_notas', COALESCE(v_motivo, ''), true);

  UPDATE public.orders
  SET estado = p_estado,
      tiempo_estimado_min = CASE
        WHEN p_estado = 'aceptado_por_local' THEN p_tiempo_estimado_min
        ELSE orders.tiempo_estimado_min
      END
  WHERE id = p_pedido_id
  RETURNING * INTO v_pedido;

  RETURN v_pedido;
END;
$$;

REVOKE ALL ON FUNCTION public.panel_cambiar_estado(UUID, public.order_status, TEXT, INTEGER)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.panel_cambiar_estado(UUID, public.order_status, TEXT, INTEGER)
  TO authenticated;
