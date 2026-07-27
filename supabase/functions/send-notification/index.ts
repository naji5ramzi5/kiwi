import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
)

const FCM_PROJECT_ID = Deno.env.get('FCM_PROJECT_ID') ?? 'fresh-enterprise'
const FCM_CLIENT_EMAIL = Deno.env.get('FCM_CLIENT_EMAIL') ?? 'firebase-adminsdk-fbsvc@fresh-enterprise.iam.gserviceaccount.com'
const FCM_PRIVATE_KEY = Deno.env.get('FCM_PRIVATE_KEY') ?? `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCsobkCFjHr49ae
E7eygVZ9s20L45CVcBftpZnNX+UcD9VW6ALWVBozhSca3HISeVojGl/cHqJjjo2a
IHatwElTmss3i0e/kJX6RjnOsjHaV3KQCKMQQzbJq2UwSGj9oViRLrw0vjHFbr8K
EPeOvc1V4AgHkd+VAIIWf+NyvG5I7hUMTv/+P8GVinwEQKhmIOxMtrhG5W9Lt5qZ
cCE6fRStUlobu91OU6tBD4ZDLGHMwrblTPs9E/lPKj6MPgqqVoJVJJheL7lGJ/UM
cMcz3dmen4WrhnXxESK7DGTFrwuRKQg3tXKYapCg86uw0WnWEms0GQEHSUihCvGy
1ObaBjtDAgMBAAECggEAI/kFPN6UI4QULleMgWl7NPFlKUOP1twHWHGYJZg0fU79
VUE+ihv3Y8H83peOO7RG6Kav0AYgL5++eR4HrPgzL3VDoHzpBA2kewUUObKfOdDc
IhByrkpbSdXp3ZBRNHzhIEu9Uz5Iz8veikHz3C5H8fufoLgwf3OeKAMZScjjMFX4
ttyj8YD+ePV+A3GPgAwt/At7f3Q4B/ju3SWJhCKer2OA90utPiZr3QCn2tCQd1Kf
htkcebhV7yEbWYYfVwWYLDeBB0d2+SUXxbrEvcR1n9ExoQ0I/XW6vtL5FnKG8eua
PzMvK667rer0akuyJjl9xSUEZVyJCwp/knhyqOc/SQKBgQDSQ96J86Zes8FewgSs
YAp8PIwVAnSHB1az801S7InjuFPa4d8nQ7KrvSSjWyLrs6i1ha3f1MVgfyjXTdCD
iNTHxRb3Aqex0aEga3iPAhDGBsKOhQsv6Ahd24qFyh3iphFyyafkFOyohvV4LrBs
0DNVJ63CqoM4mO0WMdTH/atvKQKBgQDSLlMb60Hylkdd5RrCRDKv1OcdeLDDvzqU
HEERU4sBmvbvko31u62ysnGh/aIq4hwKxma+AENH8cZm2QYVIGIcTlsVLn68ZUHR
7GHyDpfNrRYtnHkUXmg/BMw1ZGsu48owbDLMH6xLnCkHXfKacOgOV2ycfJFOBatn
Wz8Q5eXgiwKBgDn+djbeeRjNw5v7L4bLxpiVqp1w2+sSXxurE7y3eSDSCm7otcAC
sBkmRiC4Vl1kZDgM8vQ1n2sKJ52a3NQqvWWMOtVOaiplg2eJvOrUywOTgb4FfBxu
h0A7+W0FXlDRNSbP7/q8urmQ38uSNR8OHdpy4z46AY9uvpXMkL/Ie6xhAoGBAMf/
noMHeWUCXU427Zn0ZHApI0ysuHzYFD57ES/5KuulqJjPOBxuf3Sc/ufVlPh0ET57J
MBb4dQ1OuXZAaRNNX06EGRPMzHhE+h7hikolLLpgS8xXKrgBJb1huVfNGFjkFQ+C
xcuLEA5aqIgEE8h2S7rp4cX+mt3dcz7EivxvZxEFAoGAK2+9WEoF5w3LZKdlMcVY
9M1HX0kI3el7FLsKcyuEFs9n3A+Zbt1KFKJ0XbflPfX1c3vY1SwL/Cz+EHV/BM6O
70ZWASri6B04j7RwcY6W3st1CGRGxOgajuUrrg3DeG+7GiLnBVgpz0d4rdMmQLKU
9KSnFN6o3Z7ZrN9dyzhdUFA=
-----END PRIVATE KEY-----`

interface FCMNotificationRequest {
  userId?: string
  broadcast?: boolean
  title: string
  body: string
  data?: Record<string, string>
}

function pemToDer(pem: string): Uint8Array {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\r?\n/g, '')
    .replace(/\s/g, '')
  return Uint8Array.from(atob(cleaned), c => c.charCodeAt(0))
}

async function getAccessToken(): Promise<string> {
  if (!FCM_PRIVATE_KEY) throw new Error('FCM_PRIVATE_KEY secret is missing')

  const derBytes = pemToDer(FCM_PRIVATE_KEY)

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    derBytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const now = Math.floor(Date.now() / 1000)
  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const payload = btoa(JSON.stringify({
    iss: FCM_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const signingInput = `${header}.${payload}`
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(signingInput))
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const jwt = `${signingInput}.${sigB64}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })
  const data = await res.json()
  if (!data.access_token) throw new Error(`Token exchange failed: ${JSON.stringify(data)}`)
  return data.access_token
}

async function sendFCMMessage(accessToken: string, token: string, title: string, body: string, data?: Record<string, string>) {
  const messagePayload: Record<string, unknown> = {
    token,
    notification: { title, body },
    data: data ?? {},
    android: { priority: 'high', notification: { sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
  }
  if (data?.image) {
    const androidNotif = messagePayload.android as Record<string, unknown>
    androidNotif.notification = {
      ...(androidNotif.notification as Record<string, unknown>),
      image: data.image,
    }
  }
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: messagePayload }),
  })
  if (!res.ok) return { success: false, error: await res.text() }
  return { success: true, response: await res.json() }
}

Deno.serve(async (req) => {
  const corsHeaders = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey, x-supabase-auth',
  }

  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: corsHeaders })
  }

  try {
    const { userId, broadcast, title, body, data } = (await req.json()) as FCMNotificationRequest
    if (!title || !body) {
      return new Response(JSON.stringify({ error: 'Missing title or body' }), { status: 400, headers: corsHeaders })
    }
    if (!userId && !broadcast) {
      return new Response(JSON.stringify({ error: 'Missing userId or broadcast' }), { status: 400, headers: corsHeaders })
    }

    const tokens: { token: string; device_type: string }[] = []

    if (broadcast) {
      const { data: allTokens } = await supabase.from('user_fcm_tokens').select('token, device_type')
      if (allTokens) tokens.push(...allTokens)
      const { data: profiles } = await supabase.from('profiles').select('fcm_token').not('fcm_token', 'is', null)
      if (profiles) {
        for (const p of profiles) {
          if (p.fcm_token && !tokens.some(t => t.token === p.fcm_token)) {
            tokens.push({ token: p.fcm_token, device_type: 'android' })
          }
        }
      }
    } else {
      const { data: userTokens } = await supabase.from('user_fcm_tokens').select('token, device_type').eq('user_id', userId!)
      if (userTokens) tokens.push(...userTokens)
      const { data: profile } = await supabase.from('profiles').select('fcm_token').eq('id', userId!).maybeSingle()
      if (profile?.fcm_token && !tokens.some(t => t.token === profile.fcm_token)) {
        tokens.push({ token: profile.fcm_token, device_type: 'android' })
      }
    }

    if (!tokens.length) {
      return new Response(JSON.stringify({ error: 'No FCM tokens found', successful: 0, total: 0 }), { status: 200, headers: corsHeaders })
    }

    const accessToken = await getAccessToken()
    const results = await Promise.all(
      tokens.map(r => sendFCMMessage(accessToken, r.token, title, body, data).then(res => ({ token: r.token, ...res })))
    )

    const successful = results.filter(r => r.success).length
    return new Response(JSON.stringify({ successful, total: results.length, broadcast: !!broadcast, results }), { headers: corsHeaders })
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), { status: 500, headers: corsHeaders })
  }
})
