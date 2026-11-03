-- =============================================================
-- Migración: Asignar rol de admin a alejot861@gmail.com
-- Archivo: 20261013010000_assign_admin_role.sql
-- =============================================================

-- 1. Actualizar el perfil si el usuario ya existe en auth.users
UPDATE public.profiles
SET rol = 'admin'
WHERE id IN (
  SELECT id FROM auth.users WHERE LOWER(email) = 'alejot861@gmail.com'
);

-- 2. Actualizar los metadatos del usuario en auth.users si ya existe
UPDATE auth.users
SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"rol": "admin"}'::jsonb
WHERE LOWER(email) = 'alejot861@gmail.com';

-- 3. Actualizar la función handle_new_user para que asigne 'admin' automáticamente
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
  INSERT INTO public.profiles (id, nombre, telefono, rol, plan)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.phone,
    v_rol,
    'free'
  )
  ON CONFLICT (id) DO UPDATE
  SET rol = EXCLUDED.rol;

  -- Si es dueño de un local, actualizar el owner_id en la tabla merchants
  IF v_is_merchant_owner THEN
    UPDATE public.merchants
    SET owner_id = NEW.id
    WHERE owner_email = NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
