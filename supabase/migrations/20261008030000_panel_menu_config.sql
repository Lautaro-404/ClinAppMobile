-- Políticas para merchant_hours (Local CUD propio)
CREATE POLICY "Merchant hours - local CUD propio"
  ON public.merchant_hours FOR ALL
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

-- Storage bucket para imágenes de productos
INSERT INTO storage.buckets (id, name, public) VALUES ('productos', 'productos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies para 'productos'
CREATE POLICY "Imágenes de productos lectura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'productos');

CREATE POLICY "Locales pueden subir y modificar imágenes"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'productos'
    AND public.current_user_rol() = 'local'
  )
  WITH CHECK (
    bucket_id = 'productos'
    AND public.current_user_rol() = 'local'
  );
