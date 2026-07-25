import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const fcmProjectId = Deno.env.get('FCM_PROJECT_ID') ?? ''
const fcmClientEmail = Deno.env.get('FCM_CLIENT_EMAIL') ?? ''
const fcmPrivateKeyB64 = Deno.env.get('FCM_PRIVATE_KEY_B64') ?? ''
const fcmPrivateKeyRaw = (Deno.env.get('FCM_PRIVATE_KEY') ?? '')
const fcmApiUrl = `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
)

interface FCMNotificationRequest {
  userId?: string
  broadcast?: boolean
  title: string
  body: string
  data?: Record<string, string>
}

function pemToDer(pem: string): Uint8Array {
  let cleaned = pem
    .replace(/-----BEGIN [^-]+-----/g, '')
    .replace(/-----END [^-]+-----/g, '')
    .replace(/\s+/g, '')
    .replace(/\n/g, '')
    .replace(/\r/g, '')
    .replace(/\\n/g, '')
  return Uint8Array.from(atob(cleaned), c => c.charCodeAt(0))
}

function derToPem(der: Uint8Array): string {
  const b64 = btoa(String.fromCharCode(...der))
  const lines = b64.match(/.{1,64}/g) || []
  return '-----BEGIN PRIVATE KEY-----\n' + lines.join('\n') + '\n-----END PRIVATE KEY-----'
}

async function getPrivateKeyPem(): Promise<string> {
  if (fcmPrivateKeyB64) {
    const der = Uint8Array.from(atob(fcmPrivateKeyB64), c => c.charCodeAt(0))
    return derToPem(der)
  }

  let pem = fcmPrivateKeyRaw
  if (pem && !pem.includes('-----BEGIN')) {
    try {
      const der = Uint8Array.from(atob(pem), c => c.charCodeAt(0))
      return derToPem(der)
    } catch {
      // not base64, try as raw
    }
  }

  if (pem) {
    pem = pem.replace(/\\n/g, '\n')
    if (!pem.includes('-----BEGIN')) {
      pem = '-----BEGIN PRIVATE KEY-----\n' + pem + '\n-----END PRIVATE KEY-----'
    }
  }

  return pem
}

async function getAccessToken(): Promise<string> {
  const pem = await getPrivateKeyPem()
  if (!fcmProjectId || !fcmClientEmail || !pem) {
    throw new Error(`Missing FCM secrets. Got project=${fcmProjectId}, email=${fcmClientEmail}, key_len=${pem.length}`)
  }

  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: fcmClientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const signingInput = `${headerB64}.${payloadB64}`

  const keyData = pemToDer(pem)
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    keyData.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, encoder.encode(signingInput))
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const jwt = `${signingInput}.${sigB64}`

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenRes.json()
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`)
  }
  return tokenData.access_token
}

async function sendMessage(accessToken: string, token: string, title: string, body: string, data?: Record<string, string>) {
  const response = await fetch(fcmApiUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data: data ?? {},
        android: { priority: 'high', notification: { sound: 'default' } },
        apns: { payload: { aps: { sound: 'default' } } },
      },
    }),
  })

  if (!response.ok) {
    return { success: false, status: response.status, error: await response.text() }
  }

  return { success: true, response: await response.json() }
}

serve(async (req) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  }

  if (req.method === 'OPTIONS') return new Response('ok', { headers })
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers })
  }

  try {
    const { userId, broadcast, title, body, data } = (await req.json()) as FCMNotificationRequest
    if (!title || !body) {
      return new Response(JSON.stringify({ error: 'Missing required fields: title, body' }), { status: 400, headers })
    }
    if (!userId && !broadcast) {
      return new Response(JSON.stringify({ error: 'Missing required field: userId or broadcast' }), { status: 400, headers })
    }

    const tokens: { token: string; device_type: string }[] = []

    if (broadcast) {
      const { data: allTokens, error: allErr } = await supabase
        .from('user_fcm_tokens')
        .select('token, device_type')
      if (allErr) throw allErr
      if (allTokens) tokens.push(...allTokens)

      const { data: profiles, error: profErr } = await supabase
        .from('profiles')
        .select('fcm_token')
        .not('fcm_token', 'is', null)
      if (profErr) throw profErr
      if (profiles) {
        for (const p of profiles) {
          if (p.fcm_token && !tokens.some(t => t.token === p.fcm_token)) {
            tokens.push({ token: p.fcm_token, device_type: 'android' })
          }
        }
      }
    } else {
      const { data: tokensRecord, error: tokensErr } = await supabase
        .from('user_fcm_tokens')
        .select('token, device_type')
        .eq('user_id', userId!)

      const { data: profileRecord, error: profileErr } = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('id', userId!)
        .maybeSingle()

      if (tokensErr) throw tokensErr
      if (profileErr) throw profileErr

      if (tokensRecord) tokens.push(...tokensRecord)
      if (profileRecord?.fcm_token) {
        if (!tokens.some(t => t.token === profileRecord.fcm_token)) {
          tokens.push({ token: profileRecord.fcm_token, device_type: 'android' })
        }
      }
    }

    if (!tokens.length) {
      return new Response(JSON.stringify({ error: 'No FCM tokens found', successful: 0, total: 0 }), { status: 200, headers })
    }

    const accessToken = await getAccessToken()
    const results = await Promise.all(
      tokens.map((record: { token: string; device_type: string }) =>
        sendMessage(accessToken, record.token, title, body, data).then(result => ({
          token: record.token,
          device_type: record.device_type,
          ...result,
        })),
      ),
    )

    const successful = results.filter(result => result.success).length
    return new Response(JSON.stringify({ successful, total: results.length, broadcast: !!broadcast, results }), { headers })
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      status: 500,
      headers,
    })
  }
})
