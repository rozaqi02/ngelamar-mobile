import OpenAI from 'npm:openai@4'
import { createClient } from 'npm:@supabase/supabase-js@2'

const jsonHeaders = { 'Content-Type': 'application/json' }

Deno.serve(async (request) => {
  const authHeader = request.headers.get('Authorization')
  const projectUrl = Deno.env.get('SUPABASE_URL')
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const openAiKey = Deno.env.get('OPENAI_API_KEY')
  if (!authHeader || !projectUrl || !publishableKey || !serviceRoleKey || !openAiKey) {
    return new Response(JSON.stringify({ error: 'Layanan AI belum dikonfigurasi.' }), {
      status: 503,
      headers: jsonHeaders,
    })
  }

  const userClient = createClient(projectUrl, publishableKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user } } = await userClient.auth.getUser()
  if (!user) {
    return new Response(JSON.stringify({ error: 'Sesi tidak valid.' }), { status: 401, headers: jsonHeaders })
  }

  const body = await request.json().catch(() => null)
  const task = typeof body?.task === 'string' ? body.task : ''
  const context = typeof body?.context === 'string' ? body.context : ''
  if (!['cover_letter', 'interview_practice', 'job_summary'].includes(task) || context.length < 10 || context.length > 12000) {
    return new Response(JSON.stringify({ error: 'Permintaan AI tidak valid.' }), { status: 400, headers: jsonHeaders })
  }

  const admin = createClient(projectUrl, serviceRoleKey)
  const { count } = await admin
    .from('app_events')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)
    .eq('name', 'ai_request')
    .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
  if ((count ?? 0) >= 10) {
    return new Response(JSON.stringify({ error: 'Kuota AI harian sudah tercapai.' }), { status: 429, headers: jsonHeaders })
  }

  const client = new OpenAI({ apiKey: openAiKey })
  const completion = await client.chat.completions.create({
    model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-4o-mini',
    temperature: 0.5,
    max_tokens: 900,
    messages: [
      { role: 'system', content: 'Kamu adalah asisten karier berbahasa Indonesia. Jawab ringkas, praktis, tanpa membuat fakta perusahaan.' },
      { role: 'user', content: `Tugas: ${task}\n\nKonteks pengguna:\n${context}` },
    ],
  })
  await admin.from('app_events').insert({ user_id: user.id, name: 'ai_request', properties: { task } })
  return new Response(JSON.stringify({ output: completion.choices[0]?.message?.content ?? '' }), { headers: jsonHeaders })
})
