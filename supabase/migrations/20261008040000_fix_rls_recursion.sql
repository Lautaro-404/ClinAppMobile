-- Fix infinite recursion by using plpgsql to prevent planner inlining
CREATE OR REPLACE FUNCTION public.current_user_rol()
RETURNS user_role
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rol user_role;
BEGIN
  SELECT rol INTO v_rol FROM profiles WHERE id = auth.uid();
  RETURN COALESCE(v_rol, 'cliente'::user_role);
END;
$$;
