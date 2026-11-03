-- =============================================================
-- Migración: Cierre de seguridad RLS, borrado de cuenta e índices de rendimiento
-- Archivo: 20261103010000_security_and_performance_closure.sql
-- =============================================================

-- 1. Recrear vista merchants_catalog_view con security_invoker = true y filtro estado = 'activo'
-- Garantiza que la vista respete las políticas RLS del usuario que consulta y nunca exponga locales pausados.
DROP VIEW IF EXISTS public.merchants_catalog_view;

CREATE VIEW public.merchants_catalog_view
WITH (security_invoker = true)
AS
SELECT
  m.id,
  m.name,
  m.description,
  m.logo_url,
  m.banner_url,
  m.lat,
  m.lng,
  m.estado,
  m.tiempo_estimado_min,
  m.costo_envio_base,
  COALESCE(ROUND(AVG(r.rating)::numeric, 1), 4.9) AS rating,
  COUNT(r.id)::int AS review_count,
  COALESCE(
    json_agg(DISTINCT mc.category_id) FILTER (WHERE mc.category_id IS NOT NULL),
    '[]'::json
  ) AS category_ids,
  (
    m.estado = 'activo' AND (
      NOT EXISTS (SELECT 1 FROM public.merchant_hours mh_all WHERE mh_all.merchant_id = m.id)
      OR EXISTS (
        SELECT 1 FROM public.merchant_hours mh
        WHERE mh.merchant_id = m.id
          AND mh.day_of_week = EXTRACT(DOW FROM (NOW() AT TIME ZONE 'America/Argentina/Mendoza'))::int
          AND (NOW() AT TIME ZONE 'America/Argentina/Mendoza')::time BETWEEN mh.open_time AND mh.close_time
      )
    )
  ) AS is_open,
  dish.name AS signature_dish_name,
  dish.price AS signature_dish_price
FROM public.merchants m
LEFT JOIN public.reviews r ON r.merchant_id = m.id
LEFT JOIN public.merchant_categories mc ON mc.merchant_id = m.id
LEFT JOIN LATERAL (
  SELECT p.name, p.price
  FROM public.products p
  JOIN public.menu_sections ms ON ms.id = p.section_id
  WHERE ms.merchant_id = m.id AND p.is_available = true
  ORDER BY p.created_at ASC
  LIMIT 1
) dish ON true
WHERE m.estado = 'activo'
GROUP BY m.id, dish.name, dish.price;

GRANT SELECT ON public.merchants_catalog_view TO anon, authenticated;

-- 2. Endurecer política de lectura en marketing_banners (solo banners activos para público general)
DROP POLICY IF EXISTS "Banners son públicos para lectura" ON public.marketing_banners;
CREATE POLICY "Banners activos son públicos para lectura"
  ON public.marketing_banners FOR SELECT
  USING (
    active = true
    OR (SELECT public.current_user_rol()) = 'admin'
  );

-- 3. Índices compuestos para consultas críticas de Home, Pedidos, Paneles y Checkout
CREATE INDEX IF NOT EXISTS idx_orders_user_estado_created
  ON public.orders (user_id, estado, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_merchant_created
  ON public.orders (merchant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_courier_estado_created
  ON public.orders (courier_id, estado, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_products_section_avail_created
  ON public.products (section_id, is_available, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read_created
  ON public.notifications (user_id, is_read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_coupons_codigo_activo
  ON public.coupons (codigo)
  WHERE activo = true;

-- 4. RPC delete_own_account() para cumplir política de borrado de cuenta (Google Play y App Store)
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_active_orders INTEGER := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Debés iniciar sesión para eliminar tu cuenta' USING ERRCODE = '42501';
  END IF;

  -- Verificar que el usuario no tenga pedidos en curso ni entregas pendientes
  SELECT COUNT(*)
  INTO v_active_orders
  FROM public.orders
  WHERE (user_id = v_uid OR courier_id = v_uid)
    AND estado NOT IN ('entregado', 'cancelado', 'rechazado');

  IF v_active_orders > 0 THEN
    RAISE EXCEPTION 'No podés eliminar tu cuenta mientras tengas pedidos en curso' USING ERRCODE = 'P0001';
  END IF;

  -- Limpiar datos personales dependientes antes de remover el usuario de auth.users
  DELETE FROM public.push_subscriptions WHERE user_id = v_uid;
  DELETE FROM public.favorites WHERE user_id = v_uid;
  DELETE FROM public.notifications WHERE user_id = v_uid;
  DELETE FROM public.courier_locations WHERE courier_id = v_uid;
  DELETE FROM public.addresses WHERE profile_id = v_uid;
  DELETE FROM public.profiles WHERE id = v_uid;
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
