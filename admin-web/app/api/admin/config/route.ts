import { apiError, audit, requireAdmin, supabaseAdmin } from '@/lib/admin-server'

export const dynamic = 'force-dynamic'

export async function GET(request: Request) {
  try {
    await requireAdmin(request)
    const { data, error } = await supabaseAdmin()
      .from('remote_config')
      .select('*')
      .order('key')
    if (error) throw error
    return Response.json({ config: data ?? [] })
  } catch (error) {
    return apiError(error)
  }
}

export async function PUT(request: Request) {
  try {
    const user = await requireAdmin(request)
    const body = await request.json()
    const key = typeof body.key === 'string' ? body.key : ''
    if (!/^[a-z0-9_]{1,80}$/.test(key) || typeof body.value !== 'object' || body.value === null) {
      return Response.json({ error: 'Konfigurasi tidak valid.' }, { status: 400 })
    }
    const { data, error } = await supabaseAdmin()
      .from('remote_config')
      .upsert({
        key,
        value: body.value,
        description: typeof body.description === 'string' ? body.description.slice(0, 400) : null,
        is_enabled: body.isEnabled !== false,
        updated_by: user.id,
      })
      .select()
      .single()
    if (error) throw error
    await audit(user.id, 'update_remote_config', 'remote_config', key)
    return Response.json({ config: data })
  } catch (error) {
    return apiError(error)
  }
}
