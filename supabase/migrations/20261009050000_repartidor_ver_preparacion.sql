-- Actualizar políticas para que el repartidor también vea pedidos 'en_preparacion'
DROP POLICY IF EXISTS "Pedidos – repartidor SELECT disponibles y asignados" ON public.orders;

CREATE POLICY "Pedidos – repartidor SELECT disponibles y asignados"
  ON public.orders FOR SELECT
  USING (
    courier_id = auth.uid()
    OR (courier_id IS NULL AND estado IN ('listo_para_retirar', 'en_preparacion'))
  );

DROP POLICY IF EXISTS "Pedidos – repartidor UPDATE tomar y gestionar" ON public.orders;

CREATE POLICY "Pedidos – repartidor UPDATE tomar y gestionar"
  ON public.orders FOR UPDATE
  USING (
    courier_id = auth.uid()
    OR (courier_id IS NULL AND estado IN ('listo_para_retirar', 'en_preparacion'))
  );
