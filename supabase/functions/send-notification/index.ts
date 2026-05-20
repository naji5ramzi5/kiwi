import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { JWT } from "https://esm.sh/google-auth-library@8.7.0"

const FIREBASE_SERVICE_ACCOUNT = {
  "type": "service_account",
  "project_id": "fresh-enterprise",
  "private_key_id": "c4e2ef703a00c54a0cd56fba174082648e6ef46d",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDGZlwuQd9pwfs3\nh3nmM96DdEaJrUobf/zKViDZ+GuH60FLziJ5DcPZblA1qxX9cRedcvk53bRjfx4F\nAPH78n0pSifbJv+4HjhapbJaLVHKOR8eqI0YYd7ZQlHDtiziZm1OZIt1vEPGNt+L\n8qUYiM1e+cnQNOTgW25YHVi6+cdyMsK8MGYcZHYZWLAkW2PCgNkfHzx0Ba3izmj7\nhorzynLDw12xiynudKf1rJf3jRluBZqNWMYSyNHWH4G8Owl4NuntSBc+bUsV1QSV\n2FQsuti3vWJs8BN7ppc0N59QRNYMkLQW2IhkJV8mps5GRZ8jPgXEd+cbzbe/CcHR\nQAgzP3KzAgMBAAECggEAI/BDz29ISJCGcKseRjhsHLTR2DunOm8HPCG45rMMy3yu\ngcxPy0zWhsroRah9ncDALdm3UqeZ9xH+PprKusBUsseHi7e3R8NVovnz4kjmUXLi\nc7vFfz6vTvyn8gNMgyBZuYMWDhgx0LR87w1foZ+aUBOAXrJOKWP2i4iZW5lGayV7\nofCBrgbpMA+Zz5ToP3YYq01hM8WwDCJF9SgowP06kiltAy+XKRsp58YrSyNRaQbC\nwPOrQ7FsEFoN9cpW4ItiS2IDyAEKY4CsQDmOZ1XMmwAeUsH2xz39wdYKNe6QKOxE\n+qiM2IS9HGk7EdGhWfJWxk4jyymtr9Ftl0IHzJK+4QKBgQD7vS7DReLiZaLATXog\nSRnPxtRgvsARQ566L7GCjhxUPj/98DFdwGsCiXtuBz+fJn3t2YurFjxv2hYDBxfh\nKu7gZGBfsN8YvrxG0JzWUT6Gu8rB3vC4B0G26DUdBsWvUJKrjWHlkg9tVfUbGVPD\nDP59WkuS3a57YkC2Cdy0bgG0IQKBgQDJwg1SQyqdTznQ2P0QRdL7/O81x1ha4xXN\nwNIy83cpU9yPXeIplMYH/oD+Q7Mx95Doqv5t0VnlMnOxMVzOS5J7AspXy+bLsYZm\nnCVXpdnYftlFexGUCOl5iUR2Uc3FyCJvmBVWiR8Kur7B6eWu2q8BJl3AkGwuJtRA\nJ4eTVDCMUwKBgFnPe6B1DWXB5td+jKR6D/hdsiU1yGYgXr+EBmtSce7oKoJZL/OH\nk2XbUKrHcT5BSEoUA80s6LDq+FFqNW3CmGh7xxo8istUOO12vY2EfK8qzkJuXCj7\nhclQfKp3YQ2TzE/h59w0SMa0FPbvCUAcIartDOs/pWElg3queAvy9y6hAoGALt4d\nKhbgN1rIG3PMlZMix9ah2uRL6hEGZ517NsrHy5nnioZMm0wsFH9Sh75CSkEwMFxI\nbkpLj6qApZDJ9kIn7NthFbQQERFUH1H2er3UNS6CWlmUY8cONWVlufaWznMHTNUP\nX+LKizuGRJWI/W1faez3qlviRXZPp/eGzvqnrHECgYB1A6yeGzfBE9CBs94s4htn\n/KBWRESH3u3K2iG36J1WxIPoxDDLNlJSYTveUVAYhmu4yZxelOkz9EPU8YL2wY4y\nexAyq5YB6qipJzTbfBmJwbTduOYB5miIfvOD0MxjIyDIBogGtKpnBMvaJgSzJ1zL\nBQul1CGUwyhe//N0SavcQw==\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@fresh-enterprise.iam.gserviceaccount.com",
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

