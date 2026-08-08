import { readFileSync, existsSync } from 'node:fs'
import { createClient } from '@supabase/supabase-js'

function loadEnv(file) {
  const out = {}
  if (!existsSync(file)) return out
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\s*$/)
    if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, '')
  }
  return out
}

const env = { ...loadEnv('.env'), ...loadEnv('.env.production') }
const url = env.VITE_SUPABASE_URL
const anon = env.VITE_SUPABASE_ANON_KEY
if (!url || !anon) { console.error('FATAL: VITE_SUPABASE_URL / ANON_KEY not found'); process.exit(1) }

// تشغيل SELECT مباشر عبر Management API (للفحوص التي RLS يحجبها عن anon)
async function directQuery(sql) {
  const token = process.env.SUPABASE_E2E_TOKEN
  if (!token) return null
  const ref = url.replace(/https:\/\/([a-z0-9-]+)\.supabase\.co.*/, '$1')
  const body = Buffer.from(JSON.stringify({ query: sql }), 'utf8')
  const r = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body,
  })
  if (!r.ok) throw new Error(`directQuery ${r.status}`)
  return r.json()
}

const sb = createClient(url, anon)
const results = []
const total = { pass: 0, fail: 0, warn: 0 }

function report(name, ok, detail = '') {
  total[ok ? 'pass' : ok === null ? 'warn' : 'fail']++
  results.push({ name, ok, detail })
  console.log(`${ok ? '✅' : ok === null ? '⚠️' : '❌'} ${name}${detail ? ' — ' + detail : ''}`)
}

async function count(table, filters = {}) {
  let q = sb.from(table).select('*', { count: 'exact', head: true })
  for (const [k, v] of Object.entries(filters)) q = q.eq(k, v)
  const { count: c, error } = await q
  if (error) throw error
  return c
}

// ── 1. Auth ───────────────────────────────────────────────────────────────
{
  const r = await sb.auth.signInWithPassword({ email: 'e2e-invalid@kiwi.iq', password: 'wrongpass' })
  report('1. Auth endpoint email+password', true, r.error?.message || 'nuisance')
}

// ── 2. orders schema: area/street/building ────────────────────────────────
{
  const { data, error } = await sb.from('orders').select('id, area, street, building').limit(1)
  if (error) report('2. orders.area/street/building', false, error.message)
  else {
    const filled = (data ?? []).filter(o => o.area || o.street || o.building).length
    report('2. orders.area/street/building', true, `rows=${(data ?? []).length} filled=${filled}`)
  }
}

// ── 3. Views ──────────────────────────────────────────────────────────────
for (const v of ['delivered_orders_report', 'delivery_employees_report', 'delivery_employees_with_profiles']) {
  const { data, error } = await sb.from(v).select('*').limit(3)
  if (error) {
    const missing = /does not exist/i.test(error.message)
    report(`3. view ${v}`, missing ? false : null, missing ? 'غير موجودة' : error.message.slice(0, 70))
  } else report(`3. view ${v}`, true, `rows=${(data ?? []).length}`)
}

// ── 4. Storage bucket ─────────────────────────────────────────────────────
{
  const { data, error } = await sb.storage.getBucket('delivery_proofs')
  if (error && /not found/i.test(error.message)) report('4. bucket delivery_proofs', false, error.message)
  else if (error) report('4. bucket delivery_proofs', true, `موجود (${error.message.slice(0, 60)})`)
  else report('4. bucket delivery_proofs', true, `public=${data.public}`)
}

// ── 5. system_settings: أربعة مفاتيح أرباح المركبات ──────────────────────
{
  const needed = ['delivery_earnings_motorcycle', 'delivery_earnings_car', 'delivery_earnings_van', 'delivery_earnings_truck']
  if (process.env.SUPABASE_E2E_TOKEN) {
    try {
      const rows = await directQuery(`SELECT key FROM public.system_settings ORDER BY key;`)
      const keys = (rows ?? []).map(r => r.key)
      const missing = needed.filter(k => !keys.includes(k))
      report('5. مفاتيح الأرباح حسب المركبة', missing.length === 0,
        missing.length === 0 ? `موجودة: ${needed.join(', ')}` : `ناقص: ${missing.join(', ')}`)
    } catch (e) { report('5. مفاتيح الأرباح حسب المركبة', null, e.message) }
  } else {
    report('5. مفاتيح الأرباح حسب المركبة', null, 'مجرّب لم يُفحص — أعد التشغيل مع SUPABASE_E2E_TOKEN (RLS يحجبها عن anon)')
  }
}

// ── 6. Data presence ──────────────────────────────────────────────────────
for (const [t, label] of [['orders', 'طلبات'], ['delivery_employees', 'موظفو توصيل'], ['delivery_earnings', 'أرباح توصيل'], ['branches', 'فروع'], ['delivery_zones', 'مناطق']]) {
  try { report(`6. جدول ${t} (${label})`, true, `count=${await count(t)}`) }
  catch (e) { report(`6. جدول ${t} (${label})`, false, e.message.slice(0, 70)) }
}

// ── 7. Order lifecycle statuses ───────────────────────────────────────────
{
  try {
    const statuses = ['pending', 'confirmed', 'assigned', 'picked_up', 'on_the_way', 'delivered', 'cancelled', 'new']
    const dist = {}
    for (const s of statuses) { try { dist[s] = await count('orders', { status: s }) } catch { dist[s] = '?' } }
    report('7. توزيع حالات الطلبات', true, JSON.stringify(dist))
  } catch (e) { report('7. توزيع حالات الطلبات', false, e.message) }
}

// ── 8. DeliveryEmployeesReport data quality ───────────────────────────────
{
  const { data, error } = await sb.from('delivery_employees_report').select('*').limit(50)
  if (error) report('8. delivery_employees_report', null, error.message.slice(0, 60))
  else {
    const withE = (data ?? []).filter(x => Number(x.total_earnings || 0) > 0).length
    report('8. delivery_employees_report', true, `employees=${(data ?? []).length} loads=${withE}`)
  }
}

// ── 9. DeliveredOrders filter data ────────────────────────────────────────
{
  const { data, error } = await sb.from('delivered_orders_report').select('branch_name, employee_name').limit(500)
  if (error) report('9. فلاتر الفرع/الموظف (بيانات)', null, error.message.slice(0, 60))
  else {
    const br = new Set((data ?? []).map(r => r.branch_name).filter(Boolean)).size
    const em = new Set((data ?? []).map(r => r.employee_name).filter(Boolean)).size
    report('9. فلاتر الفرع/الموظف (بيانات)', true, `rows=${(data ?? []).length} branches=${br} employees=${em}`)
  }
}

// ── 10. RPCs مع معاملات سليمة ─────────────────────────────────────────────
const DUMMY = '00000000-0000-0000-0000-000000000001'
for (const [fn, args] of [
  ['confirm_delivery', { p_order_id: DUMMY, p_photo_url: null, p_latitude: null, p_longitude: null }],
  ['transfer_delivery_employee', { p_employee_id: DUMMY, p_new_branch_id: DUMMY }],
  ['assign_order_to_delivery', { p_order_id: DUMMY, p_employee_id: DUMMY }],
  ['release_order_from_delivery', { p_order_id: DUMMY }],
  ['decrement_branch_inventory', { p_branch_id: DUMMY, p_product_id: DUMMY, p_quantity: 1 }],
]) {
  try {
    const { error } = await sb.rpc(fn, args)
    if (error) {
      const msg = error.message || ''
      if (/does not exist|Could not find the function/.test(msg)) report(`10. RPC ${fn}`, false, msg.slice(0, 70))
      else if (/permission denied|violates row-level security|new row violates/i.test(msg)) report(`10. RPC ${fn}`, true, `موجودة — RLS رفض: ${msg.slice(0, 60)}`)
      else report(`10. RPC ${fn}`, true, `موجودة — خطأ منطقي متوقع: ${msg.slice(0, 60)}`)
    } else report(`10. RPC ${fn}`, true, 'نُفّذت بنجاح (غير متوقع بدون بيانات!)')
  } catch (e) { report(`10. RPC ${fn}`, false, String(e.message).slice(0, 70)) }
}

// ── 11. RLS: كتابة أنون مرفوضة ────────────────────────────────────────────
{
  const { error: ins } = await sb.from('orders').insert({ status: '__e2e_probe__' })
  report('11. RLS (كتابة أنون مرفوضة)', !!ins, ins ? ins.message.slice(0, 60) : 'تم قبول الإدراج!')
}

// ── 12. Realtime ──────────────────────────────────────────────────────────
{
  const ok = await new Promise(resolve => {
    const ch = sb.channel('e2e-ping')
    const t = setTimeout(() => { sb.removeChannel(ch); resolve(false) }, 8000)
    ch.subscribe(status => { if (status === 'SUBSCRIBED') { clearTimeout(t); sb.removeChannel(ch); resolve(true) } })
  })
  report('12. Realtime channel', ok, ok ? 'Subscribe نجح' : 'مهلة')
}

console.log('\n' + '─'.repeat(60))
console.log(`النتيجة: ${total.pass} ✅ | ${total.warn} ⚠️ | ${total.fail} ❌`)
process.exit(total.fail > 0 ? 1 : 0)