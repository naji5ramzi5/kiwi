// Kiwi FCM Worker — Cloudflare Worker

export default {
  async fetch(request) {
    const corsHeaders = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: corsHeaders });
    }

    try {
      const body = await request.json();
      const { userId, broadcast, title, body: notifBody, data } = body;
      if (!title || !notifBody) return new Response(JSON.stringify({ error: 'Missing title or body' }), { status: 400, headers: corsHeaders });
      if (!userId && !broadcast) return new Response(JSON.stringify({ error: 'Missing userId or broadcast' }), { status: 400, headers: corsHeaders });

      const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
      const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODYwODQ2OCwiZXhwIjoyMDk0MTg0NDY4fQ.kEetvZsaf7xdDrwnCCMtXOd7aky92BnBayl_VUNtnQQ';
      const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';
      const tokens = await getTokens(supabaseUrl, anonKey, serviceKey, userId, broadcast);

      if (!tokens.length) {
        return new Response(JSON.stringify({ error: 'No FCM tokens found', successful: 0, total: 0 }), { status: 200, headers: corsHeaders });
      }

      const accessToken = await getAccessToken();
      const results = await Promise.all(
        tokens.map(r => sendFCMMessage(accessToken, r.token, title, notifBody, data).then(res => ({ token: r.token, ...res })))
      );

      const successful = results.filter(r => r.success).length;
      return new Response(JSON.stringify({ successful, total: results.length, broadcast: !!broadcast, results }), { headers: corsHeaders });
    } catch (error) {
      return new Response(JSON.stringify({ error: error.message || String(error) }), { status: 500, headers: corsHeaders });
    }
  },
};

async function getTokens(supabaseUrl, anonKey, serviceKey, userId, broadcast) {
  const tokens = [];
  const headers = { apikey: anonKey, Authorization: 'Bearer ' + serviceKey };

  if (broadcast) {
    const res1 = await fetch(supabaseUrl + '/rest/v1/user_fcm_tokens?select=token,device_type', { headers });
    if (res1.ok) { const data = await res1.json(); tokens.push(...data); }

    const res2 = await fetch(supabaseUrl + '/rest/v1/profiles?select=id,fcm_token&fcm_token=not.is.null', { headers });
    if (res2.ok) {
      const profiles = await res2.json();
      for (const p of profiles) {
        if (p.fcm_token && !tokens.some(t => t.token === p.fcm_token)) {
          tokens.push({ token: p.fcm_token, device_type: 'android' });
        }
      }
    }
  } else {
    const res1 = await fetch(supabaseUrl + '/rest/v1/user_fcm_tokens?select=token,device_type&user_id=eq.' + userId, { headers });
    if (res1.ok) { const data = await res1.json(); tokens.push(...data); }

    const res2 = await fetch(supabaseUrl + '/rest/v1/profiles?select=fcm_token&id=eq.' + userId, { headers });
    if (res2.ok) {
      const profiles = await res2.json();
      if (profiles[0] && profiles[0].fcm_token && !tokens.some(t => t.token === profiles[0].fcm_token)) {
        tokens.push({ token: profiles[0].fcm_token, device_type: 'android' });
      }
    }
  }
  return tokens;
}

function pemToDer(pem) {
  // Remove PEM headers/footers and newlines, then base64 decode to DER
  const stripped = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binaryString = atob(stripped);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

async function getAccessToken() {
  const pemKey = '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCsobkCFjHr49ae\nE7eygVZ9s20L45CVcBftpZnNX+UcD9VW6ALWVBozhSca3HISeVojGl/cHqJjjo2a\nIHatwElTmss3i0e/kJX6RjnOsjHaV3KQCKMQQzbJq2UwSGj9oViRLrw0vjHFbr8K\nEPeOvc1V4AgHkd+VAIIWf+NyvG5I7hUMTv/+P8GVinwEQKhmIOxMtrhG5W9Lt5qZ\ncCE6fRStUlobu91OU6tBD4ZDLGHMwrblTPs9E/lPKj6MPgqqVoJVJJheL7lGJ/UM\ncMcz3dmen4WrhnXxESK7DGTFrwuRKQg3tXKYapCg86uw0WnWEms0GQEHSUihCvGy\n1ObaBjtDAgMBAAECggEAI/kFPN6UI4QULleMgWl7NPFlKUOP1twHWHGYJZg0fU79\nVUE+ihv3Y8H83peOO7RG6Kav0AYgL5++eR4HrPgzL3VDoHzpBA2kewUUObKfOdDc\nIhByrkpbSdXp3ZBRNHzhIEu9Uz5Iz8veikHz3C5H8fufoLgwf3OeKAMZScjjMFX4\nttyj8YD+ePV+A3GPgAwt/At7f3Q4B/ju3SWJhCKer2OA90utPiZr3QCn2tCQd1Kf\nhtkcebhV7yEbWYYfVwWYLDeBB0d2+SUXxbrEvcR1n9ExoQ0I/XW6vtL5FnKG8eua\nPzMvK667rer0akuyJjl9xSUEZVyJCwp/knhyqOc/SQKBgQDSQ96J86Zes8FewgSs\nYAp8PIwVAnSHB1az801S7InjuFPa4d8nQ7KrvSSjWyLrs6i1ha3f1MVgfyjXTdCD\niNTHxRb3Aqex0aEga3iPAhDGBsKOhQsv6Ahd24qFyh3iphFyyafkFOyohvV4LrBs\n0DNVJ63CqoM4mO0WMdTH/atvKQKBgQDSLlMb60Hylkdd5RrCRDKv1OcdeLDDvzqU\nHEERU4sBmvbvko31u62ysnGh/aIq4hwKxma+AENH8cZm2QYVIGIcTlsVLn68ZUHR\n7GHyDpfNrRYtnHkUXmg/BMw1ZGsu48owbDLMH6xLnCkHXfKacOgOV2ycfJFOBatn\nWz8Q5eXgiwKBgDn+djbeeRjNw5v7L4bLxpiVqp1w2+sSXxurE7y3eSDSCm7otcAC\nsBkmRiC4Vl1kZDgM8vQ1n2sKJ52a3NQqvWWMOtVOaiplg2eJvOrUywOTgb4FfBxu\nh0A7+W0FXlDRNSbP7/q8urmQ38uSNR8OHdpy4z46AY9uvpXMkL/Ie6xhAoGBAMf/\noMHeWUCXU427Zn0ZHApI0ysuHzYFD57ES/5KuulqJjPOBxuf3Sc/ufVlPh0ET57J\nMBb4dQ1OuXZAaRNNX06EGRPMzHhE+h7hikolLLpgS8xXKrgBJb1huVfNGFjkFQ+C\nxcuLEA5aqIgEE8h2S7rp4cX+mt3dcz7EivxvZxEFAoGAK2+9WEoF5w3LZKdlMcVY\n9M1HX0kI3el7FLsKcyuEFs9n3A+Zbt1KFKJ0XbflPfX1c3vY1SwL/Cz+EHV/BM6O\n70ZWASri6B04j7RwcY6W3st1CGRGxOgajuUrrg3DeG+7GiLnBVgpz0d4rdMmQLKU\n9KSnFN6o3Z7ZrN9dyzhdUFA=\n-----END PRIVATE KEY-----';
  const clientEmail = 'firebase-adminsdk-fbsvc@fresh-enterprise.iam.gserviceaccount.com';

  const derBuffer = pemToDer(pemKey);

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    derBuffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
  const payload = btoa(JSON.stringify({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');

  const signingInput = header + '.' + payload;
  const encoder = new TextEncoder();
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, encoder.encode(signingInput));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');

  const jwt = signingInput + '.' + sigB64;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwt,
  });
  const data = await res.json();
  if (!data.access_token) throw new Error('Token exchange failed: ' + JSON.stringify(data));
  return data.access_token;
}

async function sendFCMMessage(accessToken, token, title, body, data) {
  const projectId = 'fresh-enterprise';
  const payload = {
    token: token,
    notification: { title: title, body: body },
    data: data || {},
    android: { priority: 'high', notification: { sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
  };
  if (data && data.image) {
    payload.android.notification.image = data.image;
  }

  const res = await fetch('https://fcm.googleapis.com/v1/projects/' + projectId + '/messages:send', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + accessToken, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: payload }),
  });
  if (!res.ok) return { success: false, error: await res.text() };
  return { success: true, response: await res.json() };
}
