-- Fix infinite recursion in menu_sections policy
DROP POLICY IF EXISTS "Catálogo – menu_sections lectura pública" ON public.menu_sections;
CREATE POLICY "Catálogo – menu_sections lectura pública"
  ON public.menu_sections FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.merchants m
      WHERE m.id = merchant_id AND m.estado = 'activo'
    )
  );
