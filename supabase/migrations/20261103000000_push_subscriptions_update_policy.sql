-- Permitir a los usuarios actualizar sus suscripciones existentes al registrar/renovar su token
CREATE POLICY "Usuarios pueden actualizar sus propias suscripciones"
ON public.push_subscriptions FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
