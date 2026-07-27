import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')
const FCM_PROJECT_ID = 'fresh-enterprise'
const FCM_CLIENT_EMAIL = 'firebase-adminsdk-fbsvc@fresh-enterprise.iam.gserviceaccount.com'
const FCM_PRIVATE_KEY_B64 = 'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCsobkCFjHr49aeE7eygVZ9s20L45CVcBftpZnNX+UcD9VW6ALWVBozhSca3HISeVojGl/cHqJjjo2aIHatwElTmss3i0e/kJX6RjnOsjHaV3KQCKMQQzbJq2UwSGj9oViRLrw0vjHFbr8KEPeOvc1V4AgHkd+VAIIWf+NyvG5I7hUMTv/+P8GVinwEQKhmIOxMtrhG5W9Lt5qZcCE6fRStUlobu91OU6tBD4ZDLGHMwrblTPs9E/lPKj6MPgqqVoJVJJheL7lGJ/UMcMcz3dmen4WrhnXxESK7DGTFrwuRKQg3tXKYapCg86uw0WnWEms0GQEHSUihCvGy1ObaBjtDAgMBAAECggEAI/kFPN6UI4QULleMgWl7NPFlKUOP1twHWHGYJZg0fU79VUE+ihv3Y8H83peOO7RG6Kav0AYgL5++eR4HrPgzL3VDoHzpBA2kewUUObKfOdDcIhByrkpbSdXp3ZBRNHzhIEu9Uz5Iz8veikHz3C5H8fufoLgwf3OeKAMZScjjMFX4ttyj8YD+ePV+A3GPgAwt/At7f3Q4B/ju3SWJhCKer2OA90utPiZr3QCn2tCQd1KfhtkcebhV7yEbWYYfVwWYLDeBB0d2+SUXxbrEvcR1n9ExoQ0I/XW6vtL5FnKG8euaPzMvK667rer0akuyJjl9xSUEZVyJCwp/knhyqOc/SQKBgQDSQ96J86Zes8FewgSsYAp8PIwVAnSHB1az801S7InjuFPa4d8nQ7KrvSSjWyLrs6i1ha3f1MVgfyjXTdCDiNTHxRb3Aqex0aEga3iPAhDGBsKOhQsv6Ahd24qFyh3iphFyyafkFOyohvV4LrBs0DNVJ63CqoM4mO0WMdTH/atvKQKBgQDSLlMb60Hylkdd5RrCRDKv1OcdeLDDvzqUHEERU4sBmvbvko31u62ysnGh/aIq4hwKxma+AENH8cZm2QYVIGIcTlsVLn68ZUHR7GHyDpfNrRYtnHkUXmg/BMw1ZGsu48owbDLMH6xLnCkHXfKacOgOV2ycfJFOBatnWz8Q5eXgiwKBgDn+djbeeRjNw5v7L4bLxpiVqp1w2+sSXxurE7y3eSDSCm7otcACsBkmRiC4Vl1kZDgM8vQ1n2sKJ52a3NQqvWWMOtVOaiplg2eJvOrUywOTgb4FfBxuh0A7+W0FXlDRNSbP7/q8urmQ38uSNR8OHdpy4z46AY9uvpXMkL/Ie6xhAoGBAMf/oMHeWUCXU427Zn0ZHApI0ysuHzYFD57ES/5KuulqJjPOBxuf3Sc/ufVlPh0ET57JMBb4dQ1OuXZAaRNNX06EGRPMzHhE+h7hikolLLpgS8xXKrgBJb1huVfNGFjkFQ+CxcuLEA5aqIgEE8h2S7rp4cX+mt3dcz7EivxvZxEFAoGAK2+9WEoF5w3LZKdlMcVY9M1HX0kI3el7FLsKcyuEFs9n3A+Zbt1KFKJ0XbflPfX1c3vY1SwL/Cz+EHV/BM6O70ZWASri6B04j7RwcY6W3st1CGRGxOgajuUrrg3DeG+7GiLnBVgpz0d4rdMmQLKU9KSnFN6o3Z7ZrN9dyzhdUFA='

async function getAccessToken() {
  if (!FCM_PRIVATE_KEY_B64) throw new Error('FCM_PRIVATE_KEY_B64 is missing')
  const derBytes = Uint8Array.from(atob(FCM_PRIVATE_KEY_B64), c => c.charCodeAt(0))
  const privateKey = await crypto.subtle.importKey('pkcs8', derBytes.buffer, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'])
  const now = Math.floor(Date.now() / 1000)
  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const payload = btoa(JSON.stringify({ iss: FCM_CLIENT_EMAIL, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600 })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const signingInput = header + '.' + payload
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(signingInput))
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const jwt = signingInput + '.' + sigB64
  const res = await fetch('https://oauth2.googleapis.com/token', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwt })
  const data = await res.json()
  if (!data.access_token) throw new Error('Token exchange failed: ' + JSON.stringify(data))
  return data.access_token
}

serve(async (req) => {
  const h = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey, x-supabase-auth' }
  if (req.method === 'OPTIONS') return new Response('ok', { headers: h })
  if (req.method !== 'POST') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: h })
  try {
    const { userId, broadcast, title, body, data } = await req.json()
    if (!title || !body) return new Response(JSON.stringify({ error: 'Missing title or body' }), { status: 400, headers: h })
    if (!userId && !broadcast) return new Response(JSON.stringify({ error: 'Missing userId or broadcast' }), { status: 400, headers: h })
    const tokens = []
    if (broadcast) {
      const { data: allTokens } = await supabase.from('user_fcm_tokens').select('token, device_type')
      if (allTokens) tokens.push(...allTokens)
      const { data: profiles } = await supabase.from('profiles').select('fcm_token').not('fcm_token', 'is', null)
      if (profiles) for (const p of profiles) if (p.fcm_token && !tokens.some(t => t.token === p.fcm_token)) tokens.push({ token: p.fcm_token, device_type: 'android' })
    } else {
      const { data: ut } = await supabase.from('user_fcm_tokens').select('token, device_type').eq('user_id', userId)
      if (ut) tokens.push(...ut)
      const { data: pr } = await supabase.from('profiles').select('fcm_token').eq('id', userId).maybeSingle()
      if (pr?.fcm_token && !tokens.some(t => t.token === pr.fcm_token)) tokens.push({ token: pr.fcm_token, device_type: 'android' })
    }
    if (!tokens.length) return new Response(JSON.stringify({ error: 'No FCM tokens found', successful: 0, total: 0 }), { status: 200, headers: h })
    const accessToken = await getAccessToken()
    const fcmUrl = 'https://fcm.googleapis.com/v1/projects/' + FCM_PROJECT_ID + '/messages:send'
    const results = await Promise.all(tokens.map(async (r) => {
      const res = await fetch(fcmUrl, { method: 'POST', headers: { Authorization: 'Bearer ' + accessToken, 'Content-Type': 'application/json' }, body: JSON.stringify({ message: { token: r.token, notification: { title, body }, data: data || {}, android: { priority: 'high', notification: { sound: 'default' } }, apns: { payload: { aps: { sound: 'default' } } } } }) })
      if (!res.ok) return { token: r.token, success: false, error: await res.text() }
      return { token: r.token, success: true, response: await res.json() }
    }))
    const successful = results.filter(r => r.success).length
    return new Response(JSON.stringify({ successful, total: results.length, broadcast: !!broadcast, results }), { headers: h })
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), { status: 500, headers: h })
  }
})
