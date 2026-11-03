#!/usr/bin/env node
/**
 * Script de verificación de políticas RLS por rol para Clin.
 *
 * Modos de uso:
 * 1) Solo lectura anónima (seguro, no requiere service_role ni escribe datos):
 *    node supabase/tests/rls-runner.mjs
 *
 * 2) Suite completa por rol (cliente, local, repartidor, admin) en un branch/staging:
 *    SUPABASE_URL=https://... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=... \
 *      node supabase/tests/rls-runner.mjs --with-writes
 */

import fs from 'node:fs';
import path from 'node:path';
import { createClient } from '@supabase/supabase-js';

function loadDotEnv(filePath) {
  if (!fs.existsSync(filePath)) return {};
  return Object.fromEntries(
    fs
      .readFileSync(filePath, 'utf8')
      .split(/\r?\n/)
      .filter((line) => line.includes('=') && !line.trim().startsWith('#'))
      .map((line) => [
        line.slice(0, line.indexOf('=')).trim(),
        line.slice(line.indexOf('=') + 1).trim(),
      ]),
  );
}

const envStaging = loadDotEnv(path.resolve(process.cwd(), '.env.staging'));
const envDefault = loadDotEnv(path.resolve(process.cwd(), '.env'));
const envLegacy = loadDotEnv(path.resolve(process.cwd(), 'apps/cliente/.env'));
const envFile = { ...envLegacy, ...envDefault, ...envStaging };
const SUPABASE_URL =
  process.env.SUPABASE_URL || envFile.SUPABASE_URL || envFile.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  envFile.SUPABASE_ANON_KEY ||
  envFile.VITE_SUPABASE_ANON_KEY;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const WITH_WRITES = process.argv.includes('--with-writes');

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    'Faltan SUPABASE_URL o SUPABASE_ANON_KEY (definilos en .env.staging, .env o variables de entorno).',
  );
  process.exit(1);
}

let passed = 0;
let failed = 0;

function report(name, ok, detail = '') {
  if (ok) {
    passed++;
    console.log(`  [OK]   ${name}${detail ? ` (${detail})` : ''}`);
  } else {
    failed++;
    console.error(`  [FAIL] ${name}${detail ? ` -> ${detail}` : ''}`);
  }
}

async function runAnonReadSuite() {
  console.log('\n=== 1. Pruebas con rol ANÓNIMO (solo lectura) ===');
  const anon = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false },
  });

  // C2: mp_access_token no debe existir ni ser legible en merchants
  const { error: mpColErr } = await anon.from('merchants').select('id, mp_access_token').limit(1);
  report(
    'C2: merchants.mp_access_token no está expuesto al público',
    Boolean(mpColErr),
    mpColErr ? 'columna oculta/eliminada' : 'EXPUESTO',
  );

  // C2b: merchant_secrets bloqueado para anon
  const { data: secretsData, error: secretsErr } = await anon
    .from('merchant_secrets')
    .select('merchant_id');
  report(
    'C2: tabla merchant_secrets inaccesible para anon',
    Boolean(secretsErr) || (secretsData ?? []).length === 0,
    secretsErr ? secretsErr.code : `filas=${(secretsData ?? []).length}`,
  );

  // C3: orders no debe devolver pedidos ajenos a usuarios anónimos
  const { data: anonOrders, error: anonOrdersErr } = await anon.from('orders').select('id');
  report(
    'C3: anon no puede listar pedidos en orders',
    !anonOrdersErr && (anonOrders ?? []).length === 0,
    `filas=${(anonOrders ?? []).length}`,
  );

  // Tablas privadas que deben devolver 0 filas para anon
  const privateTables = [
    'profiles',
    'addresses',
    'order_items',
    'order_item_options',
    'order_status_history',
    'payments',
    'coupon_redemptions',
    'favorites',
    'notifications',
    'push_subscriptions',
    'courier_locations',
    'chat_messages',
    'coupons',
  ];

  for (const table of privateTables) {
    const { data, error } = await anon.from(table).select('id').limit(5);
    const empty = !error && (data ?? []).length === 0;
    const denied = Boolean(error);
    report(
      `RLS anon SELECT bloqueado en ${table}`,
      empty || denied,
      error ? error.code : `filas=${(data ?? []).length}`,
    );
  }
}

async function runAuthenticatedRoleSuite() {
  console.log('\n=== 2. Pruebas autenticadas por ROL (--with-writes) ===');
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    console.log('  (Omitido: definí SUPABASE_SERVICE_ROLE_KEY y --with-writes para ejecutar en staging)');
    return;
  }

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const runId = Date.now();
  const password = `TestRls!${runId}`;
  const createdUserIds = [];
  let testMerchantId = null;
  let testOrderId = null;

  async function createRoleUser(role) {
    const email = `rls-${role}-${runId}@clin-test.local`;
    const { data, error } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (error || !data.user) throw new Error(`No se pudo crear usuario ${role}: ${error?.message}`);
    createdUserIds.push(data.user.id);

    await adminClient.from('profiles').upsert({
      id: data.user.id,
      email,
      nombre: `Test ${role}`,
      rol: role,
      plan: 'free',
    });

    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: false },
    });
    const { error: signInErr } = await userClient.auth.signInWithPassword({ email, password });
    if (signInErr) throw new Error(`Error login ${role}: ${signInErr.message}`);
    return { id: data.user.id, client: userClient };
  }

  try {
    const alice = await createRoleUser('cliente');
    const bob = await createRoleUser('cliente');
    const dueno = await createRoleUser('local');
    const courier = await createRoleUser('repartidor');

    // Crear comercio de prueba para dueno y pedido de prueba para bob
    const { data: merchant } = await adminClient
      .from('merchants')
      .insert({
        name: `Comercio RLS ${runId}`,
        estado: 'activo',
        owner_id: dueno.id,
        comision_porcentaje: 12,
        costo_envio_base: 100000,
      })
      .select('id')
      .single();
    testMerchantId = merchant?.id;

    const { data: order } = await adminClient
      .from('orders')
      .insert({
        user_id: bob.id,
        merchant_id: testMerchantId,
        estado: 'listo_para_retirar',
        subtotal: 500000,
        envio: 100000,
        total: 600000,
      })
      .select('id')
      .single();
    testOrderId = order?.id;

    // C4: Cliente intenta escalar su propio rol a 'admin' y su wallet_balance
    const { error: escError } = await alice.client
      .from('profiles')
      .update({ rol: 'admin', wallet_balance: 9999999 })
      .eq('id', alice.id);
    report('C4: cliente no puede cambiar su rol a admin ni wallet_balance', Boolean(escError));

    // C5: Cliente intenta insertar pedido directo en orders con total arbitrario
    const { error: directOrderErr } = await alice.client.from('orders').insert({
      user_id: alice.id,
      merchant_id: testMerchantId,
      estado: 'confirmado',
      total: 1,
    });
    report('C5: cliente no puede hacer INSERT directo en orders', Boolean(directOrderErr));

    // C3: Cliente (alice) no puede ver ni tomar el pedido disponible de bob
    const { data: aliceSeesBob } = await alice.client
      .from('orders')
      .select('id')
      .eq('id', testOrderId);
    report(
      'C3: cliente no ve pedidos en estado listo_para_retirar de otro usuario',
      (aliceSeesBob ?? []).length === 0,
    );

    const { error: aliceTakeErr } = await alice.client.rpc('tomar_pedido', {
      p_order_id: testOrderId,
    });
    report('C3: cliente no puede ejecutar tomar_pedido()', Boolean(aliceTakeErr));

    // A4: Local no puede modificar comision_porcentaje de su propio comercio
    const { error: comisionErr } = await dueno.client
      .from('merchants')
      .update({ comision_porcentaje: 0 })
      .eq('id', testMerchantId);
    report('A4: local no puede reducir su propia comision_porcentaje', Boolean(comisionErr));

    // A4: Local no puede hacer UPDATE directo en orders (debe usar panel_cambiar_estado)
    const { data: localDirectUpd } = await dueno.client
      .from('orders')
      .update({ total: 100, estado: 'entregado' })
      .eq('id', testOrderId)
      .select('id');
    report(
      'A4: local no puede hacer UPDATE directo sobre orders',
      (localDirectUpd ?? []).length === 0,
    );

    // Repartidor legítimo sí ve el pedido disponible, lo toma por RPC y avanza su estado
    const { data: courierSees } = await courier.client
      .from('orders')
      .select('id')
      .eq('id', testOrderId);
    report('Repartidor ve pedidos disponibles para retirar', (courierSees ?? []).length === 1);

    const { error: courierTakeErr } = await courier.client.rpc('tomar_pedido', {
      p_order_id: testOrderId,
    });
    report('Repartidor puede tomar pedido disponible vía RPC', !courierTakeErr);

    // Repartidor no puede saltar directo a 'entregado' sin pasar por 'en_camino'
    const { error: badJumpErr } = await courier.client.rpc('repartidor_cambiar_estado', {
      p_order_id: testOrderId,
      p_estado: 'entregado',
    });
    report(
      'Repartidor no puede saltar a entregado sin estar en_camino',
      Boolean(badJumpErr),
    );
  } finally {
    if (testOrderId) await adminClient.from('orders').delete().eq('id', testOrderId);
    if (testMerchantId) await adminClient.from('merchants').delete().eq('id', testMerchantId);
    for (const uid of createdUserIds) {
      await adminClient.auth.admin.deleteUser(uid);
    }
  }
}

await runAnonReadSuite();
if (WITH_WRITES) {
  await runAuthenticatedRoleSuite();
}

console.log(`\nResumen RLS: ${passed} pasaron, ${failed} fallaron.`);
process.exit(failed > 0 ? 1 : 0);
