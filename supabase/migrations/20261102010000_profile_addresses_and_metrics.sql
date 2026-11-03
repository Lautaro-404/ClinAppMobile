-- Migración: Soporte para direcciones completas, puntos y métricas de perfil
-- Archivo: 20261102010000_profile_addresses_and_metrics.sql

-- 1. Agregar columnas a profiles para puntos de fidelidad
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS puntos INTEGER DEFAULT 0;

-- 2. Agregar columnas a addresses para título (ej. Casa, Trabajo) y predeterminada
ALTER TABLE public.addresses
ADD COLUMN IF NOT EXISTS title TEXT DEFAULT 'Casa',
ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

-- 3. Índice para acelerar la consulta de la dirección predeterminada del usuario
CREATE INDEX IF NOT EXISTS idx_addresses_profile_default
  ON public.addresses(profile_id, is_default);

-- 4. RPC para métricas de perfil consolidadas (saldo ClinPay, puntos, pedidos y total gastado)
CREATE OR REPLACE FUNCTION public.get_user_profile_metrics()
RETURNS TABLE (
  orders_count BIGINT,
  total_spent_cents BIGINT,
  clinpay_balance_cents INTEGER,
  points INTEGER,
  rating_text TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_orders_count BIGINT := 0;
  v_total_spent BIGINT := 0;
  v_wallet INTEGER := 0;
  v_points INTEGER := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  -- Conteo de pedidos y total gastado
  SELECT COUNT(*), COALESCE(SUM(total), 0)
  INTO v_orders_count, v_total_spent
  FROM public.orders
  WHERE user_id = v_user_id;

  -- Saldo de billetera y puntos desde profiles
  SELECT COALESCE(wallet_balance, 0), COALESCE(puntos, 0)
  INTO v_wallet, v_points
  FROM public.profiles
  WHERE id = v_user_id;

  RETURN QUERY SELECT
    v_orders_count,
    v_total_spent,
    v_wallet,
    v_points,
    '5,0'::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_profile_metrics() TO authenticated;
