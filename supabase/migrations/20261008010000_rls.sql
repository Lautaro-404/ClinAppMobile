-- =============================================================
--  RLS – Row Level Security
--  Migración: 20261008010000_rls.sql
-- =============================================================

-- ─── Helper: obtener el rol del usuario actual ─────────────────
-- Lo leemos desde el claim "rol" que el trigger handle_new_user
-- pone en la metadata del JWT a través de app_metadata.
-- Supabase refresca el JWT cuando el claim cambia; mientras tanto
-- se puede usar la función de acceso directo a profiles.

CREATE OR REPLACE FUNCTION public.current_user_rol()
RETURNS user_role
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT rol FROM public.profiles WHERE id = auth.uid();
$$;

-- ─── Agregar owner_id a merchants ANTES de crear políticas que lo usan ───
ALTER TABLE public.merchants
  ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES public.profiles(id);

CREATE INDEX IF NOT EXISTS idx_merchants_owner ON public.merchants(owner_id);

-- ─── Habilitar RLS en todas las tablas ────────────────────────

ALTER TABLE public.profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchants            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchant_hours       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchant_categories  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_sections        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_options      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_redemptions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courier_locations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications        ENABLE ROW LEVEL SECURITY;


-- =============================================================
--  CATÁLOGO PÚBLICO (solo lectura, sin autenticar)
-- =============================================================

-- categories: cualquiera puede leer
CREATE POLICY "Catálogo – categories lectura pública"
  ON public.categories FOR SELECT
  USING (true);

-- merchants: solo los activos son visibles al público
CREATE POLICY "Catálogo – merchants activos lectura pública"
  ON public.merchants FOR SELECT
  USING (estado = 'activo');

-- merchant_hours: visibles si el local es activo
CREATE POLICY "Catálogo – merchant_hours lectura pública"
  ON public.merchant_hours FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.estado = 'activo'
    )
  );

-- merchant_categories: visibles si el local es activo
CREATE POLICY "Catálogo – merchant_categories lectura pública"
  ON public.merchant_categories FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.estado = 'activo'
    )
  );

-- menu_sections: visibles si el local es activo
CREATE POLICY "Catálogo – menu_sections lectura pública"
  ON public.menu_sections FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.merchants m
        JOIN public.menu_sections ms ON ms.merchant_id = m.id
      WHERE ms.id = menu_sections.id AND m.estado = 'activo'
    )
  );

-- products: visibles y disponibles si el local es activo
CREATE POLICY "Catálogo – products lectura pública"
  ON public.products FOR SELECT
  USING (
    is_available = true AND
    EXISTS (
      SELECT 1 FROM public.menu_sections ms
        JOIN public.merchants m ON m.id = ms.merchant_id
      WHERE ms.id = section_id AND m.estado = 'activo'
    )
  );

-- product_options: visibles si el producto lo es
CREATE POLICY "Catálogo – product_options lectura pública"
  ON public.product_options FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.products p
        JOIN public.menu_sections ms ON ms.id = p.section_id
        JOIN public.merchants m ON m.id = ms.merchant_id
      WHERE p.id = product_id
        AND p.is_available = true
        AND m.estado = 'activo'
    )
  );

-- delivery_zones: lectura pública
CREATE POLICY "Catálogo – delivery_zones lectura pública"
  ON public.delivery_zones FOR SELECT
  USING (active = true);

-- coupons: lectura pública (para validar al checkout)
CREATE POLICY "Cupones – lectura pública"
  ON public.coupons FOR SELECT
  USING (true);


-- =============================================================
--  PROFILES
-- =============================================================

-- Cada usuario ve y edita solo su propio perfil
CREATE POLICY "Perfil – SELECT propio"
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Perfil – UPDATE propio"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());


-- =============================================================
--  ADDRESSES
-- =============================================================

CREATE POLICY "Direcciones – SELECT propia"
  ON public.addresses FOR SELECT
  USING (profile_id = auth.uid());

CREATE POLICY "Direcciones – INSERT propia"
  ON public.addresses FOR INSERT
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Direcciones – UPDATE propia"
  ON public.addresses FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Direcciones – DELETE propia"
  ON public.addresses FOR DELETE
  USING (profile_id = auth.uid());


-- =============================================================
--  FAVORITES
-- =============================================================

CREATE POLICY "Favoritos – SELECT propio"
  ON public.favorites FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Favoritos – INSERT propio"
  ON public.favorites FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Favoritos – DELETE propio"
  ON public.favorites FOR DELETE
  USING (user_id = auth.uid());


-- =============================================================
--  NOTIFICATIONS
-- =============================================================

CREATE POLICY "Notificaciones – SELECT propio"
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Notificaciones – UPDATE propio (marcar leído)"
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- =============================================================
--  ORDERS – cliente
-- =============================================================

-- Cliente ve solo sus propios pedidos
CREATE POLICY "Pedidos – cliente SELECT propio"
  ON public.orders FOR SELECT
  USING (user_id = auth.uid());

-- Cliente solo puede crear pedidos a su nombre
CREATE POLICY "Pedidos – cliente INSERT propio"
  ON public.orders FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND public.current_user_rol() = 'cliente'
  );

-- ORDER ITEMS – cliente solo ve items de sus pedidos
CREATE POLICY "Items – cliente SELECT de sus pedidos"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id AND o.user_id = auth.uid()
    )
  );

-- ORDER STATUS HISTORY – cliente ve el historial de sus pedidos
CREATE POLICY "Historial estado – cliente SELECT de sus pedidos"
  ON public.order_status_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id AND o.user_id = auth.uid()
    )
  );


-- =============================================================
--  ORDERS – local (rol 'local')
-- =============================================================

-- Local ve los pedidos de su(s) comercio(s)
CREATE POLICY "Pedidos – local SELECT de su merchant"
  ON public.orders FOR SELECT
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id
        -- La relación local <-> merchant se resuelve via profiles.
        -- Se asume un campo owner_id en merchants (se agrega abajo).
        AND m.owner_id = auth.uid()
    )
  );

-- Local puede actualizar estado de pedidos de su merchant
CREATE POLICY "Pedidos – local UPDATE de su merchant"
  ON public.orders FOR UPDATE
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.owner_id = auth.uid()
    )
  );

-- Local ve items de sus pedidos
CREATE POLICY "Items – local SELECT de su merchant"
  ON public.order_items FOR SELECT
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.orders o
        JOIN public.merchants m ON m.id = o.merchant_id
      WHERE o.id = order_id AND m.owner_id = auth.uid()
    )
  );

-- Local ve historial de estado de sus pedidos
CREATE POLICY "Historial estado – local SELECT de su merchant"
  ON public.order_status_history FOR SELECT
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.orders o
        JOIN public.merchants m ON m.id = o.merchant_id
      WHERE o.id = order_id AND m.owner_id = auth.uid()
    )
  );

-- Local puede ver y editar su propio merchant
CREATE POLICY "Merchants – local SELECT propio"
  ON public.merchants FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Merchants – local UPDATE propio"
  ON public.merchants FOR UPDATE
  USING (
    public.current_user_rol() = 'local'
    AND owner_id = auth.uid()
  )
  WITH CHECK (owner_id = auth.uid());

-- Local puede gestionar su menú
CREATE POLICY "Menu sections – local CUD propio"
  ON public.menu_sections FOR ALL
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.owner_id = auth.uid()
    )
  );

CREATE POLICY "Products – local CUD propio"
  ON public.products FOR ALL
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.menu_sections ms
        JOIN public.merchants m ON m.id = ms.merchant_id
      WHERE ms.id = section_id AND m.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.menu_sections ms
        JOIN public.merchants m ON m.id = ms.merchant_id
      WHERE ms.id = section_id AND m.owner_id = auth.uid()
    )
  );

CREATE POLICY "Product options – local CUD propio"
  ON public.product_options FOR ALL
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.products p
        JOIN public.menu_sections ms ON ms.id = p.section_id
        JOIN public.merchants m ON m.id = ms.merchant_id
      WHERE p.id = product_id AND m.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
        JOIN public.menu_sections ms ON ms.id = p.section_id
        JOIN public.merchants m ON m.id = ms.merchant_id
      WHERE p.id = product_id AND m.owner_id = auth.uid()
    )
  );


-- =============================================================
--  ORDERS – repartidor (rol 'repartidor')
-- =============================================================

-- Repartidor solo ve pedidos que tiene asignados
CREATE POLICY "Pedidos – repartidor SELECT asignados"
  ON public.orders FOR SELECT
  USING (
    public.current_user_rol() = 'repartidor'
    AND courier_id = auth.uid()
  );

-- Repartidor puede actualizar el estado de sus pedidos
CREATE POLICY "Pedidos – repartidor UPDATE asignados"
  ON public.orders FOR UPDATE
  USING (
    public.current_user_rol() = 'repartidor'
    AND courier_id = auth.uid()
  )
  WITH CHECK (courier_id = auth.uid());

-- Repartidor actualiza su ubicación
CREATE POLICY "Ubicación courier – UPDATE propia"
  ON public.courier_locations FOR ALL
  USING (courier_id = auth.uid())
  WITH CHECK (courier_id = auth.uid());


-- =============================================================
--  ADMIN – acceso completo a tablas de configuración
-- =============================================================

-- Admin puede escribir en categories
CREATE POLICY "Admin – categories escritura"
  ON public.categories FOR ALL
  USING (public.current_user_rol() = 'admin')
  WITH CHECK (public.current_user_rol() = 'admin');

-- Admin puede escribir en coupons
CREATE POLICY "Admin – coupons escritura"
  ON public.coupons FOR ALL
  USING (public.current_user_rol() = 'admin')
  WITH CHECK (public.current_user_rol() = 'admin');

-- Admin puede escribir en delivery_zones
CREATE POLICY "Admin – delivery_zones escritura"
  ON public.delivery_zones FOR ALL
  USING (public.current_user_rol() = 'admin')
  WITH CHECK (public.current_user_rol() = 'admin');

-- Admin puede editar comisiones de merchants (UPDATE total)
CREATE POLICY "Admin – merchants ALL"
  ON public.merchants FOR ALL
  USING (public.current_user_rol() = 'admin')
  WITH CHECK (public.current_user_rol() = 'admin');

-- Admin ve todos los pedidos
CREATE POLICY "Admin – orders SELECT all"
  ON public.orders FOR SELECT
  USING (public.current_user_rol() = 'admin');

-- Admin ve todos los perfiles
CREATE POLICY "Admin – profiles SELECT all"
  ON public.profiles FOR SELECT
  USING (public.current_user_rol() = 'admin');

-- Admin puede actualizar perfiles (ej. cambiar rol)
CREATE POLICY "Admin – profiles UPDATE all"
  ON public.profiles FOR UPDATE
  USING (public.current_user_rol() = 'admin');


-- =============================================================
--  PAYMENTS & COUPON_REDEMPTIONS – solo service role
--  (sin políticas FROM → bloquea todo acceso anónimo y autenticado)
-- =============================================================
-- Al no agregar ninguna política FOR SELECT/INSERT/UPDATE/DELETE
-- a estas tablas (con RLS habilitado), solo el service_role
-- de Supabase puede operar sobre ellas.

-- Reviews: cliente ve las de su pedido; local ve las de su merchant
CREATE POLICY "Reviews – cliente SELECT propias"
  ON public.reviews FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Reviews – cliente INSERT propia"
  ON public.reviews FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND public.current_user_rol() = 'cliente'
    AND EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id AND o.user_id = auth.uid()
        AND o.estado = 'entregado'
    )
  );

CREATE POLICY "Reviews – local SELECT de su merchant"
  ON public.reviews FOR SELECT
  USING (
    public.current_user_rol() = 'local'
    AND EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.owner_id = auth.uid()
    )
  );

CREATE POLICY "Reviews – admin SELECT all"
  ON public.reviews FOR SELECT
  USING (public.current_user_rol() = 'admin');

