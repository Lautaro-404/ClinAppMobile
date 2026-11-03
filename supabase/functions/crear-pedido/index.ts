// Edge Function: crear-pedido
// Deno / Supabase Edge Runtime
// Zona horaria: America/Argentina/Mendoza

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── Tipos de entrada ────────────────────────────────────────────────────────

interface ItemInput {
  product_id: string;
  cantidad: number;
  opciones: string[]; // IDs de product_options seleccionados
  nota?: string;
}

interface CrearPedidoBody {
  merchant_id: string;
  address_id: string;
  items: ItemInput[];
  propina: number; // en centavos
  codigo_cupon?: string;
  metodo_pago: 'efectivo' | 'clinpay' | 'mercado_pago';
  /** Solo para efectivo: monto con el que paga el cliente (en centavos) para calcular vuelto */
  vuelto_para?: number;
  /** Instrucciones de entrega o notas para el repartidor */
  special_instructions?: string;
  /** Identificador de idempotencia del cliente */
  client_request_id?: string;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const DEFAULT_ALLOWED_ORIGINS = [
  'https://clin-app-ivory.vercel.app',
  'https://clin.app',
  'https://www.clin.app',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
];

function getCorsOrigin(req?: Request): string {
  const envOrigins = Deno.env.get('ALLOWED_ORIGINS');
  const allowed = envOrigins
    ? envOrigins.split(',').map((o) => o.trim()).filter(Boolean)
    : DEFAULT_ALLOWED_ORIGINS;
  const reqOrigin = req?.headers.get('Origin') ?? '';
  if (reqOrigin && allowed.includes(reqOrigin)) {
    return reqOrigin;
  }
  return allowed[0] ?? 'https://clin-app-ivory.vercel.app';
}

function jsonOk(data: unknown, status = 200, req?: Request) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': getCorsOrigin(req),
      Vary: 'Origin',
    },
  });
}

function jsonError(mensaje: string, status = 400, req?: Request) {
  return new Response(JSON.stringify({ error: mensaje }), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': getCorsOrigin(req),
      Vary: 'Origin',
    },
  });
}

/** Verifica si un punto (lat, lng) cae dentro de un polígono GeoJSON (coordenadas [lng, lat]).
 *  Usa el algoritmo ray-casting. */
function puntoDentroDePoligono(
  lat: number,
  lng: number,
  coordinates: number[][],
): boolean {
  let inside = false;
  const n = coordinates.length;
  for (let i = 0, j = n - 1; i < n; j = i++) {
    const xi = coordinates[i][0]; // lng
    const yi = coordinates[i][1]; // lat
    const xj = coordinates[j][0]; // lng
    const yj = coordinates[j][1]; // lat
    const intersect =
      yi > lat !== yj > lat && lng < ((xj - xi) * (lat - yi)) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}

function haversineDistanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  if (lat1 === lat2 && lng1 === lng2) return 0;
  const toRad = (v: number) => (v * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(6371 * c * 100) / 100;
}

/** Devuelve la hora actual en Argentina/Mendoza como string HH:MM:SS */
function horaActualMendoza(): { timeStr: string; dayOfWeek: number } {
  const now = new Date();
  const mendozaStr = now.toLocaleString('en-US', {
    timeZone: 'America/Argentina/Mendoza',
  });
  const mendoza = new Date(mendozaStr);
  const h = mendoza.getHours().toString().padStart(2, '0');
  const m = mendoza.getMinutes().toString().padStart(2, '0');
  const s = mendoza.getSeconds().toString().padStart(2, '0');
  return { timeStr: `${h}:${m}:${s}`, dayOfWeek: mendoza.getDay() };
}

// ─── Handler principal ───────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': getCorsOrigin(req),
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        Vary: 'Origin',
      },
    });
  }

  // ── 1. Autenticación ──────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return jsonError('No autorizado: falta encabezado de autenticación', 401, req);

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  // Cliente con service role para validación de token y operaciones del pedido
  const supabaseAdmin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  const {
    data: { user },
    error: authError,
  } = await supabaseAdmin.auth.getUser(token);

  if (authError || !user) {
    console.error('Error de autenticación en crear-pedido:', authError);
    return jsonError('No autorizado: tu sesión expiró o es inválida. Por favor volvé a iniciar sesión.', 401, req);
  }

  // ── 2. Parsear cuerpo ─────────────────────────────────────────────────────
  let body: CrearPedidoBody;
  try {
    body = await req.json();
  } catch {
    return jsonError('Cuerpo JSON inválido', 400, req);
  }

  const { merchant_id, address_id, items, propina, codigo_cupon, metodo_pago, vuelto_para, special_instructions } = body;

  if (!merchant_id || !address_id || !Array.isArray(items) || items.length === 0) {
    return jsonError('Faltan campos obligatorios: merchant_id, address_id, items', 400, req);
  }
  if (items.length > 50) {
    return jsonError('El pedido supera el máximo de 50 ítems permitidos', 400, req);
  }
  if (!['efectivo', 'clinpay', 'mercado_pago'].includes(metodo_pago)) {
    return jsonError('Método de pago inválido', 400, req);
  }
  if (
    typeof propina !== 'number' ||
    !Number.isFinite(propina) ||
    !Number.isInteger(propina) ||
    propina < 0 ||
    propina > 10_000_000
  ) {
    return jsonError('Propina inválida', 400, req);
  }
  if (metodo_pago === 'efectivo' && vuelto_para !== undefined && vuelto_para !== null) {
    if (
      typeof vuelto_para !== 'number' ||
      !Number.isFinite(vuelto_para) ||
      !Number.isInteger(vuelto_para) ||
      vuelto_para < 0 ||
      vuelto_para > 100_000_000
    ) {
      return jsonError('Monto para vuelto inválido', 400, req);
    }
  }

  // ── 3. Verificar que el local existe y está activo ────────────────────────
  const { data: merchant, error: merchantError } = await supabaseAdmin
    .from('merchants')
    .select('id, estado, costo_envio_base, lat, lng, merchant_hours(day_of_week, open_time, close_time)')
    .eq('id', merchant_id)
    .single();

  if (merchantError || !merchant) return jsonError('Local no encontrado', 404);
  if (merchant.estado !== 'activo') return jsonError('El local no está disponible en este momento');

  // ── 4. Verificar horario de apertura ─────────────────────────────────────
  const { timeStr, dayOfWeek } = horaActualMendoza();
  const isSunday = dayOfWeek === 0;

  type MerchantHour = { day_of_week: number; open_time: string; close_time: string };
  const hours: MerchantHour[] = (merchant.merchant_hours as MerchantHour[]) ?? [];

  // Temporal para facilitar pruebas: si el local no tiene horarios, asumimos que está abierto
  if (hours.length === 0) {
    // Abierto 24/7 por defecto si no hay horarios
  } else {
    const todayHours = hours.filter(
      (h) => h.day_of_week === dayOfWeek || (isSunday && h.day_of_week === 7),
    );

    const estaAbierto = todayHours.some(
      (h) => timeStr >= h.open_time && timeStr <= h.close_time,
    );

    if (!estaAbierto) return jsonError('El local está cerrado en este momento');
  }

  // ── 5. Verificar dirección del usuario ───────────────────────────────────
  const { data: address, error: addressError } = await supabaseAdmin
    .from('addresses')
    .select('id, profile_id, lat, lng')
    .eq('id', address_id)
    .single();

  if (addressError || !address) return jsonError('Dirección no encontrada', 404);
  if (address.profile_id !== user.id) return jsonError('La dirección no pertenece al usuario', 403);

  // ── 6. Verificar zona de entrega ─────────────────────────────────────────
  const { data: zones } = await supabaseAdmin
    .from('delivery_zones')
    .select('id, name, polygon_geojson, costo_adicional_centavos')
    .eq('active', true);

  type DeliveryZoneRow = {
    id: string;
    name: string;
    polygon_geojson: unknown;
    costo_adicional_centavos?: number;
  };
  let zonaDestino: DeliveryZoneRow | null = null;

  if ((zones ?? []).length > 0) {
    if (address.lat === null || address.lng === null) {
      return jsonError('La dirección de entrega está fuera de la zona de cobertura', 400, req);
    }

    const lat = Number(address.lat);
    const lng = Number(address.lng);

    for (const zone of (zones as DeliveryZoneRow[]) ?? []) {
      try {
        const geojson = zone.polygon_geojson as {
          type?: string;
          coordinates?: number[][][];
          geometry?: { type?: string; coordinates?: number[][][] };
        };
        const coords = geojson?.coordinates?.[0] || geojson?.geometry?.coordinates?.[0];
        if (coords && puntoDentroDePoligono(lat, lng, coords)) {
          zonaDestino = zone;
          break;
        }
      } catch {
        // zona con formato inesperado, ignorar y continuar
      }
    }

    if (!zonaDestino) {
      return jsonError('La dirección de entrega está fuera de la zona de cobertura', 400, req);
    }
  }

  // ── 7. Re-leer precios de productos desde la BD ───────────────────────────
  const productIds = [...new Set(items.map((i) => i.product_id))];

  const { data: products, error: productsError } = await supabaseAdmin
    .from('products')
    .select(
      `id, price, is_available, section_id,
       menu_sections!inner(merchant_id)`,
    )
    .in('id', productIds);

  if (productsError) return jsonError('Error al verificar productos', 400, req);

  // Mapa para acceso O(1)
  type DbProduct = {
    id: string;
    price: number;
    is_available: boolean;
    section_id: string;
    menu_sections: { merchant_id: string };
  };
  const productMap = new Map<string, DbProduct>(
    (products as unknown as DbProduct[]).map((p) => [p.id, p]),
  );

  // ── 8. Re-leer precios de opciones desde la BD ────────────────────────────
  const allOptionIds = items.flatMap((i) => i.opciones ?? []);
  const uniqueOptionIds = [...new Set(allOptionIds)];

  type DbOption = { id: string; product_id: string; name: string; price_modifier: number };
  let optionMap = new Map<string, DbOption>();

  if (uniqueOptionIds.length > 0) {
    const { data: options, error: optionsError } = await supabaseAdmin
      .from('product_options')
      .select('id, product_id, name, price_modifier')
      .in('id', uniqueOptionIds);

    if (optionsError) return jsonError('Error al verificar opciones de productos', 400, req);
    optionMap = new Map<string, DbOption>(
      (options as DbOption[]).map((o) => [o.id, o]),
    );
  }

  // ── 9. Validar items y calcular subtotal ──────────────────────────────────
  type ItemCalculado = {
    product_id: string;
    quantity: number;
    unit_price: number;
    total_price: number;
    notes: string | null;
  };

  const itemsCalculados: ItemCalculado[] = [];
  let subtotal = 0;

  for (const item of items) {
    if (
      !item.product_id ||
      typeof item.cantidad !== 'number' ||
      !Number.isInteger(item.cantidad) ||
      item.cantidad < 1 ||
      item.cantidad > 50
    ) {
      return jsonError(`Item inválido: product_id=${item.product_id}`, 400, req);
    }

    if (item.nota !== undefined && item.nota !== null) {
      if (typeof item.nota !== 'string' || item.nota.length > 200) {
        return jsonError('La nota del producto no puede superar los 200 caracteres', 400, req);
      }
    }

    const producto = productMap.get(item.product_id);
    if (!producto) return jsonError(`Producto no encontrado: ${item.product_id}`, 404, req);
    if (!producto.is_available) return jsonError(`El producto no está disponible: ${item.product_id}`, 400, req);

    // Verificar que el producto pertenece al merchant
    if (producto.menu_sections.merchant_id !== merchant_id) {
      return jsonError(`El producto ${item.product_id} no pertenece a este local`, 400, req);
    }

    // Deduplicar opciones para evitar duplicación de modificadores de precio
    const opcionesUnicas = [...new Set(item.opciones ?? [])];
    if (opcionesUnicas.length > 20) {
      return jsonError('Demasiadas opciones seleccionadas para un mismo producto', 400, req);
    }

    // Precio base del producto (desde BD, NO del cliente)
    let precioUnitario = producto.price;

    // Sumar modificadores de opciones (re-leídos desde BD)
    for (const optId of opcionesUnicas) {
      const opt = optionMap.get(optId);
      if (!opt) return jsonError(`Opción no encontrada: ${optId}`, 404, req);
      if (opt.product_id !== item.product_id) {
        return jsonError(`La opción ${optId} no corresponde al producto ${item.product_id}`, 400, req);
      }
      precioUnitario += opt.price_modifier;
    }

    const totalItem = precioUnitario * item.cantidad;
    subtotal += totalItem;

    itemsCalculados.push({
      product_id: item.product_id,
      quantity: item.cantidad,
      unit_price: precioUnitario,
      total_price: totalItem,
      notes: item.nota ?? null,
    });
  }

  // ── 10. Calcular envío según distancia y zonas ─────────────────────────────
  let envio = merchant.costo_envio_base ?? 0;

  try {
    const { data: settings } = await supabaseAdmin
      .from('delivery_settings')
      .select('*')
      .eq('id', 'default')
      .maybeSingle();

    if (
      settings &&
      merchant.lat !== null &&
      merchant.lng !== null &&
      address.lat !== null &&
      address.lng !== null
    ) {
      const mLat = Number(merchant.lat);
      const mLng = Number(merchant.lng);
      const aLat = Number(address.lat);
      const aLng = Number(address.lng);

      const routeFactor = Number(settings.route_factor) || 1.3;
      const straightDist = haversineDistanceKm(mLat, mLng, aLat, aLng);
      const distanceKm = Math.round(straightDist * routeFactor * 100) / 100;

      const maxDistance = Number(settings.max_distance_km) || 18.0;
      if (distanceKm > maxDistance) {
        return jsonError(
          `La dirección se encuentra a ${distanceKm.toFixed(1)} km, superando el radio máximo de entrega (${maxDistance} km)`,
          400,
          req,
        );
      }

      const baseFee = Number(settings.base_fee_centavos) || 120000;
      const baseIncludedKm = Number(settings.base_included_km) || 2.0;
      const pricePerKm = Number(settings.price_per_km_centavos) || 35000;
      const extraKm = Math.max(0, distanceKm - baseIncludedKm);
      const distanceFee = Math.round(extraKm * pricePerKm);

      let zoneSurcharge = 0;
      if (zonaDestino) {
        const geojson = zonaDestino.polygon_geojson as {
          properties?: { costo_envio_centavos?: number };
        };
        zoneSurcharge =
          Number(zonaDestino.costo_adicional_centavos) ||
          Number(geojson?.properties?.costo_envio_centavos) ||
          0;
      }

      const subtotalEnvio = baseFee + distanceFee + zoneSurcharge;
      const step = Number(settings.rounding_step_centavos) || 5000;
      let totalEnvio = Math.round(subtotalEnvio / step) * step;

      const minFee = Number(settings.min_fee_centavos) || 100000;
      const maxFee = Number(settings.max_fee_centavos) || 600000;
      if (totalEnvio < minFee) totalEnvio = minFee;
      if (totalEnvio > maxFee) totalEnvio = maxFee;

      envio = totalEnvio;
    }
  } catch (err) {
    console.error('Error calculando tarifas dinámicas en crear-pedido, usando base:', err);
  }

  // ── 11. Validar y calcular descuento por cupón ────────────────────────────
  let descuento = 0;
  let couponId: string | null = null;

  if (codigo_cupon) {
    if (typeof codigo_cupon !== 'string' || codigo_cupon.trim().length > 50) {
      return jsonError('Cupón inválido o no encontrado', 400, req);
    }

    const { data: cupon, error: cuponError } = await supabaseAdmin
      .from('coupons')
      .select('*')
      .eq('codigo', codigo_cupon.toUpperCase().trim())
      .single();

    if (cuponError || !cupon) return jsonError('Cupón inválido o no encontrado', 400, req);
    if (cupon.activo === false) return jsonError('Cupón inválido o no encontrado', 400, req);

    const ahora = new Date();

    // Vigencia
    if (cupon.vigencia_desde && new Date(cupon.vigencia_desde) > ahora) {
      return jsonError('El cupón aún no está vigente', 400, req);
    }
    if (cupon.vigencia_hasta && new Date(cupon.vigencia_hasta) < ahora) {
      return jsonError('El cupón está vencido', 400, req);
    }

    if (
      typeof cupon.monto_minimo_centavos === 'number' &&
      cupon.monto_minimo_centavos > 0 &&
      subtotal < cupon.monto_minimo_centavos
    ) {
      return jsonError('El pedido no alcanza el monto mínimo para este cupón', 400, req);
    }

    // Solo primer pedido
    if (cupon.solo_primer_pedido) {
      const { count } = await supabaseAdmin
        .from('orders')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', user.id)
        .neq('estado', 'cancelado')
        .neq('estado', 'rechazado');

      if ((count ?? 0) > 0) {
        return jsonError('Este cupón es solo para el primer pedido', 400, req);
      }
    }

    // Calcular descuento
    const descuentoBruto = Math.floor((subtotal * cupon.porcentaje) / 100);
    descuento =
      cupon.tope_centavos !== null
        ? Math.min(descuentoBruto, cupon.tope_centavos)
        : descuentoBruto;

    couponId = cupon.id;
  }

  // ── 12. Total final ───────────────────────────────────────────────────────
  const propinaValidada = Math.max(0, Math.floor(propina));
  const total = subtotal + envio + propinaValidada - descuento;

  if (total < 0) return jsonError('El total no puede ser negativo');

  // Si paga con ClinPay, validar saldo suficiente antes de crear la orden
  let currentClinpayBalance = 0;
  if (metodo_pago === 'clinpay') {
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('wallet_balance')
      .eq('id', user.id)
      .single();

    if (profileError || !profile) {
      return jsonError('No se pudo verificar el saldo de ClinPay', 400, req);
    }

    currentClinpayBalance = Number(profile.wallet_balance) || 0;
    if (currentClinpayBalance < total) {
      return jsonError('Saldo insuficiente en ClinPay', 400, req);
    }
  }

  // ── 13. Insertar order + order_items en una transacción ───────────────────
  // Supabase no expone transacciones vía client; usamos una función RPC para
  // garantizar atomicidad. Alternativa: insertar sequencialmente con rollback
  // manual en caso de error (ambos con service_role que bypasa RLS).

  const { data: order, error: orderError } = await supabaseAdmin
    .from('orders')
    .insert({
      user_id: user.id,
      merchant_id,
      address_id,
      coupon_id: couponId,
      // Efectivo: confirmado directamente. MP: queda en espera de pago.
      estado: metodo_pago === 'mercado_pago' ? 'pago_pendiente' : 'confirmado',
      subtotal,
      envio,
      propina: propinaValidada,
      descuento,
      total,
      vuelto_para: metodo_pago === 'efectivo' && vuelto_para ? Math.floor(vuelto_para) : null,
      special_instructions: special_instructions ? String(special_instructions).slice(0, 500) : null,
    })
    .select()
    .single();

  if (orderError || !order) {
    console.error('Error al crear pedido:', orderError);
    return jsonError('Error al crear el pedido', 500);
  }

  const { data: itemsCreados, error: itemsError } = await supabaseAdmin
    .from('order_items')
    .insert(itemsCalculados.map((i) => ({ ...i, order_id: order.id })))
    .select('id, product_id, quantity, unit_price, total_price, notes');

  if (itemsError) {
    // Rollback manual: eliminar la order recién creada
    await supabaseAdmin.from('orders').delete().eq('id', order.id);
    console.error('Error al insertar items:', itemsError);
    return jsonError('Error al guardar los productos del pedido', 500);
  }

  // ── 13b. Guardar las opciones elegidas en cada ítem ──────────────────────
  // Se copia nombre y modificador para que el pedido histórico no cambie si
  // el menú cambia después. Se relaciona cada fila devuelta con su item de
  // entrada a partir de la firma de valores (el carrito fusiona duplicados).

  type DatosItem = {
    product_id: string;
    quantity: number;
    unit_price: number;
    total_price: number;
    notes: string | null;
  };

  type FilaItem = DatosItem & { id: string };

  const firmaDe = (fila: DatosItem) =>
    [fila.product_id, fila.quantity, fila.unit_price, fila.total_price, fila.notes ?? ''].join('|');

  const indicesPendientes = new Map<string, number[]>();
  itemsCalculados.forEach((itemCalculado, indice) => {
    const firma = firmaDe(itemCalculado);
    indicesPendientes.set(firma, [...(indicesPendientes.get(firma) ?? []), indice]);
  });

  type OpcionDeItem = {
    order_item_id: string;
    option_id: string;
    name: string;
    price_modifier: number;
  };

  const opcionesDeItems: OpcionDeItem[] = [];

  for (const fila of (itemsCreados ?? []) as FilaItem[]) {
    const indice = indicesPendientes.get(firmaDe(fila))?.shift();
    if (indice === undefined) continue;

    for (const optionId of [...new Set(items[indice].opciones ?? [])]) {
      const opcion = optionMap.get(optionId);
      if (!opcion) continue;
      opcionesDeItems.push({
        order_item_id: fila.id,
        option_id: opcion.id,
        name: opcion.name,
        price_modifier: opcion.price_modifier,
      });
    }
  }

  if (opcionesDeItems.length > 0) {
    const { error: opcionesError } = await supabaseAdmin
      .from('order_item_options')
      .insert(opcionesDeItems);

    if (opcionesError) {
      // Rollback manual: borra la order y, en cascada, items y opciones
      await supabaseAdmin.from('orders').delete().eq('id', order.id);
      console.error('Error al insertar opciones:', opcionesError);
      return jsonError('Error al guardar las opciones del pedido', 500);
    }
  }

  // ── 14. Registrar redención de cupón ─────────────────────────────────────
  if (couponId && descuento > 0) {
    await supabaseAdmin.from('coupon_redemptions').insert({
      coupon_id: couponId,
      order_id: order.id,
      user_id: user.id,
      amount_saved: descuento,
    });
  }

  // ── 14b. Debitar saldo ClinPay si corresponde ─────────────────────────────
  if (metodo_pago === 'clinpay') {
    const nuevoSaldo = currentClinpayBalance - total;
    const { error: debitError } = await supabaseAdmin
      .from('profiles')
      .update({ wallet_balance: nuevoSaldo })
      .eq('id', user.id);

    if (debitError) {
      // Rollback manual: eliminar la order
      await supabaseAdmin.from('orders').delete().eq('id', order.id);
      console.error('Error al debitar saldo ClinPay:', debitError);
      return jsonError('Error al procesar el pago con ClinPay', 500, req);
    }
  }

  // ── 15. Insertar registro de pago ─────────────────────────────────────────
  await supabaseAdmin.from('payments').insert({
    order_id: order.id,
    method: metodo_pago,
    amount: total,
    status: (metodo_pago === 'efectivo' || metodo_pago === 'clinpay') ? 'confirmado' : 'iniciado',
  });

  // ── 16. Respuesta ─────────────────────────────────────────────────────────
  return jsonOk({
    pedido: {
      id: order.id,
      estado: order.estado,
      subtotal,
      envio,
      propina: propinaValidada,
      descuento,
      total,
      metodo_pago,
      vuelto_para: order.vuelto_para ?? null,
      created_at: order.created_at,
    },
  });
});
