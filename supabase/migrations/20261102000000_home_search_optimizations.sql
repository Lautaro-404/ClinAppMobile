-- Migración: Optimizaciones para Home y Búsqueda en General Alvear
-- Habilita extensión de trigramas para búsqueda textual rápida, índices y vista de catálogo unificada.

-- 1. Extensión para búsquedas difusas y substrings rápidos con ILIKE
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Índices de texto GIN (trigrams)
CREATE INDEX IF NOT EXISTS idx_merchants_name_trgm ON public.merchants USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_merchants_desc_trgm ON public.merchants USING gin (description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON public.products USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_categories_name_trgm ON public.categories USING gin (name gin_trgm_ops);

-- 3. Índice para cálculo rápido de apertura de comercios
CREATE INDEX IF NOT EXISTS idx_merchant_hours_lookup 
  ON public.merchant_hours (merchant_id, day_of_week, open_time, close_time);

-- 4. Vista de catálogo optimizada para Home y Buscar
-- Agrega rating promedio, conteo de opiniones, categorías, plato insignia y estado abierto en huso Mendoza.
CREATE OR REPLACE VIEW public.merchants_catalog_view AS
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
GROUP BY m.id, dish.name, dish.price;

-- Permisos de lectura pública para la vista
GRANT SELECT ON public.merchants_catalog_view TO anon, authenticated;
