-- =============================================================
-- Migración: Soporte de color/costo en delivery_zones y configuración de tarifas delivery_settings
-- Archivo: 20261016010000_delivery_zones_and_settings.sql
-- =============================================================

-- 1. Extender delivery_zones con color y costo adicional en centavos
ALTER TABLE public.delivery_zones
  ADD COLUMN IF NOT EXISTS color TEXT NOT NULL DEFAULT '#E84B35',
  ADD COLUMN IF NOT EXISTS costo_adicional_centavos INTEGER NOT NULL DEFAULT 0;

-- Migrar costos preexistentes desde polygon_geojson.properties si existen
UPDATE public.delivery_zones
SET costo_adicional_centavos = COALESCE(
  (polygon_geojson->'properties'->>'costo_envio_centavos')::integer,
  0
)
WHERE costo_adicional_centavos = 0
  AND polygon_geojson->'properties'->>'costo_envio_centavos' IS NOT NULL;

-- Asegurar permisos de DELETE para administradores en delivery_zones
DROP POLICY IF EXISTS "Admin – delivery_zones escritura" ON public.delivery_zones;
CREATE POLICY "Admin – delivery_zones escritura"
  ON public.delivery_zones FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.rol = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.rol = 'admin'
    )
  );

-- 2. Crear tabla de configuración de tarifas de envío
CREATE TABLE IF NOT EXISTS public.delivery_settings (
  id TEXT PRIMARY KEY DEFAULT 'default',
  base_fee_centavos INTEGER NOT NULL DEFAULT 120000,          -- $1.200 (tarifa base)
  base_included_km NUMERIC(5,2) NOT NULL DEFAULT 2.00,        -- 2 km incluidos
  price_per_km_centavos INTEGER NOT NULL DEFAULT 35000,       -- $350 por km adicional
  min_fee_centavos INTEGER NOT NULL DEFAULT 100000,           -- $1.000 mínimo
  max_fee_centavos INTEGER NOT NULL DEFAULT 600000,           -- $6.000 tope
  max_distance_km NUMERIC(5,2) NOT NULL DEFAULT 18.00,        -- 18 km máximo de cobertura
  rounding_step_centavos INTEGER NOT NULL DEFAULT 5000,       -- Redondeo al múltiplo de $50
  route_factor NUMERIC(4,2) NOT NULL DEFAULT 1.30,            -- Factor de corrección vial sobre Haversine
  use_tiers BOOLEAN NOT NULL DEFAULT FALSE,
  tiers JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insertar configuración inicial por defecto si no existe
INSERT INTO public.delivery_settings (id)
VALUES ('default')
ON CONFLICT (id) DO NOTHING;

-- Trigger para updated_at en delivery_settings
CREATE OR REPLACE TRIGGER set_delivery_settings_updated_at
  BEFORE UPDATE ON public.delivery_settings
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Habilitar RLS en delivery_settings
ALTER TABLE public.delivery_settings ENABLE ROW LEVEL SECURITY;

-- Lectura pública (clientes, repartidores y administradores necesitan leer tarifas)
DROP POLICY IF EXISTS "delivery_settings lectura publica" ON public.delivery_settings;
CREATE POLICY "delivery_settings lectura publica"
  ON public.delivery_settings FOR SELECT
  TO public
  USING (true);

-- Escritura solo administradores
DROP POLICY IF EXISTS "Admin – delivery_settings gestion" ON public.delivery_settings;
CREATE POLICY "Admin – delivery_settings gestion"
  ON public.delivery_settings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.rol = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.rol = 'admin'
    )
  );
