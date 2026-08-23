import { createClient, type User } from '@supabase/supabase-js'

function environment(name: string) {
  const value = process.env[name]
  if (!value) throw new Error(`Environment variable ${name} belum diatur.`)
  return value
}

export function supabaseAdmin() {
  return createClient(
    environment('NEXT_PUBLIC_SUPABASE_URL'),
    environment('SUPABASE_SERVICE_ROLE_KEY'),
    { auth: { autoRefreshToken: false, persistSession: false } },
  )
}

export async function requireAdmin(request: Request): Promise<User> {
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '')
  if (!token) throw new Response('Login diperlukan.', { status: 401 })
  const admin = supabaseAdmin()
  const { data: userData, error: userError } = await admin.auth.getUser(token)
  if (userError || !userData.user) throw new Response('Sesi tidak valid.', { status: 401 })

  const { data: role, error: roleError } = await admin
    .from('admin_users')
    .select('role')
    .eq('user_id', userData.user.id)
    .maybeSingle()
  if (roleError || !role) throw new Response('Akses admin ditolak.', { status: 403 })
  return userData.user
}

export async function audit(
  actorId: string,
  action: string,
  targetType: string,
  targetId?: string,
  metadata: Record<string, unknown> = {},
) {
  await supabaseAdmin().from('admin_audit_logs').insert({
    actor_id: actorId,
    action,
    target_type: targetType,
    target_id: targetId ?? null,
    metadata,
  })
}

export function apiError(error: unknown) {
  if (error instanceof Response) {
    return new Response(error.body, { status: error.status })
  }
  console.error(error)
  return Response.json({ error: 'Terjadi kesalahan di server.' }, { status: 500 })
}
