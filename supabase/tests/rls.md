# Casos de prueba manuales – Row Level Security

Usá la UI de Supabase (Table Editor → RLS) o `psql` con roles distintos para verificar cada caso.

## Usuarios de prueba necesarios

| Alias          | Rol         | Plan | Merchant asociado |
|----------------|-------------|------|-------------------|
| `alice`        | `cliente`   | free | —                 |
| `bob`          | `cliente`   | plus | —                 |
| `dueño`        | `local`     | free | `owner_id = dueño.id` en merchants.id = M1 |
| `courier`      | `repartidor`| free | —                 |
| `superadmin`   | `admin`     | plus | —                 |
| `anon`         | sin sesión  | —    | —                 |

---

## 1. Catálogo público (tablas de solo lectura)

| # | Tabla                | Usuario  | Operación            | Resultado esperado |
|---|----------------------|----------|----------------------|--------------------|
| 1 | `categories`         | `anon`   | SELECT *             | ✅ Devuelve filas   |
| 2 | `merchants`          | `anon`   | SELECT *             | ✅ Solo los `activo`; los `pausado` no aparecen |
| 3 | `merchants`          | `anon`   | INSERT               | 🚫 Rechazado        |
| 4 | `menu_sections`      | `anon`   | SELECT donde merchant activo | ✅ Devuelve filas |
| 5 | `products`           | `anon`   | SELECT               | ✅ Solo `is_available = true` en merchants activos |
| 6 | `products`           | `alice`  | DELETE               | 🚫 Rechazado        |
| 7 | `delivery_zones`     | `anon`   | SELECT               | ✅ Solo las activas  |
| 8 | `coupons`            | `anon`   | SELECT               | ✅ Devuelve filas   |
| 9 | `coupons`            | `anon`   | INSERT               | 🚫 Rechazado        |

---

## 2. Perfil propio

| # | Tabla      | Usuario | Operación                            | Resultado esperado |
|---|------------|---------|--------------------------------------|--------------------|
| 10 | `profiles` | `alice` | SELECT WHERE id = alice.id           | ✅ 1 fila           |
| 11 | `profiles` | `alice` | SELECT WHERE id = bob.id             | 🚫 0 filas          |
| 12 | `profiles` | `alice` | UPDATE nombre WHERE id = alice.id    | ✅ OK               |
| 13 | `profiles` | `alice` | UPDATE nombre WHERE id = bob.id      | 🚫 Rechazado        |
| 14 | `profiles` | `alice` | UPDATE rol = 'admin' (su propio id)  | 🚫 Rechazado (campo no expuesto o política) |

---

## 3. Direcciones, Favoritos y Notificaciones

| # | Tabla           | Usuario | Operación                              | Resultado esperado |
|---|-----------------|---------|----------------------------------------|--------------------|
| 15 | `addresses`    | `alice` | SELECT WHERE profile_id = alice.id     | ✅ Sus direcciones  |
| 16 | `addresses`    | `alice` | SELECT WHERE profile_id = bob.id       | 🚫 0 filas          |
| 17 | `addresses`    | `alice` | INSERT con profile_id = alice.id       | ✅ OK               |
| 18 | `addresses`    | `alice` | INSERT con profile_id = bob.id         | 🚫 Rechazado        |
| 19 | `favorites`    | `alice` | INSERT merchant M1                     | ✅ OK               |
| 20 | `favorites`    | `alice` | SELECT                                 | ✅ Solo los suyos   |
| 21 | `notifications`| `alice` | SELECT                                 | ✅ Solo las suyas   |
| 22 | `notifications`| `alice` | UPDATE is_read = true                  | ✅ OK               |
| 23 | `notifications`| `alice` | INSERT (desde cliente)                 | 🚫 Rechazado (no hay policy de INSERT para cliente) |

---

## 4. Pedidos – cliente

| # | Tabla                  | Usuario | Operación                                | Resultado esperado |
|---|------------------------|---------|------------------------------------------|--------------------|
| 24 | `orders`              | `alice` | SELECT *                                 | ✅ Solo los de alice |
| 25 | `orders`              | `alice` | SELECT WHERE user_id = bob.id            | 🚫 0 filas          |
| 26 | `orders`              | `alice` | INSERT con user_id = alice.id            | ✅ OK               |
| 27 | `orders`              | `alice` | INSERT con user_id = bob.id              | 🚫 Rechazado        |
| 28 | `order_items`         | `alice` | SELECT items del pedido de alice         | ✅ OK               |
| 29 | `order_items`         | `alice` | SELECT items de un pedido de bob         | 🚫 0 filas          |
| 30 | `order_status_history`| `alice` | SELECT historial del pedido de alice     | ✅ OK               |

---

## 5. Pedidos – local (dueño)

| # | Tabla                  | Usuario | Operación                                        | Resultado esperado |
|---|------------------------|---------|--------------------------------------------------|--------------------|
| 31 | `orders`              | `dueño` | SELECT pedidos de su merchant M1                 | ✅ OK               |
| 32 | `orders`              | `dueño` | SELECT pedidos de otro merchant M2               | 🚫 0 filas          |
| 33 | `orders`              | `dueño` | UPDATE estado = 'aceptado_por_local' de su pedido| ✅ OK               |
| 34 | `orders`              | `dueño` | UPDATE estado de un pedido de M2                 | 🚫 Rechazado        |
| 35 | `menu_sections`       | `dueño` | INSERT sección en su merchant M1                 | ✅ OK               |
| 36 | `menu_sections`       | `dueño` | INSERT sección en merchant M2                    | 🚫 Rechazado        |
| 37 | `products`            | `dueño` | UPDATE precio de un producto de M1               | ✅ OK               |
| 38 | `products`            | `dueño` | DELETE producto de M2                            | 🚫 Rechazado        |
| 39 | `product_options`     | `dueño` | INSERT opción en producto de M1                  | ✅ OK               |

---

## 6. Pedidos – repartidor

| # | Tabla    | Usuario   | Operación                                      | Resultado esperado |
|---|----------|-----------|------------------------------------------------|--------------------|
| 40 | `orders` | `courier` | SELECT WHERE courier_id = courier.id           | ✅ Sus asignados    |
| 41 | `orders` | `courier` | SELECT WHERE courier_id IS NULL o de otro      | 🚫 0 filas          |
| 42 | `orders` | `courier` | UPDATE estado = 'en_camino' de su pedido       | ✅ OK               |
| 43 | `orders` | `courier` | UPDATE estado de pedido no asignado a él       | 🚫 Rechazado        |
| 44 | `courier_locations` | `courier` | INSERT/UPDATE su propia ubicación | ✅ OK               |
| 45 | `courier_locations` | `alice`   | INSERT ubicación de otro courier  | 🚫 Rechazado        |

---

## 7. Admin

| # | Tabla             | Usuario      | Operación                                | Resultado esperado |
|---|-------------------|--------------|------------------------------------------|--------------------|
| 46 | `categories`     | `superadmin` | INSERT nueva categoría                   | ✅ OK               |
| 47 | `categories`     | `alice`      | INSERT nueva categoría                   | 🚫 Rechazado        |
| 48 | `coupons`        | `superadmin` | INSERT cupón                             | ✅ OK               |
| 49 | `coupons`        | `alice`      | INSERT cupón                             | 🚫 Rechazado        |
| 50 | `merchants`      | `superadmin` | UPDATE comision_porcentaje               | ✅ OK               |
| 51 | `merchants`      | `dueño`      | UPDATE comision_porcentaje (campo ajeno) | 🚫 Rechazado (RLS bloquea) |
| 52 | `delivery_zones` | `superadmin` | INSERT zona                              | ✅ OK               |
| 53 | `profiles`       | `superadmin` | SELECT todas las filas                   | ✅ Ve todos          |
| 54 | `orders`         | `superadmin` | SELECT *                                 | ✅ Ve todos          |

---

## 8. Payments y Coupon Redemptions (solo service_role)

| # | Tabla                  | Usuario      | Operación  | Resultado esperado |
|---|------------------------|--------------|------------|--------------------|
| 55 | `payments`            | `alice`      | SELECT     | 🚫 0 filas (RLS habilitado, sin política) |
| 56 | `payments`            | `alice`      | INSERT     | 🚫 Rechazado        |
| 57 | `payments`            | `superadmin` | SELECT     | 🚫 0 filas (no hay política admin) |
| 58 | `payments`            | `service_role` (servidor) | INSERT | ✅ OK (service_role bypasea RLS) |
| 59 | `coupon_redemptions`  | `alice`      | INSERT     | 🚫 Rechazado        |
| 60 | `coupon_redemptions`  | `service_role` (servidor) | INSERT | ✅ OK |

---

## 9. Reviews

| # | Tabla      | Usuario | Operación                                      | Resultado esperado |
|---|------------|---------|------------------------------------------------|--------------------|
| 61 | `reviews` | `alice` | SELECT sus propias reseñas                     | ✅ OK               |
| 62 | `reviews` | `alice` | SELECT reseña de bob                           | 🚫 0 filas          |
| 63 | `reviews` | `alice` | INSERT reseña en pedido propio con estado 'entregado' | ✅ OK        |
| 64 | `reviews` | `alice` | INSERT reseña en pedido que no es suyo         | 🚫 Rechazado        |
| 65 | `reviews` | `alice` | INSERT reseña en pedido propio en estado 'creado' | 🚫 Rechazado (solo 'entregado') |
| 66 | `reviews` | `dueño` | SELECT reseñas de su merchant M1               | ✅ OK               |
| 67 | `reviews` | `superadmin` | SELECT *                                   | ✅ Ve todas          |

---

## Cómo ejecutar las pruebas en Supabase

```sql
-- Simular un usuario concreto (reemplazar con el UUID real)
SET request.jwt.claims TO '{"sub":"UUID-DE-ALICE","role":"authenticated"}';

-- Verificar qué se ve
SELECT * FROM public.orders;

-- Volver al service_role
RESET request.jwt.claims;
```

> [!IMPORTANT]
> La función `auth.current_user_rol()` hace un `SELECT` en `profiles`. Asegurate de que cada usuario de prueba tenga una fila en `profiles` con el rol correcto antes de correr los tests.

> [!NOTE]
> Las políticas de `merchants` tienen dos capas: lectura pública (activos) y escritura por `local` u `admin`. Si un local está en estado `pausado`, su local no aparece en el catálogo público, pero el dueño (`local`) sí lo puede ver por la política de su rol.
