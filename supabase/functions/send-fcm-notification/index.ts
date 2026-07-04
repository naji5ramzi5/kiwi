import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'https://esm.sh/google-auth-library@8.7.0'

const fcmProjectId = Deno.env.get('FCM_PROJECT_ID') ?? ''
const fcmClientEmail = Deno.env.get('FCM_CLIENT_EMAIL') ?? ''
const fcmPrivateKey = (Deno.env.get('FCM_PRIVATE_KEY') ?? '').replace(/\\n/g, '\n')
const fcmApiUrl = `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
)

interface FCMNotificationRequest {
  userId: string
  title: string
  body: string
  data?: Record<string, string>
}

async function getAccessToken() {
  if (!fcmProjectId || !fcmClientEmail || !fcmPrivateKey) {
    throw new Error('Missing FCM secrets: FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY')
  }

  const client = new JWT({
    email: fcmClientEmail,
    key: fcmPrivateKey,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })

  const { token } = await client.getAccessToken()
  if (!token) throw new Error('Failed to create FCM access token')
  return token
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
    const { userId, title, body, data } = (await req.json()) as FCMNotificationRequest
    if (!userId || !title || !body) {
      return new Response(JSON.stringify({ error: 'Missing required fields: userId, title, body' }), { status: 400, headers })
    }

    const { data: tokensRecord, error: tokensErr } = await supabase
      .from('user_fcm_tokens')
      .select('token, device_type')
      .eq('user_id', userId)

    const { data: profileRecord, error: profileErr } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', userId)
      .maybeSingle()

    if (tokensErr) throw tokensErr
    if (profileErr) throw profileErr

    const tokens: { token: string; device_type: string }[] = []
    if (tokensRecord) {
      tokens.push(...tokensRecord)
    }
    if (profileRecord?.fcm_token) {
      if (!tokens.some(t => t.token === profileRecord.fcm_token)) {
        tokens.push({ token: profileRecord.fcm_token, device_type: 'android' })
      }
    }

    if (!tokens.length) {
      return new Response(JSON.stringify({ error: 'No FCM tokens found for user' }), { status: 404, headers })
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
    return new Response(JSON.stringify({ successful, total: results.length, results }), { headers })
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      status: 500,
      headers,
    })
  }
})
