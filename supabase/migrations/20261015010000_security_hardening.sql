-- =============================================================
--  Migración: Endurecimiento de seguridad (Auditoría 2026-10-15)
--  Archivo: 20261015010000_security_hardening.sql
--
--  Cubre:
--   C2: Mover mp_access_token / mp_refresh_token a merchant_secrets (solo service_role)
--   C3: Políticas de repartidor en orders/addresses/profiles/payments exigen rol 'repartidor'
--       + RPC repartidor_cambiar_estado() y endurecimiento de tomar_pedido()
--   C4: Trigger que impide a usuarios no-admin modificar rol, plan, wallet_balance, is_banned, email
--   C5: Eliminar INSERT directo de clientes en orders (solo vía Edge Function crear-pedido)
--   A3: Límites y vigencia activa en cupones
--   A4: Eliminar UPDATE directo de local en orders (usa panel_cambiar_estado) y proteger
--       comision_porcentaje / owner_id / owner_email en merchants con trigger
--   M3: Límites de MIME/tamaño en buckets de Storage y aislamiento por carpeta
--   M5: search_path fijo en funciones SECURITY DEFINER
-- =============================================================

-- -------------------------------------------------------------
-- 1. C2 – Tabla privada para credenciales OAuth de Mercado Pago
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.merchant_secrets (
  merchant_id UUID PRIMARY KEY REFERENCES public.merchants(id) ON DELETE CASCADE,
  mp_access_token TEXT,
  mp_refresh_token TEXT,
  mp_user_id TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.merchant_secrets ENABLE ROW LEVEL SECURITY;
-- Sin políticas para anon/authenticated: solo service_role puede leer o escribir.
REVOKE ALL ON public.merchant_secrets FROM PUBLIC, anon, authenticated;

-- Migrar credenciales existentes antes de eliminar columnas públicas
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'merchants' AND column_name = 'mp_access_token'
  ) THEN
    INSERT INTO public.merchant_secrets (merchant_id, mp_access_token, mp_refresh_token, mp_user_id)
    SELECT id, mp_access_token, mp_refresh_token, mp_user_id
    FROM public.merchants
    WHERE mp_access_token IS NOT NULL
       OR mp_refresh_token IS NOT NULL
       OR mp_user_id IS NOT NULL
    ON CONFLICT (merchant_id) DO UPDATE
      SET mp_access_token = EXCLUDED.mp_access_token,
          mp_refresh_token = EXCLUDED.mp_refresh_token,
          mp_user_id = EXCLUDED.mp_user_id,
          updated_at = NOW();

    ALTER TABLE public.merchants
      DROP COLUMN IF EXISTS mp_access_token,
      DROP COLUMN IF EXISTS mp_refresh_token,
      DROP COLUMN IF EXISTS mp_user_id;
  END IF;
END $$;

-- Tabla de nonces de un solo uso para el flujo OAuth de Mercado Pago (C6)
CREATE TABLE IF NOT EXISTS public.oauth_states (
  nonce TEXT PRIMARY KEY,
  merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.oauth_states ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.oauth_states FROM PUBLIC, anon, authenticated;

-- -------------------------------------------------------------
-- 2. M5 – Fijar search_path en current_user_rol()
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_rol()
RETURNS public.user_role
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rol public.user_role;
BEGIN
  SELECT rol INTO v_rol FROM public.profiles WHERE id = auth.uid();
  RETURN COALESCE(v_rol, 'cliente'::public.user_role);
END;
$$;

-- -------------------------------------------------------------
-- 3. C4 – Proteger columnas sensibles en profiles
--    Un usuario normal solo puede editar nombre, telefono, avatar_url
--    (y vehiculo/patente si es repartidor).
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_jwt_role TEXT := COALESCE(auth.role(), '');
  v_caller_rol public.user_role;
BEGIN
  -- Permitir operaciones internas (triggers de auth, migraciones, service_role)
  IF v_jwt_role = 'service_role' OR auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT rol INTO v_caller_rol FROM public.profiles WHERE id = auth.uid();

  IF v_caller_rol = 'admin' THEN
    RETURN NEW;
  END IF;

  IF NEW.rol IS DISTINCT FROM OLD.rol THEN
    RAISE EXCEPTION 'No tenés permisos para modificar el rol' USING ERRCODE = '42501';
  END IF;

  IF NEW.plan IS DISTINCT FROM OLD.plan THEN
    RAISE EXCEPTION 'No tenés permisos para modificar el plan' USING ERRCODE = '42501';
  END IF;

  IF NEW.wallet_balance IS DISTINCT FROM OLD.wallet_balance THEN
    RAISE EXCEPTION 'No tenés permisos para modificar el saldo de billetera' USING ERRCODE = '42501';
  END IF;

  IF NEW.is_banned IS DISTINCT FROM OLD.is_banned THEN
    RAISE EXCEPTION 'No tenés permisos para modificar el estado de bloqueo' USING ERRCODE = '42501';
  END IF;

  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'No tenés permisos para modificar el email directamente' USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_sensitive_columns ON public.profiles;
CREATE TRIGGER trg_protect_profile_sensitive_columns
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_sensitive_columns();

-- -------------------------------------------------------------
-- 4. A4 – Proteger columnas sensibles en merchants
--    El dueño del local no puede bajarse comision_porcentaje ni cambiar owner_id / owner_email.
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_merchant_sensitive_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_jwt_role TEXT := COALESCE(auth.role(), '');
  v_caller_rol public.user_role;
BEGIN
  IF v_jwt_role = 'service_role' OR auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT rol INTO v_caller_rol FROM public.profiles WHERE id = auth.uid();

  IF v_caller_rol = 'admin' THEN
    RETURN NEW;
  END IF;

  IF NEW.comision_porcentaje IS DISTINCT FROM OLD.comision_porcentaje THEN
    RAISE EXCEPTION 'No tenés permisos para modificar la comisión del comercio' USING ERRCODE = '42501';
  END IF;

  IF NEW.owner_id IS DISTINCT FROM OLD.owner_id THEN
    RAISE EXCEPTION 'No tenés permisos para transferir la titularidad del comercio' USING ERRCODE = '42501';
  END IF;

  IF NEW.owner_email IS DISTINCT FROM OLD.owner_email THEN
    RAISE EXCEPTION 'No tenés permisos para modificar el email de titularidad' USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_merchant_sensitive_columns ON public.merchants;
CREATE TRIGGER trg_protect_merchant_sensitive_columns
  BEFORE UPDATE ON public.merchants
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_merchant_sensitive_columns();

-- -------------------------------------------------------------
-- 5. C3, C5, A4 – Políticas RLS de orders, addresses, profiles y payments
-- -------------------------------------------------------------

-- C5: Los clientes NO pueden insertar pedidos directamente (solo la Edge Function crear-pedido)
DROP POLICY IF EXISTS "Pedidos – cliente INSERT propio" ON public.orders;

-- A4: El local NO actualiza orders por tabla directa; usa la RPC panel_cambiar_estado
DROP POLICY IF EXISTS "Pedidos – local UPDATE de su merchant" ON public.orders;

-- C3: Repartidor SELECT exige rol = 'repartidor' y sesión autenticada
DROP POLICY IF EXISTS "Pedidos – repartidor SELECT asignados" ON public.orders;
DROP POLICY IF EXISTS "Pedidos – repartidor SELECT disponibles y asignados" ON public.orders;

CREATE POLICY "Pedidos – repartidor SELECT disponibles y asignados"
  ON public.orders FOR SELECT
  TO authenticated
  USING (
    (SELECT public.current_user_rol()) = 'repartidor'
    AND (
      courier_id = (SELECT auth.uid())
      OR (
        courier_id IS NULL
        AND estado IN ('listo_para_retirar', 'en_preparacion', 'aceptado_por_local')
      )
    )
  );

-- C3: Eliminar UPDATE directo de repartidor sobre orders (se usa tomar_pedido y repartidor_cambiar_estado)
DROP POLICY IF EXISTS "Pedidos – repartidor UPDATE asignados" ON public.orders;
DROP POLICY IF EXISTS "Pedidos – repartidor UPDATE tomar y gestionar" ON public.orders;

-- C3: Direcciones visibles para repartidor solo si realmente tiene rol 'repartidor'
DROP POLICY IF EXISTS "Direcciones – repartidor SELECT pedidos" ON public.addresses;
CREATE POLICY "Direcciones – repartidor SELECT pedidos"
  ON public.addresses FOR SELECT
  TO authenticated
  USING (
    (SELECT public.current_user_rol()) = 'repartidor'
    AND EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.address_id = addresses.id
        AND (
          o.courier_id = (SELECT auth.uid())
          OR (o.courier_id IS NULL AND o.estado IN ('listo_para_retirar', 'en_preparacion', 'aceptado_por_local'))
        )
    )
  );

-- C3: Perfiles de clientes visibles para repartidor solo si tiene rol 'repartidor'
DROP POLICY IF EXISTS "Perfiles – repartidor SELECT clientes de pedidos" ON public.profiles;
CREATE POLICY "Perfiles – repartidor SELECT clientes de pedidos"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    (SELECT public.current_user_rol()) = 'repartidor'
    AND EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.user_id = profiles.id
        AND (
          o.courier_id = (SELECT auth.uid())
          OR (o.courier_id IS NULL AND o.estado IN ('listo_para_retirar', 'en_preparacion', 'aceptado_por_local'))
        )
    )
  );

-- C3: Pagos visibles para repartidor solo si tiene rol 'repartidor' (y para el cliente dueño del pedido)
DROP POLICY IF EXISTS "Pagos – repartidor SELECT pedidos" ON public.payments;
CREATE POLICY "Pagos – repartidor SELECT pedidos"
  ON public.payments FOR SELECT
  TO authenticated
  USING (
    (SELECT public.current_user_rol()) = 'repartidor'
    AND EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = payments.order_id
        AND (
          o.courier_id = (SELECT auth.uid())
          OR (o.courier_id IS NULL AND o.estado IN ('listo_para_retirar', 'en_preparacion', 'aceptado_por_local'))
        )
    )
  );

-- Ubicación del repartidor: solo usuarios con rol 'repartidor' pueden escribir la suya
DROP POLICY IF EXISTS "Ubicación courier – UPDATE propia" ON public.courier_locations;
CREATE POLICY "Ubicación courier – escritura propia"
  ON public.courier_locations FOR ALL
  TO authenticated
  USING (
    courier_id = (SELECT auth.uid())
    AND (SELECT public.current_user_rol()) IN ('repartidor', 'admin')
  )
  WITH CHECK (
    courier_id = (SELECT auth.uid())
    AND (SELECT public.current_user_rol()) IN ('repartidor', 'admin')
  );

-- -------------------------------------------------------------
-- 6. C3 / M5 – Endurecer tomar_pedido() y crear repartidor_cambiar_estado()
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tomar_pedido(p_order_id UUID)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_courier_id UUID := auth.uid();
  v_rol public.user_role;
BEGIN
  IF v_courier_id IS NULL THEN
    RAISE EXCEPTION 'No autorizado' USING ERRCODE = '42501';
  END IF;

  SELECT rol INTO v_rol FROM public.profiles WHERE id = v_courier_id;
  IF v_rol IS DISTINCT FROM 'repartidor' AND v_rol IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Solo los repartidores pueden tomar pedidos' USING ERRCODE = '42501';
  END IF;

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
      updated_at = NOW()
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.tomar_pedido(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.tomar_pedido(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.repartidor_cambiar_estado(
  p_order_id UUID,
  p_estado public.order_status
)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rol public.user_role;
  v_order public.orders%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No autenticado' USING ERRCODE = '42501';
  END IF;

  SELECT rol INTO v_rol FROM public.profiles WHERE id = v_uid;
  IF v_rol NOT IN ('repartidor', 'admin') THEN
    RAISE EXCEPTION 'No tenés permisos para actualizar la entrega' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido no encontrado' USING ERRCODE = 'P0002';
  END IF;

  IF v_rol = 'repartidor' AND v_order.courier_id IS DISTINCT FROM v_uid THEN
    RAISE EXCEPTION 'Este pedido no está asignado a tu cuenta' USING ERRCODE = '42501';
  END IF;

  IF p_estado NOT IN ('en_camino', 'entregado') THEN
    RAISE EXCEPTION 'Estado % no permitido para repartidor', p_estado USING ERRCODE = '22023';
  END IF;

  IF p_estado = 'en_camino'
     AND v_order.estado NOT IN ('aceptado_por_local', 'en_preparacion', 'listo_para_retirar') THEN
    RAISE EXCEPTION 'No se puede pasar de % a en_camino', v_order.estado USING ERRCODE = '22023';
  END IF;

  IF p_estado = 'entregado' AND v_order.estado <> 'en_camino' THEN
    RAISE EXCEPTION 'Solo se puede marcar como entregado un pedido en camino' USING ERRCODE = '22023';
  END IF;

  UPDATE public.orders
  SET estado = p_estado,
      updated_at = NOW()
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.repartidor_cambiar_estado(UUID, public.order_status) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.repartidor_cambiar_estado(UUID, public.order_status) TO authenticated;

-- -------------------------------------------------------------
-- 7. A3 – Endurecimiento de cupones (límites de uso y estado activo)
-- -------------------------------------------------------------
ALTER TABLE public.coupons
  ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS usos_maximos INTEGER CHECK (usos_maximos IS NULL OR usos_maximos > 0),
  ADD COLUMN IF NOT EXISTS usos_por_usuario INTEGER NOT NULL DEFAULT 1 CHECK (usos_por_usuario > 0),
  ADD COLUMN IF NOT EXISTS monto_minimo_centavos INTEGER NOT NULL DEFAULT 0 CHECK (monto_minimo_centavos >= 0);

-- Solo usuarios autenticados pueden consultar cupones activos (evita scraping anónimo)
DROP POLICY IF EXISTS "Cupones – lectura pública" ON public.coupons;
CREATE POLICY "Cupones – lectura autenticada activos"
  ON public.coupons FOR SELECT
  TO authenticated
  USING (
    activo = true
    OR (SELECT public.current_user_rol()) = 'admin'
  );

-- -------------------------------------------------------------
-- 8. M3 – Endurecimiento de Storage (límites MIME/tamaño y carpetas)
-- -------------------------------------------------------------
UPDATE storage.buckets
SET file_size_limit = 2097152, -- 2 MB
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
WHERE id IN ('productos', 'locales', 'avatars');

-- Avatares: el usuario solo puede subir dentro de su carpeta <uid>/... o con prefijo <uid>-
DROP POLICY IF EXISTS "Users can upload their own avatar." ON storage.objects;
CREATE POLICY "Users can upload their own avatar."
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid() = owner
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR name LIKE (auth.uid()::text || '-%')
    )
  );
