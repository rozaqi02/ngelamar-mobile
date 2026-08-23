import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = { 'Content-Type': 'application/json' }

Deno.serve(async (request) => {
  const cronSecret = Deno.env.get('CRON_SECRET')
  const providedSecret = request.headers.get('x-cron-secret')
  if (!cronSecret || providedSecret !== cronSecret) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: corsHeaders,
    })
  }

  const projectUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!projectUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: 'Server belum dikonfigurasi.' }), {
      status: 500,
      headers: corsHeaders,
    })
  }

  const admin = createClient(projectUrl, serviceRoleKey)
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
  const { data: activeUsers, error } = await admin
    .from('user_activity')
    .select('user_id')
    .gte('last_seen_at', sevenDaysAgo)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: corsHeaders,
    })
  }

  const rows = (activeUsers ?? []).map(({ user_id }) => ({
    user_id,
    title: 'Ringkasan mingguan Ngelamar',
    body: 'Luangkan waktu sebentar untuk meninjau progres lamaranmu minggu ini.',
    type: 'reminder',
    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  }))

  if (rows.length > 0) {
    const { error: insertError } = await admin.from('notification_inbox').insert(rows)
    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 500,
        headers: corsHeaders,
      })
    }
  }

  return new Response(JSON.stringify({ delivered: rows.length }), { headers: corsHeaders })
})
