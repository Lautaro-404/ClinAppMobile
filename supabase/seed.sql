-- ==============================================================================
-- Clin - Seed Data para General Alvear, Mendoza, Argentina
-- Archivo: supabase/seed.sql
-- NOTA: Todos los montos monetarios se almacenan en CENTAVOS (enteros).
--       $1.000 ARS = 100000 centavos.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. ZONA DE ENTREGA: Centro (General Alvear)
-- ------------------------------------------------------------------------------
INSERT INTO public.delivery_zones (id, name, polygon_geojson, active)
VALUES (
  '11111111-1111-4111-8111-111111111111',
  'Centro General Alvear',
  '{
    "type": "Polygon",
    "coordinates": [[
      [-67.7150, -34.9600],
      [-67.6800, -34.9600],
      [-67.6800, -34.9900],
      [-67.7150, -34.9900],
      [-67.7150, -34.9600]
    ]]
  }'::jsonb,
  true
)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 2. CUPONES
-- ------------------------------------------------------------------------------
-- Cupón de bienvenida: 20% OFF, tope $2.000 ARS (200.000 centavos), 1er pedido
INSERT INTO public.coupons (
  id,
  codigo,
  porcentaje,
  tope_centavos,
  solo_primer_pedido,
  vigencia_desde,
  vigencia_hasta
) VALUES (
  '22222222-2222-4222-8222-222222222222',
  'HOLA',
  20,
  200000,
  true,
  '2026-01-01 00:00:00-03',
  '2027-12-31 23:59:59-03'
)
ON CONFLICT (codigo) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 3. CATEGORÍAS (12 categorías principales de la app)
-- ------------------------------------------------------------------------------
INSERT INTO public.categories (id, name, emoji) VALUES
  ('c0000001-0000-4000-8000-000000000001', 'Pizza', '🍕'),
  ('c0000002-0000-4000-8000-000000000002', 'Hamburguesas', '🍔'),
  ('c0000003-0000-4000-8000-000000000003', 'Empanadas', '🥟'),
  ('c0000004-0000-4000-8000-000000000004', 'Helados', '🍦'),
  ('c0000005-0000-4000-8000-000000000005', 'Súper', '🛒'),
  ('c0000006-0000-4000-8000-000000000006', 'Farmacia', '💊'),
  ('c0000007-0000-4000-8000-000000000007', 'Tacos', '🌮'),
  ('c0000008-0000-4000-8000-000000000008', 'Sushi', '🍣'),
  ('c0000009-0000-4000-8000-000000000009', 'Pollo', '🍗'),
  ('c0000010-0000-4000-8000-000000000010', 'Ensaladas', '🥗'),
  ('c0000011-0000-4000-8000-000000000011', 'Postres', '🧁'),
  ('c0000012-0000-4000-8000-000000000012', 'Café', '☕')
ON CONFLICT (id) DO NOTHING;


-- ==============================================================================
-- 4. LOCAL 1: Pizzería Ficticia ("Pizzería Don Atilio")
-- REEMPLAZAR_MAS_ADELANTE: Cambiar nombre, coordenadas y menú por comercio real.
-- Ubicación aproximada: Av. Alvear Oeste cerca de calle Paso, General Alvear.
-- ==============================================================================
INSERT INTO public.merchants (
  id,
  name,
  description,
  logo_url,
  banner_url,
  lat,
  lng,
  estado,
  comision_porcentaje,
  tiempo_estimado_min,
  costo_envio_base
) VALUES (
  'a1111111-1111-4111-8111-111111111111',
  'Pizzería Don Atilio',
  'Pizzas a la piedra al horno de leña tradicionales de General Alvear.',
  '/placeholder-pizza.jpg',
  '/placeholder-banner-pizza.jpg',
  -34.9741,
  -67.6965,
  'activo',
  12.50,
  30,
  120000 -- $1.200 ARS envío base
)
ON CONFLICT (id) DO NOTHING;

-- Relación con Categoría Pizza
INSERT INTO public.merchant_categories (merchant_id, category_id)
VALUES ('a1111111-1111-4111-8111-111111111111', 'c0000001-0000-4000-8000-000000000001')
ON CONFLICT (merchant_id, category_id) DO NOTHING;

-- Horarios Don Atilio: Martes a Domingo 19:30 a 00:30 (días 0=Dom, 2=Mar, 3=Mie, 4=Jue, 5=Vie, 6=Sab)
INSERT INTO public.merchant_hours (merchant_id, day_of_week, open_time, close_time) VALUES
  ('a1111111-1111-4111-8111-111111111111', 0, '19:30:00', '00:30:00'),
  ('a1111111-1111-4111-8111-111111111111', 2, '19:30:00', '00:30:00'),
  ('a1111111-1111-4111-8111-111111111111', 3, '19:30:00', '00:30:00'),
  ('a1111111-1111-4111-8111-111111111111', 4, '19:30:00', '00:30:00'),
  ('a1111111-1111-4111-8111-111111111111', 5, '19:30:00', '01:00:00'),
  ('a1111111-1111-4111-8111-111111111111', 6, '19:30:00', '01:00:00')
ON CONFLICT DO NOTHING;

-- Secciones de menú Don Atilio
INSERT INTO public.menu_sections (id, merchant_id, name, sequence) VALUES
  ('b1111111-1111-4111-8111-111111111111', 'a1111111-1111-4111-8111-111111111111', 'Pizzas Clásicas', 1),
  ('b1111111-1111-4111-8111-111111111112', 'a1111111-1111-4111-8111-111111111111', 'Bebidas', 2)
ON CONFLICT (id) DO NOTHING;

-- Productos Don Atilio (7 productos)
INSERT INTO public.products (id, section_id, name, description, price, is_available) VALUES
  ('d1111111-1111-4111-8111-111111111101', 'b1111111-1111-4111-8111-111111111111', 'Pizza Muzzarella Especial', 'Salsa de tomate casera, abundante muzzarella, aceitunas verdes y orégano mendocino.', 1150000, true), -- $11.500
  ('d1111111-1111-4111-8111-111111111102', 'b1111111-1111-4111-8111-111111111111', 'Pizza Fugazzeta Rellena', 'Doble masa rellena con muzzarella, cubierta con cebollas caramelizadas y provolone.', 1420000, true), -- $14.200
  ('d1111111-1111-4111-8111-111111111103', 'b1111111-1111-4111-8111-111111111111', 'Pizza Calabresa', 'Muzzarella, longaniza casera en rodajas, ají molido y morrones asados.', 1350000, true), -- $13.500
  ('d1111111-1111-4111-8111-111111111104', 'b1111111-1111-4111-8111-111111111111', 'Pizza Napolitana con Ajo', 'Rodajas de tomate fresco, muzzarella, ajo picado suave y hojas de albahaca.', 1280000, true), -- $12.800
  ('d1111111-1111-4111-8111-111111111105', 'b1111111-1111-4111-8111-111111111111', 'Pizza Cuatro Quesos', 'Muzzarella, roquefort, provolone y sardo gratinado.', 1490000, true), -- $14.900
  ('d1111111-1111-4111-8111-111111111106', 'b1111111-1111-4111-8111-111111111112', 'Cerveza Andes Origen Rubia 1L', 'Botella de litro retornable / descartable bien fría.', 340000, true), -- $3.400
  ('d1111111-1111-4111-8111-111111111107', 'b1111111-1111-4111-8111-111111111112', 'Gaseosa Coca-Cola 1.5L', 'Presentación familiar retornable.', 290000, true) -- $2.900
ON CONFLICT (id) DO NOTHING;

-- Opciones extra para pizzas Don Atilio
INSERT INTO public.product_options (product_id, name, price_modifier, is_required, max_choices) VALUES
  ('d1111111-1111-4111-8111-111111111101', 'Aceitunas negras extra', 90000, false, 1), -- +$900
  ('d1111111-1111-4111-8111-111111111101', 'Faina clásica (porción)', 150000, false, 2), -- +$1.500
  ('d1111111-1111-4111-8111-111111111102', 'Extra muzzarella gratinada', 200000, false, 1) -- +$2.000
ON CONFLICT DO NOTHING;


-- ==============================================================================
-- 5. LOCAL 2: Casa de Empanadas Ficticia ("El Rincón del Repulgue")
-- REEMPLAZAR_MAS_ADELANTE: Cambiar nombre, coordenadas y menú por comercio real.
-- Ubicación aproximada: Av. Libertador Sur cerca de calle Intendente Morales.
-- ==============================================================================
INSERT INTO public.merchants (
  id,
  name,
  description,
  logo_url,
  banner_url,
  lat,
  lng,
  estado,
  comision_porcentaje,
  tiempo_estimado_min,
  costo_envio_base
) VALUES (
  'a2222222-2222-4222-8222-222222222222',
  'El Rincón del Repulgue',
  'Empanadas mendocinas al horno de barro cortadas a cuchillo y sabores gourmet.',
  '/placeholder-empanadas.jpg',
  '/placeholder-banner-empanadas.jpg',
  -34.9760,
  -67.6978,
  'activo',
  10.00,
  25,
  100000 -- $1.000 ARS envío base
)
ON CONFLICT (id) DO NOTHING;

-- Relación con Categoría Empanadas
INSERT INTO public.merchant_categories (merchant_id, category_id)
VALUES ('a2222222-2222-4222-8222-222222222222', 'c0000003-0000-4000-8000-000000000003')
ON CONFLICT (merchant_id, category_id) DO NOTHING;

-- Horarios El Rincón del Repulgue: Lunes a Domingo mediodía y noche
INSERT INTO public.merchant_hours (merchant_id, day_of_week, open_time, close_time) VALUES
  ('a2222222-2222-4222-8222-222222222222', 0, '20:00:00', '00:00:00'),
  ('a2222222-2222-4222-8222-222222222222', 1, '20:00:00', '23:30:00'),
  ('a2222222-2222-4222-8222-222222222222', 2, '20:00:00', '23:30:00'),
  ('a2222222-2222-4222-8222-222222222222', 3, '20:00:00', '23:30:00'),
  ('a2222222-2222-4222-8222-222222222222', 4, '20:00:00', '00:00:00'),
  ('a2222222-2222-4222-8222-222222222222', 5, '20:00:00', '00:30:00'),
  ('a2222222-2222-4222-8222-222222222222', 6, '20:00:00', '00:30:00')
ON CONFLICT DO NOTHING;

-- Secciones de menú El Rincón del Repulgue
INSERT INTO public.menu_sections (id, merchant_id, name, sequence) VALUES
  ('b2222222-2222-4222-8222-222222222221', 'a2222222-2222-4222-8222-222222222222', 'Docenas y Promos', 1),
  ('b2222222-2222-4222-8222-222222222222', 'a2222222-2222-4222-8222-222222222222', 'Empanadas Individuales', 2)
ON CONFLICT (id) DO NOTHING;

-- Productos El Rincón del Repulgue (7 productos)
INSERT INTO public.products (id, section_id, name, description, price, is_available) VALUES
  ('d2222222-2222-4222-8222-222222222201', 'b2222222-2222-4222-8222-222222222221', 'Docena de Empanadas a Elección', '12 empanadas surtidas a gusto, cocinadas al horno de barro con masa casera.', 1440000, true), -- $14.400 ($1.200 c/u)
  ('d2222222-2222-4222-8222-222222222202', 'b2222222-2222-4222-8222-222222222221', 'Media Docena de Empanadas', '6 empanadas surtidas bien jugosas.', 750000, true), -- $7.500
  ('d2222222-2222-4222-8222-222222222203', 'b2222222-2222-4222-8222-222222222222', 'Carne Suave Cortada a Cuchillo', 'Nalga vacuna picada a mano, cebolla de verdeo, huevo duro y toque de comino.', 130000, true), -- $1.300
  ('d2222222-2222-4222-8222-222222222204', 'b2222222-2222-4222-8222-222222222222', 'Carne Picante Especial', 'Carne cortada a cuchillo con ají picante de la huerta alvearense.', 130000, true), -- $1.300
  ('d2222222-2222-4222-8222-222222222205', 'b2222222-2222-4222-8222-222222222222', 'Jamón y Queso Cremoso', 'Abundante queso cremoso y jamón cocido seleccionado.', 1250000, true), -- $1.250
  ('d2222222-2222-4222-8222-222222222206', 'b2222222-2222-4222-8222-222222222222', 'Humita Norteña Cremosa', 'Choclo dulce rallado, salsa blanca, cebolla y toque de queso gouda.', 1250000, true), -- $1.250
  ('d2222222-2222-4222-8222-222222222207', 'b2222222-2222-4222-8222-222222222222', 'Pollo al Verdeo', 'Pechuga desmechada con puerro, verdeo y crema suave.', 130000, true) -- $1.300
ON CONFLICT (id) DO NOTHING;

-- Opciones extra para Docena de empanadas
INSERT INTO public.product_options (product_id, name, price_modifier, is_required, max_choices) VALUES
  ('d2222222-2222-4222-8222-222222222201', 'Pote de salsa criolla casera', 80000, false, 2), -- +$800
  ('d2222222-2222-4222-8222-222222222201', 'Pote de chimichurri especial', 80000, false, 2) -- +$800
ON CONFLICT DO NOTHING;


-- ==============================================================================
-- 6. LOCAL 3: Hamburguesería Ficticia ("Fuego & Pan Burgers")
-- REEMPLAZAR_MAS_ADELANTE: Cambiar nombre, coordenadas y menú por comercio real.
-- Ubicación aproximada: Cerca de Plaza Carlos María de Alvear (calle San Martín).
-- ==============================================================================
INSERT INTO public.merchants (
  id,
  name,
  description,
  logo_url,
  banner_url,
  lat,
  lng,
  estado,
  comision_porcentaje,
  tiempo_estimado_min,
  costo_envio_base
) VALUES (
  'a3333333-3333-4333-8333-333333333333',
  'Fuego & Pan Burgers',
  'Smash burgers artesanales, medallones 100% novillo y papas rústicas crujientes.',
  '/placeholder-burger.jpg',
  '/placeholder-banner-burger.jpg',
  -34.9722,
  -67.6952,
  'activo',
  15.00,
  35,
  110000 -- $1.100 ARS envío base
)
ON CONFLICT (id) DO NOTHING;

-- Relación con Categoría Hamburguesas
INSERT INTO public.merchant_categories (merchant_id, category_id)
VALUES ('a3333333-3333-4333-8333-333333333333', 'c0000002-0000-4000-8000-000000000002')
ON CONFLICT (merchant_id, category_id) DO NOTHING;

-- Horarios Fuego & Pan Burgers: Miércoles a Domingo 20:00 a 01:00
INSERT INTO public.merchant_hours (merchant_id, day_of_week, open_time, close_time) VALUES
  ('a3333333-3333-4333-8333-333333333333', 0, '20:00:00', '01:00:00'),
  ('a3333333-3333-4333-8333-333333333333', 3, '20:00:00', '00:30:00'),
  ('a3333333-3333-4333-8333-333333333333', 4, '20:00:00', '00:30:00'),
  ('a3333333-3333-4333-8333-333333333333', 5, '20:00:00', '01:30:00'),
  ('a3333333-3333-4333-8333-333333333333', 6, '20:00:00', '01:30:00')
ON CONFLICT DO NOTHING;

-- Secciones de menú Fuego & Pan Burgers
INSERT INTO public.menu_sections (id, merchant_id, name, sequence) VALUES
  ('b3333333-3333-4333-8333-333333333331', 'a3333333-3333-4333-8333-333333333333', 'Hamburguesas Smash', 1),
  ('b3333333-3333-4333-8333-333333333332', 'a3333333-3333-4333-8333-333333333333', 'Acompañamientos', 2)
ON CONFLICT (id) DO NOTHING;

-- Productos Fuego & Pan Burgers (7 productos)
INSERT INTO public.products (id, section_id, name, description, price, is_available) VALUES
  ('d3333333-3333-4333-8333-333333333301', 'b3333333-3333-4333-8333-333333333331', 'Smash Cheeseburger Doble', 'Doble medallón smash (90g c/u), cuádruple cheddar milkaut, cebolla picada y salsa especial en pan brioche de papa.', 980000, true), -- $9.800
  ('d3333333-3333-4333-8333-333333333302', 'b3333333-3333-4333-8333-333333333331', 'Bacon King Alvear', 'Doble carne smash, cuádruple cheddar, panceta crocante ahumada y salsa barbacoa.', 1120000, true), -- $11.200
  ('d3333333-3333-4333-8333-333333333303', 'b3333333-3333-4333-8333-333333333331', 'La Mendocina Criolla', 'Doble medallón, provoleta fundida, chimichurri artesanal, lechuga y tomate en pan brioche.', 1090000, true), -- $10.900
  ('d3333333-3333-4333-8333-333333333304', 'b3333333-3333-4333-8333-333333333331', 'Crispy Chicken Burger', 'Pechuga de pollo rebozada ultra crocante, lechuga capuchina, mayonesa de ajo y pepinillos agridulces.', 950000, true), -- $9.500
  ('d3333333-3333-4333-8333-333333333305', 'b3333333-3333-4333-8333-333333333331', 'Veggie NotBurger', 'Medallón plant-based, queso tybo fundido, palta laminada, cebolla morada y rúcula.', 1020000, true), -- $10.200
  ('d3333333-3333-4333-8333-333333333306', 'b3333333-3333-4333-8333-333333333332', 'Papas Fritas Rústicas Grandes', 'Papas con piel crujientes por fuera y tiernas por dentro, sazonadas.', 450000, true), -- $4.500
  ('d3333333-3333-4333-8333-333333333307', 'b3333333-3333-4333-8333-333333333332', 'Papas Cheddar & Panceta', 'Papas rústicas bañadas en salsa cheddar caliente y lluvia de panceta crocante.', 680000, true) -- $6.800
ON CONFLICT (id) DO NOTHING;

-- Opciones extra para hamburguesas Fuego & Pan
INSERT INTO public.product_options (product_id, name, price_modifier, is_required, max_choices) VALUES
  ('d3333333-3333-4333-8333-333333333301', 'Medallón smash extra (90g)', 220000, false, 2), -- +$2.200
  ('d3333333-3333-4333-8333-333333333301', 'Bacon crocante extra', 150000, false, 2), -- +$1.500
  ('d3333333-3333-4333-8333-333333333302', 'Dip extra de salsa barbacoa', 70000, false, 2), -- +$700
  ('d3333333-3333-4333-8333-333333333306', 'Cheddar fundido en pote', 120000, false, 2) -- +$1.200
ON CONFLICT DO NOTHING;
