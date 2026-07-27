import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
)

const FCM_PROJECT_ID = Deno.env.get('FCM_PROJECT_ID') ?? 'fresh-enterprise'
const FCM_CLIENT_EMAIL = Deno.env.get('FCM_CLIENT_EMAIL') ?? 'firebase-adminsdk-fbsvc@fresh-enterprise.iam.gserviceaccount.com'
const FCM_PRIVATE_KEY_B64 = Deno.env.get('FCM_PRIVATE_KEY_B64') ?? ''

interface FCMNotificationRequest {
  userId?: string
  broadcast?: boolean
  title: string
  body: string
  data?: Record<string, string>
}

async function getAccessToken(): Promise<string> {
  if (!FCM_PRIVATE_KEY_B64) throw new Error('FCM_PRIVATE_KEY_B64 secret is missing')

  const derBytes = Uint8Array.from(atob(FCM_PRIVATE_KEY_B64), c => c.charCodeAt(0))

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
