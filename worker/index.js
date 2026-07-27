// Kiwi FCM Worker — Cloudflare Worker
// يرسل إشعارات FCM مباشرة من Cloudflareبدون Edge Function

const CONFIG = {
  SUPABASE_URL: 'https://pftjlvtdzokbzuioqfug.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM',
  SUPABASE_SERVICE_ROLE_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODYwODQ2OCwiZXhwIjoyMDk0MTg0NDY4fQ.kEetvZsaf7xdDrwnCCMtXOd7aky92BnBayl_VUNtnQQ',
  FCM_PROJECT_ID: 'fresh-enterprise',
  FCM_CLIENT_EMAIL: 'firebase-adminsdk-fbsvc@fresh-enterprise.iam.gserviceaccount.com',
  FCM_PRIVATE_KEY_B64: 'LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQ3NvYmtDRmpIcjQ5YWUKRTdleWdWWjlzMjBMNDVDVmNCZnRwWm5OWCtVY0Q5Vlc2QUxXVkJvemhTY2EzSElTZVZvakdsL2NIcUpqam8yYQpJSGF0d0VsVG1zczNpMGUva0pYNlJqbk9zakhhVjNLUUNLTVFRemJKcTJVd1NHajlvVmlSTHJ3MHZqSEZicjhLCkVQZU92YzFWNEFnSGtkK1ZBSUlXZitOeXZHNUk3aFVNVHYvK1A4R1ZpbndFUUtobUlPeE10cmhHNVc5THQ1cVoKY0NFNmZSU3RVbG9idTkxT1U2dEJENFpETEdITXdyYmxUUHM5RS9sUEtqNk1QZ3FxVm9KVkpKaGVMN2xHSi9VTQpjTWN6M2RtZW40V3Joblh4RVNLN0RHVEZyd3VSS1FnM3RYS1lhcENnODZ1dzBXbldFbXMwR1FFSFNVaWhDdkd5CjFPYmFCanREQWdNQkFBRUNnZ0VBSS9rRlBONlVJNFFVTGxlTWdXbDdOUEZsS1VPUDF0d0hXSEdZSlpnMGZVNzkKVlVFK2lodjNZOEg4M3BlT083Ukc2S2F2MEFZZ0w1KytlUjRIclBnekwzVkRvSHpwQkEya2V3VVVPYktmT2REYwpJaEJ5cmtwYlNkWHAzWkJSTkh6aElFdTlVejVJejh2ZWlrSHozQzVIOGZ1Zm9MZ3dmM09lS0FNWlNjampNRlg0CnR0eWo4WUQrZVBWK0EzR1BnQXd0L0F0N2YzUTRCL2p1M1NXSmhDS2VyMk9BOTB1dFBpWnIzUUNuMnRDUWQxS2YKaHRrY2ViaFY3eUViV1lZZlZ3V1lMRGVCQjBkMitTVVh4YnJFdmNSMW45RXhvUTBJL1hXNnZ0TDVGbktHOGV1YQpQek12SzY2N3JlcjBha3V5SmpsOXhTVUVaVnlKQ3dwL2tuaHlxT2MvU1FLQmdRRFNROTZKODZaZXM4RmV3Z1NzCllBcDhQSXdWQW5TSEIxYXo4MDFTN0luanVGUGE0ZDhuUTdLcnZTU2pXeUxyczZpMWhhM2YxTVZnZnlqWFRkQ0QKaU5USHhSYjNBcWV4MGFFZ2EzaVBBaERHQnNLT2hRc3Y2QWhkMjRxRnloM2lwaEZ5eWFma0ZPeW9odlY0THJCcwowRE5WSjYzQ3FvTTRtTzBXTWRUSC9hdHZLUUtCZ1FEU0xsTWI2MEh5bGtkZDVSckNSREt2MU9jZGVMRER2enFVCkhFRVJVNHNCbXZidmtvMzF1NjJ5c25HaC9hSXE0aHdLeG1hK0FFTkg4Y1ptMlFZVklHSWNUbHNWTG42OFpVSFIKN0dIeURwZk5yUll0bkhrVVhtZy9CTXcxWkdzdTQ4b3diRExNSDZ4TG5Da0hYZkthY09nT1YyeWNmSkZPQmF0bgpXejhRNWVYZ2l3S0JnRG4rZGpiZWVSak53NXY3TDRiTHhwaVZxcDF3MitzU1h4dXJFN3kzZVNEU0NtN290Y0FDCnNCa21SaUM0Vmwxa1pEZ004dlExbjJzS0o1MmEzTlFxdldXTU90Vk9haXBsZzJlSnZPclV5d09UZ2I0RmZCeHUKaDBBNytXMEZYbERSTlNiUDcvcTh1cm1RMzh1U05SOE9IZHB5NHo0NkFZOXV2cFhNa0wvSWU2eGhBb0dCQU1mLwpvTUhlV1VDWFU0MjdabjBaSEFwSTB5c3VIellGRDU3RVMvNUt1dWxxSmpQT0J4dWYzU2MvdWZWbFBoMEVUNTdKCk1CYjRkUTFPdVhaQWFSTk5YMDZFR1JQTXpIaEUraDdoaWtvbExMcGdTOHhYS3JnQkpiMWh1VmZOR0Zqa0ZRK0MKeGN1TEVBNWFxSWdFRThoMlM3cnA0Y1grbXQzZGN6N0Vpdnh2WnhFRkFvR0FLMis5V0VvRjV3M0xaS2RsTWNWWQo5TTFIWDBrSTNlbDdGTHNLY3l1RUZzOW4zQStaYnQxS0ZLSjBYYmZsUGZYMWMzdlkxU3dML0N6K0VIVi9CTTZPCjcwWldBU3JpNkIwNGo3UndjWTZXM3N0MUNHUkd4T2dhanVVcnJnM0RlRys3R2lMbkJWZ3B6MGQ0cmRNbVFMS1UKOUtTbkZONm8zWjdack45ZHl6aGRVRkE9Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K',
};

export default {
  async fetch(request, env) {
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
      const { userId, broadcast, title, body, data } = await request.json();
      if (!title || !body) return new Response(JSON.stringify({ error: 'Missing title or body' }), { status: 400, headers: corsHeaders });
      if (!userId && !broadcast) return new Response(JSON.stringify({ error: 'Missing userId or broadcast' }), { status: 400, headers: corsHeaders });

      const tokens = await getTokens(userId, broadcast);
      if (!tokens.length) {
        return new Response(JSON.stringify({ error: 'No FCM tokens found', successful: 0, total: 0 }), { status: 200, headers: corsHeaders });
      }

      const accessToken = await getAccessToken();
      const results = await Promise.all(
        tokens.map(r => sendFCMMessage(accessToken, r.token, title, body, data).then(res => ({ token: r.token, ...res })))
      );

      const successful = results.filter(r => r.success).length;
      return new Response(JSON.stringify({ successful, total: results.length, broadcast: !!broadcast, results }), { headers: corsHeaders });
    } catch (error) {
      return new Response(JSON.stringify({ error: error.message || String(error) }), { status: 500, headers: corsHeaders });
    }
  },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function getTokens(userId, broadcast) {
  const tokens = [];
  const headers = { apikey: CONFIG.SUPABASE_ANON_KEY, Authorization: `Bearer ${CONFIG.SUPABASE_SERVICE_ROLE_KEY}` };

  if (broadcast) {
    const res1 = await fetch(`${CONFIG.SUPABASE_URL}/rest/v1/user_fcm_tokens?select=token,device_type`, { headers });
    if (res1.ok) { const data = await res1.json(); tokens.push(...data); }

    const res2 = await fetch(`${CONFIG.SUPABASE_URL}/rest/v1/profiles?select=id,fcm_token&fcm_token=not.is.null`, { headers });
    if (res2.ok) {
      const profiles = await res2.json();
      for (const p of profiles) {
        if (p.fcm_token && !tokens.some(t => t.token === p.fcm_token)) {
          tokens.push({ token: p.fcm_token, device_type: 'android' });
        }
      }
    }
  } else {
    const res1 = await fetch(`${CONFIG.SUPABASE_URL}/rest/v1/user_fcm_tokens?select=token,device_type&user_id=eq.${userId}`, { headers });
    if (res1.ok) { const data = await res1.json(); tokens.push(...data); }

    const res2 = await fetch(`${CONFIG.SUPABASE_URL}/rest/v1/profiles?select=fcm_token&id=eq.${userId}`, { headers });
    if (res2.ok) {
      const profiles = await res2.json();
      if (profiles[0]?.fcm_token && !tokens.some(t => t.token === profiles[0].fcm_token)) {
        tokens.push({ token: profiles[0].fcm_token, device_type: 'android' });
      }
    }
  }
  return tokens;
}

async function getAccessToken() {
  const privateKeyB64 = CONFIG.FCM_PRIVATE_KEY_B64;
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
    iss: CONFIG.FCM_CLIENT_EMAIL,
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

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${CONFIG.FCM_PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: payload }),
  });
  if (!res.ok) return { success: false, error: await res.text() };
  return { success: true, response: await res.json() };
}
