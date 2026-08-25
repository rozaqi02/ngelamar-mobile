import { GoogleAuth } from 'npm:google-auth-library@9.15.1'
import { withSupabase } from 'npm:@supabase/server@^1'

const jsonHeaders = { 'Content-Type': 'application/json' }
const fcmScope = 'https://www.googleapis.com/auth/firebase.messaging'

type InboxRecord = {
  id?: string
  user_id?: string | null
  title?: string
  body?: string
  type?: string
  action_url?: string | null
}

type DatabaseWebhook = {
  record?: InboxRecord
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`Secret ${name} belum dikonfigurasi.`)
  return value
}

function text(value: unknown, limit: number): string {
  const clean = String(value ?? '').replace(/\s+/g, ' ').trim()
  return clean.length <= limit ? clean : `${clean.slice(0, limit - 1).trimEnd()}…`
}

function stringData(record: InboxRecord) {
  return {
    inbox_id: text(record.id, 120),
    title: text(record.title, 120),
    body: text(record.body, 1000),
    type: text(record.type || 'announcement', 40),
    action_url: text(record.action_url, 500),
  }
}

function isUnregisteredToken(error: unknown): boolean {
  // FCM returns this stable reason when an app was uninstalled or its token
  // was rotated. Other transient FCM failures must keep the token intact.
  return JSON.stringify(error).includes('UNREGISTERED')
}

async function sendToToken({
  authClient,
  projectId,
  token,
  record,
}: {
  authClient: Awaited<ReturnType<GoogleAuth['getClient']>>
  projectId: string
  token: string
  record: InboxRecord
}) {
  return authClient.request({
    url: `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    method: 'POST',
    data: {
      message: {
        token,
        // Data-only keeps the Flutter background handler in charge of
        // presentation and inbox de-duplication on Android.
        data: stringData(record),
        android: {
          priority: 'high',
        },
      },
    },
  })
}

export default {
  // A Database Webhook sends a Supabase secret key. `withSupabase` validates
  // it before this handler receives the database record.
  fetch: withSupabase({ auth: 'secret' }, async (request, context) => {
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method tidak diizinkan.' }), {
      status: 405,
      headers: jsonHeaders,
    })
  }

  try {
    const payload = (await request.json()) as DatabaseWebhook
    const record = payload.record
    if (!record?.id || !record.title || !record.body) {
      return new Response(JSON.stringify({ ignored: 'Payload inbox tidak lengkap.' }), {
        status: 202,
        headers: jsonHeaders,
      })
    }

    const credentials = JSON.parse(requiredEnvironment('FCM_SERVICE_ACCOUNT_JSON'))
    const projectId = text(credentials.project_id, 160)
    if (!projectId) throw new Error('project_id FCM tidak ditemukan.')

    let tokenQuery = context.supabaseAdmin
      .from('device_push_tokens')
      .select('token')
      .eq('enabled', true)
      .eq('platform', 'android')
      .limit(1000)
    if (record.user_id) tokenQuery = tokenQuery.eq('user_id', record.user_id)

    const { data: deviceRows, error: tokenError } = await tokenQuery
    if (tokenError) throw new Error(`Gagal membaca perangkat: ${tokenError.message}`)

    const tokens = [...new Set((deviceRows ?? []).map((row) => text(row.token, 4096)).filter(Boolean))]
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ delivered: 0, reason: 'Tidak ada perangkat aktif.' }), {
        headers: jsonHeaders,
      })
    }

    const auth = new GoogleAuth({ credentials, scopes: [fcmScope] })
    const authClient = await auth.getClient()
    const results = await Promise.allSettled(
      tokens.map((token) => sendToToken({ authClient, projectId, token, record })),
    )
    const delivered = results.filter((result) => result.status === 'fulfilled').length
    const failed = results.length - delivered
    const expiredTokens = results.flatMap((result, index) =>
      result.status === 'rejected' && isUnregisteredToken(result.reason)
        ? [tokens[index]]
        : [],
    )
    if (expiredTokens.length > 0) {
      const { error: cleanupError } = await context.supabaseAdmin
        .from('device_push_tokens')
        .delete()
        .in('token', expiredTokens)
      if (cleanupError) console.error('Gagal menghapus token FCM tidak aktif', cleanupError)
    }

    return new Response(
      JSON.stringify({ delivered, failed, retired_tokens: expiredTokens.length }),
      { headers: jsonHeaders },
    )
  } catch (error) {
    console.error('Pengiriman push FCM gagal', error)
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Kesalahan pengiriman push.' }),
      { status: 500, headers: jsonHeaders },
    )
  }
  }),
}
