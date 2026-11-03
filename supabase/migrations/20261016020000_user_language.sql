-- Migración: Agregar columna language a profiles para persistencia de preferencia de idioma
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'es'
CHECK (language IN ('es', 'en'));

COMMENT ON COLUMN public.profiles.language IS 'Idioma preferido del usuario: es (Español) o en (English)';
