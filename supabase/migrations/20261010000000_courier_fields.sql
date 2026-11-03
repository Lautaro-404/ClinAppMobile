-- Agregar campos para detalles del vehículo a los repartidores
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS vehiculo TEXT,
ADD COLUMN IF NOT EXISTS patente TEXT;
