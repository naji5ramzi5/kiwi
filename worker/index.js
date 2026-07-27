// Kiwi FCM Worker — Cloudflare Worker
// يرسل إشعارات FCM مباشرة من Cloudflareبدون Edge Function

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders() });
    }
    if (request.method !== 'POST') {
      return jsonResp({ error: 'Method not allowed' }, 405);
    }

    try {
      const { userId, broadcast, title, body, data } = await request.json();
      if (!title || !body) return jsonResp({ error: 'Missing title or body' }, 400);
      if (!userId && !broadcast) return jsonResp({ error: 'Missing userId or broadcast' }, 400);

      // جلب التوكنات من Supabase
      const tokens = await getTokens(env, userId, broadcast);
      if (!tokens.length) {
        return jsonResp({ error: 'No FCM tokens found', successful: 0, total: 0 });
      }

      const accessToken = await getAccessToken(env);
      const results = await Promise.all(
        tokens.map(r => sendFCMMessage(accessToken, r.token, title, body, data).then(res => ({ token: r.token, ...res })))
      );

      const successful = results.filter(r => r.success).length;
      return jsonResp({ successful, total: results.length, broadcast: !!broadcast, results });
    } catch (error) {
      return jsonResp({ error: error.message || String(error) }, 500);
    }
  },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function corsHeaders() {
  return {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

function jsonResp(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders() });
}

// جلب توكنات FCM من Supabase
async function getTokens(env, userId, broadcast) {
  const tokens = [];

  if (broadcast) {
    // جلب كل التوكنات
    const res1 = await fetch(`${env.SUPABASE_URL}/rest/v1/user_fcm_tokens?select=token,device_type`, {
      headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}` },
    });
    if (res1.ok) {
      const data = await res1.json();
      tokens.push(...data);
    }

    // جلب توكنات من profiles
    const res2 = await fetch(`${env.SUPABASE_URL}/rest/v1/profiles?select=id,fcm_token&fcm_token=not.is.null`, {
      headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}` },
    });
    if (res2.ok) {
      const profiles = await res2.json();
      for (const p of profiles) {
        if (p.fcm_token && !tokens.some(t => t.token === p.fcm_token)) {
          tokens.push({ token: p.fcm_token, device_type: 'android' });
        }
      }
    }
  } else {
    // توكنات مستخدم محدد
    const res1 = await fetch(`${env.SUPABASE_URL}/rest/v1/user_fcm_tokens?select=token,device_type&user_id=eq.${userId}`, {
      headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}` },
    });
    if (res1.ok) {
      const data = await res1.json();
      tokens.push(...data);
    }

    const res2 = await fetch(`${env.SUPABASE_URL}/rest/v1/profiles?select=fcm_token&id=eq.${userId}`, {
      headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}` },
    });
    if (res2.ok) {
      const profiles = await res2.json();
      if (profiles[0]?.fcm_token && !tokens.some(t => t.token === profiles[0].fcm_token)) {
        tokens.push({ token: profiles[0].fcm_token, device_type: 'android' });
      }
    }
  }

  return tokens;
}

// توليد OAuth2 Access Token لـ FCM
async function getAccessToken(env) {
  const privateKeyB64 = env.FCM_PRIVATE_KEY_B64;
  if (!privateKeyB64) throw new Error('FCM_PRIVATE_KEY_B64 is missing');

  const derBytes = Uint8Array.from(atob(privateKeyB64), c => c.charCodeAt(0));

  const privateKey = await crypto.subtle.importKey(
    'pkcs8', derBytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  );

  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  const payload = btoa(JSON.stringify({
    iss: env.FCM_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now, exp: now + 3600,
  })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const signingInput = `${header}.${payload}`;
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(signingInput));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const jwt = `${signingInput}.${sigB64}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!data.access_token) throw new Error(`Token exchange failed: ${JSON.stringify(data)}`);
  return data.access_token;
}

// إرسال رسالة FCM
async function sendFCMMessage(accessToken, token, title, body, data) {
  const payload = {
    token,
    notification: { title, body },
    data: data || {},
    android: { priority: 'high', notification: { sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
  };
  if (data?.image) {
    payload.android.notification.image = data.image;
  }

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${'fresh-enterprise'}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: payload }),
  });
  if (!res.ok) return { success: false, error: await res.text() };
  return { success: true, response: await res.json() };
}
