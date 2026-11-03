-- Agregar columna owner_email a merchants
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS owner_email TEXT;

-- Modificar la función handle_new_user para que asigne el rol de dueño si el correo coincide
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_is_merchant_owner BOOLEAN;
  v_rol user_role;
BEGIN
  -- Verificar si el email coincide con el owner_email de algún local
  SELECT EXISTS(
    SELECT 1 FROM public.merchants WHERE owner_email = NEW.email
  ) INTO v_is_merchant_owner;

  IF v_is_merchant_owner THEN
    v_rol := 'local';
  ELSE
    v_rol := 'cliente';
  END IF;

  -- Insertar el perfil
  INSERT INTO public.profiles (id, nombre, telefono, rol, plan)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.phone,
    v_rol,
    'free'
  );

  -- Si es dueño de un local, actualizar el owner_id en la tabla merchants
  IF v_is_merchant_owner THEN
    UPDATE public.merchants
    SET owner_id = NEW.id
    WHERE owner_email = NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
