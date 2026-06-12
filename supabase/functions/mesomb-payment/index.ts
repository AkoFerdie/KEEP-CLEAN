// @ts-ignore
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// @ts-ignore
declare const Deno: any

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const ALGORITHM = 'HMAC-SHA1'
const SERVICE   = 'payment'
const HOST      = 'https://mesomb.hachther.com'
const ENDPOINT  = '/api/v1.1/payment/collect/'

async function sha1Hex(data: string): Promise<string> {
  const encoder = new TextEncoder()
  const buf = await crypto.subtle.digest('SHA-1', encoder.encode(data))
  return Array.from(new Uint8Array(buf)).map((b: any) => b.toString(16).padStart(2, '0')).join('')
}

async function hmacSha1Hex(secret: string, data: string): Promise<string> {
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw', encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-1' }, false, ['sign']
  )
  const buf = await crypto.subtle.sign('HMAC', key, encoder.encode(data))
  return Array.from(new Uint8Array(buf)).map((b: any) => b.toString(16).padStart(2, '0')).join('')
}

serve(async (req: any) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders, status: 200 })
  }

  try {
    const { amount, service, payer } = await req.json()

    const accessKey = Deno.env.get('MESOMB_ACCESS_KEY') ?? ''
    const secretKey = Deno.env.get('MESOMB_SECRET_KEY') ?? ''
    const appKey    = Deno.env.get('MESOMB_APP_KEY') ?? ''

    let formattedPhone = payer.replace(/\D/g, '')
    if (!formattedPhone.startsWith('237')) formattedPhone = '237' + formattedPhone

    const nonce = Math.random().toString(36).substring(2, 12)
    const date  = new Date()
    const timestamp = date.getTime() // milliseconds

    // Scope: YYYYMMDD/service/mesomb_request
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, '0')
    const d = String(date.getDate()).padStart(2, '0')
    const scope = `${y}${m}${d}/${SERVICE}/mesomb_request`

    const body = {
      amount: parseInt(amount),
      service: service.toUpperCase(),
      payer: formattedPhone,
      nonce,
      country: 'CM',
      currency: 'XAF',
      trxID: `PAY${Date.now()}`,
    }

    const bodyStr  = JSON.stringify(body)
    const fullUrl  = `${HOST}${ENDPOINT}`

    // Build canonical headers (sorted alphabetically)
    const headers: Record<string, string> = {
      'host': 'https://mesomb.hachther.com',
      'x-mesomb-date': String(timestamp),
      'x-mesomb-nonce': nonce,
    }
    const headersKeys     = Object.keys(headers).sort()
    const canonicalHeaders = headersKeys.map(k => `${k}:${headers[k]}`).join('\n')
    const signedHeaders    = headersKeys.join(';')

    // Payload hash
    const payloadHash = await sha1Hex(bodyStr)

    // Canonical request
    const canonicalRequest = [
      'POST',
      ENDPOINT,
      '',               // canonical query string (empty)
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n')

    // String to sign
    const stringToSign = `${ALGORITHM}\n${timestamp}\n${scope}\n${await sha1Hex(canonicalRequest)}`

    // Final signature
    const signature = await hmacSha1Hex(secretKey, stringToSign)

    // Authorization header
    const authHeader = `${ALGORITHM} Credential=${accessKey}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`

    console.log('scope:', scope)
    console.log('stringToSign:', stringToSign)
    console.log('authHeader:', authHeader)

    const response = await fetch(fullUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
        'X-MeSomb-Application': appKey,
        'x-mesomb-date': String(timestamp),
        'x-mesomb-nonce': nonce,
      },
      body: bodyStr,
    })

    const text = await response.text()
    console.log('MeSomb response:', text)

    let data: any = {}
    try { data = JSON.parse(text) } catch (_) { data = { raw: text } }

    return new Response(JSON.stringify({
      success: data.success ?? false,
      message: data.message || data.detail || text,
      transaction: data.transaction || data,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    console.error('Error:', error)
    return new Response(JSON.stringify({
      success: false,
      message: error?.message || 'Payment failed',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
