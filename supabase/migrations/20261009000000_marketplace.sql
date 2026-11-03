-- Migración para Mercado Pago Marketplace (Split de pagos)

ALTER TABLE public.merchants 
  ADD COLUMN mp_access_token TEXT,
  ADD COLUMN mp_refresh_token TEXT,
  ADD COLUMN mp_user_id TEXT;
