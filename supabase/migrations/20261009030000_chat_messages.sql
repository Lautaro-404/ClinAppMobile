-- Chat Messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast retrieval
CREATE INDEX IF NOT EXISTS idx_chat_messages_order ON chat_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);

-- RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participantes pueden ver el chat" ON chat_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = chat_messages.order_id
      AND (orders.user_id = auth.uid() OR orders.courier_id = auth.uid())
    )
  );

CREATE POLICY "Participantes pueden enviar mensajes" ON chat_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = chat_messages.order_id
      AND (orders.user_id = auth.uid() OR orders.courier_id = auth.uid())
    )
  );

-- Habilitar Realtime para esta tabla si no está habilitado
-- (Esto asume que se publicarán insertes a esta tabla para la app de React)
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
