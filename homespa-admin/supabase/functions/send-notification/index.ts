import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FCM_PROJECT_ID = 'kaizen-home-spa-bf55a'

// Base64url encode a Uint8Array
function base64url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
}

// Build and RS256-sign a JWT for Google service-account auth
async function createJWT(
  payload: Record<string, unknown>,
  privateKeyPem: string
): Promise<string> {
  const header = { alg: 'RS256', typ: 'JWT' }

  const enc = new TextEncoder()
  const encodedHeader  = base64url(enc.encode(JSON.stringify(header)))
  const encodedPayload = base64url(enc.encode(JSON.stringify(payload)))
  const signingInput   = `${encodedHeader}.${encodedPayload}`

  // Strip PEM envelope and decode
  const pemBody = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '')
  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    enc.encode(signingInput)
  )

  return `${signingInput}.${base64url(new Uint8Array(signatureBuffer))}`
}

async function getAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}')

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const jwt = await createJWT(payload, serviceAccount.private_key)

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await response.json()
  if (!tokenData.access_token) {
    throw new Error(`OAuth2 token exchange failed: ${JSON.stringify(tokenData)}`)
  }
  return tokenData.access_token
}

async function sendFCM(
  token: string,
  title: string,
  body: string,
) {
  const accessToken = await getAccessToken()

  const message = {
    message: {
      token,
      notification: {
        title,
        body,
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channel_id: 'kaizen_notifications',
        },
      },
    },
  }

  console.log('FCM token:', token)
  console.log('FCM request body:', JSON.stringify(message))

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    }
  )

  const responseText = await response.text()
  console.log('FCM response:', responseText)
  return JSON.parse(responseText)
}

serve(async (req) => {
  try {
    const { user_id, title, body } = await req.json()

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'user_id, title, and body are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: profile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', user_id)
      .single()

    if (!profile?.fcm_token) {
      return new Response(
        JSON.stringify({ error: 'No FCM token for this user' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const result = await sendFCM(profile.fcm_token, title, body)

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal error'
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
