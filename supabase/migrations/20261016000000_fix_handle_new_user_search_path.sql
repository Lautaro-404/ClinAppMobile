-- =============================================================
-- Migración: Corregir search_path y tipos en trigger handle_new_user
-- Archivo: 20261016000000_fix_handle_new_user_search_path.sql
-- =============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_merchant_owner BOOLEAN := false;
  v_rol public.user_role := 'cliente';
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
$$;
