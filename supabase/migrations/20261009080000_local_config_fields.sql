-- Agregar columna address a merchants
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS address TEXT;

-- Storage bucket para imágenes de locales (logo, banner)
INSERT INTO storage.buckets (id, name, public) VALUES ('locales', 'locales', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies para 'locales'
CREATE POLICY "Imágenes de locales lectura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'locales');

CREATE POLICY "Locales pueden subir y modificar sus imágenes"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'locales'
    AND public.current_user_rol() = 'local'
  )
  WITH CHECK (
    bucket_id = 'locales'
    AND public.current_user_rol() = 'local'
  );
