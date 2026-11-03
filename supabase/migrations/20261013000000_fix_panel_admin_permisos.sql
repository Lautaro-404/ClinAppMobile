-- =============================================================
--  Fix: admin puede aceptar/rechazar pedidos desde el panel
--  Migración: 20261013000000_fix_panel_admin_permisos.sql
--
--  Problema:
--    La RPC panel_cambiar_estado solo permitía rol = 'local'.
--    El frontend (/panel) admite también rol = 'admin', por lo que
--    un admin obtenía "No tenés permisos para gestionar pedidos"
--    al intentar aceptar o rechazar un pedido.
--
--  Cambios:
--    1. RPC panel_cambiar_estado: acepta 'local' O 'admin'.
--       El admin no necesita ser dueño del merchant; puede operar
--       cualquier pedido (igual que su acceso SELECT).
--    2. RLS orders UPDATE: política para que admin pueda actualizar
--       cualquier pedido (complementa la SELECT ya existente).
-- =============================================================

-- -------------------------------------------------------------
-- 1. RPC actualizada
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
  v_uid  UUID := auth.uid();
  v_rol  public.user_role;
  v_pedido public.orders%ROWTYPE;
  v_dueno  BOOLEAN;
  v_motivo TEXT := NULLIF(COALESCE(p_notas, ''), '');
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  SELECT rol INTO v_rol FROM public.profiles WHERE id = v_uid;

  -- Solo 'local' y 'admin' pueden gestionar pedidos desde el panel
  IF v_rol NOT IN ('local', 'admin') THEN
    RAISE EXCEPTION 'No tenés permisos para gestionar pedidos';
  END IF;

  SELECT * INTO v_pedido
  FROM public.orders
  WHERE id = p_pedido_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido no encontrado';
  END IF;

  -- El 'local' solo puede operar pedidos de su propio comercio
  IF v_rol = 'local' THEN
    SELECT EXISTS (
      SELECT 1 FROM public.merchants
      WHERE id = v_pedido.merchant_id AND owner_id = v_uid
    ) INTO v_dueno;

    IF NOT v_dueno THEN
      RAISE EXCEPTION 'No tenés permisos sobre este pedido';
    END IF;
  END IF;
  -- El 'admin' puede operar cualquier pedido (sin verificar dueño)

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

-- Permisos de ejecución (sin cambios: authenticated)
REVOKE ALL ON FUNCTION public.panel_cambiar_estado(UUID, public.order_status, TEXT, INTEGER)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.panel_cambiar_estado(UUID, public.order_status, TEXT, INTEGER)
  TO authenticated;

-- -------------------------------------------------------------
-- 2. RLS: admin puede actualizar cualquier pedido
--    (SELECT ya existe en 20261008010000_rls.sql)
-- -------------------------------------------------------------
DROP POLICY IF EXISTS "Admin – orders UPDATE all" ON public.orders;
CREATE POLICY "Admin – orders UPDATE all"
  ON public.orders FOR UPDATE
  USING (public.current_user_rol() = 'admin')
  WITH CHECK (public.current_user_rol() = 'admin');
