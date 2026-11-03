-- =============================================================
-- Migración: Mejoras para la funcionalidad de Favoritos (RPC, índices y defaults)
-- Archivo: 20261016030000_favoritos_feature.sql
-- =============================================================

-- 1. Asegurar default auth.uid() en user_id para conveniencia y consistencia
ALTER TABLE public.favorites
  ALTER COLUMN user_id SET DEFAULT auth.uid();

-- 2. Índice compuesto para optimizar verificación de favoritos por usuario y comercio
CREATE INDEX IF NOT EXISTS idx_favorites_user_merchant
  ON public.favorites(user_id, merchant_id);

-- 3. Reafirmar políticas de Row Level Security (idempotente)
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Favoritos – SELECT propio" ON public.favorites;
CREATE POLICY "Favoritos – SELECT propio"
  ON public.favorites FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Favoritos – INSERT propio" ON public.favorites;
CREATE POLICY "Favoritos – INSERT propio"
  ON public.favorites FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Favoritos – DELETE propio" ON public.favorites;
CREATE POLICY "Favoritos – DELETE propio"
  ON public.favorites FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- 4. Función RPC para obtener comercios favoritos del usuario autenticado con datos completos
CREATE OR REPLACE FUNCTION public.get_user_favorites()
RETURNS TABLE (
  favorite_id UUID,
  merchant_id UUID,
  name TEXT,
  description TEXT,
  logo_url TEXT,
  banner_url TEXT,
  estado public.merchant_status,
  tiempo_estimado_min INTEGER,
  costo_envio_base INTEGER,
  rating TEXT,
  review_count BIGINT,
  categories TEXT[],
  is_open BOOLEAN,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_mendoza_time TIMESTAMP;
  v_day_of_week INTEGER;
  v_time_str TIME;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  -- Calcular día y hora actual en huso horario America/Argentina/Mendoza
  v_mendoza_time := (timezone('America/Argentina/Mendoza', now()));
  v_day_of_week := EXTRACT(DOW FROM v_mendoza_time)::INTEGER; -- 0: Domingo, 1: Lunes, etc.
  v_time_str := v_mendoza_time::TIME;

  RETURN QUERY
  SELECT
    f.id AS favorite_id,
    m.id AS merchant_id,
    m.name,
    m.description,
    m.logo_url,
    m.banner_url,
    m.estado,
    m.tiempo_estimado_min,
    m.costo_envio_base,
    COALESCE(
      REPLACE(ROUND(AVG(r.rating), 1)::TEXT, '.', ','),
      'Nuevo'
    ) AS rating,
    COUNT(r.id)::BIGINT AS review_count,
    COALESCE(
      ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL),
      ARRAY[]::TEXT[]
    ) AS categories,
    (
      m.estado = 'activo' AND (
        NOT EXISTS (
          SELECT 1 FROM public.merchant_hours mh
          WHERE mh.merchant_id = m.id
        )
        OR EXISTS (
          SELECT 1 FROM public.merchant_hours mh
          WHERE mh.merchant_id = m.id
            AND (mh.day_of_week = v_day_of_week OR (v_day_of_week = 0 AND mh.day_of_week = 7))
            AND v_time_str >= mh.open_time
            AND v_time_str <= mh.close_time
        )
      )
    ) AS is_open,
    f.created_at
  FROM public.favorites f
  INNER JOIN public.merchants m ON m.id = f.merchant_id
  LEFT JOIN public.reviews r ON r.merchant_id = m.id
  LEFT JOIN public.merchant_categories mc ON mc.merchant_id = m.id
  LEFT JOIN public.categories c ON c.id = mc.category_id
  WHERE f.user_id = v_user_id
  GROUP BY f.id, m.id, f.created_at
  ORDER BY f.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_favorites() TO authenticated;
