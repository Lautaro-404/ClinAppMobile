-- Migración: soporte a Mercado Pago
-- Agrega campos necesarios en orders y payments para el flujo de pago

-- Campo para indicar con cuánto paga el cliente en efectivo (para el vuelto)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS vuelto_para INTEGER;
-- vuelto_para NULL = no aplica (pago digital)
-- vuelto_para > 0  = el cliente paga con ese monto y espera vuelto

-- Índice en payments por external_id para búsquedas rápidas del webhook
CREATE INDEX IF NOT EXISTS idx_payments_external_id ON public.payments(external_id);

-- Índice en payments por order_id + method para búsquedas del webhook
CREATE INDEX IF NOT EXISTS idx_payments_order_method ON public.payments(order_id, method);

COMMENT ON COLUMN public.orders.vuelto_para IS
  'Monto en centavos con el que paga el cliente en efectivo. NULL si paga digital.';
COMMENT ON COLUMN public.payments.external_id IS
  'ID de la preferencia o del pago en Mercado Pago';
