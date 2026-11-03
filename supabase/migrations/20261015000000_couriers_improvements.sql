-- =============================================================
-- Migración: Limpieza de repartidor demo y soporte para repartidores reales
-- Archivo: 20261015000000_couriers_improvements.sql
-- =============================================================

-- 1. Eliminar referencias y datos del repartidor de prueba Lucas
UPDATE public.orders 
SET courier_id = NULL 
WHERE courier_id = 'c0000000-0000-0000-0000-000000000001';

DELETE FROM public.courier_locations 
WHERE courier_id = 'c0000000-0000-0000-0000-000000000001';

DELETE FROM public.profiles 
WHERE id = 'c0000000-0000-0000-0000-000000000001';

DELETE FROM auth.users 
WHERE id = 'c0000000-0000-0000-0000-000000000001';

-- 2. Asegurar columna email en profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS email TEXT;

UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id AND p.email IS NULL;

-- 3. Actualizar trigger handle_new_user para guardar el email en el perfil
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_is_merchant_owner BOOLEAN;
  v_rol user_role;
BEGIN
  -- Si el correo es el administrador designado
  IF LOWER(NEW.email) = 'alejot861@gmail.com' THEN
    v_rol := 'admin';
  ELSE
    -- Verificar si el email coincide con el owner_email de algún local
    SELECT EXISTS(
      SELECT 1 FROM public.merchants WHERE owner_email = NEW.email
    ) INTO v_is_merchant_owner;

    IF v_is_merchant_owner THEN
      v_rol := 'local';
    ELSE
      v_rol := 'cliente';
    END IF;
  END IF;

  -- Insertar o actualizar el perfil
  INSERT INTO public.profiles (id, nombre, telefono, email, rol, plan)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    COALESCE(NEW.phone, NEW.raw_user_meta_data->>'telefono', NEW.raw_user_meta_data->>'phone'),
    NEW.email,
    v_rol,
    'free'
  )
  ON CONFLICT (id) DO UPDATE
  SET rol = EXCLUDED.rol,
      email = EXCLUDED.email;

  -- Si es dueño de un local, actualizar el owner_id en la tabla merchants
  IF v_is_merchant_owner THEN
    UPDATE public.merchants
    SET owner_id = NEW.id
    WHERE owner_email = NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Política para que admin pueda eliminar o desvincular perfiles si es necesario
DROP POLICY IF EXISTS "Admin – profiles DELETE all" ON public.profiles;
CREATE POLICY "Admin – profiles DELETE all"
  ON public.profiles FOR DELETE
  USING (public.current_user_rol() = 'admin');
