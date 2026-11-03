-- Migración de Módulos Generales: Clientes (Billetera y Ban) y Marketing (Banners)

-- 1. Actualizar tabla profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS wallet_balance INTEGER DEFAULT 0;

-- 2. Crear tabla de Marketing Banners
CREATE TABLE IF NOT EXISTS marketing_banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  subtitle TEXT,
  details TEXT,
  image_url TEXT,
  active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Políticas RLS para marketing_banners
ALTER TABLE marketing_banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Banners son públicos para lectura"
  ON marketing_banners FOR SELECT
  USING (true);

CREATE POLICY "Solo admins pueden modificar banners"
  ON marketing_banners FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.rol = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.rol = 'admin'
    )
  );
