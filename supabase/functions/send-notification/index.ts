import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { JWT } from "https://esm.sh/google-auth-library@8.7.0"

const FIREBASE_SERVICE_ACCOUNT = {
  project_id: Deno.env.get("FCM_PROJECT_ID") ?? "",
  client_email: Deno.env.get("FCM_CLIENT_EMAIL") ?? "",
  private_key: (Deno.env.get("FCM_PRIVATE_KEY") ?? "").replace(/\\n/g, "\n"),
}

serve(async (req) => {
  try {
    const { tokens, title, body } = await req.json()

    // 1. Get Access Token from Google
    const client = new JWT({
      email: FIREBASE_SERVICE_ACCOUNT.client_email,
      key: FIREBASE_SERVICE_ACCOUNT.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    const { token } = await client.getAccessToken()

    // 2. Send Notifications to all tokens
    const results = await Promise.all(tokens.map(async (deviceToken: string) => {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${FIREBASE_SERVICE_ACCOUNT.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            message: {
              token: deviceToken,
              notification: { title, body },
              data: { click_action: "FLUTTER_NOTIFICATION_CLICK" }
            },
          }),
        }
      )
      return response.json()
    }))

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
