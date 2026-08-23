import { apiError, audit, requireAdmin, supabaseAdmin } from '@/lib/admin-server'

export const dynamic = 'force-dynamic'

export async function GET(request: Request) {
  try {
    await requireAdmin(request)
    const { data, error } = await supabaseAdmin()
      .from('user_feedback')
      .select('id, category, message, app_version, status, admin_note, created_at, user_id')
      .order('created_at', { ascending: false })
      .limit(100)
    if (error) throw error
    return Response.json({ feedback: data ?? [] })
  } catch (error) {
    return apiError(error)
  }
}

export async function PATCH(request: Request) {
  try {
    const user = await requireAdmin(request)
    const body = await request.json()
    const statuses = ['new', 'reviewing', 'resolved', 'closed']
    if (typeof body.id !== 'string' || !statuses.includes(body.status)) {
      return Response.json({ error: 'Status masukan tidak valid.' }, { status: 400 })
    }
    const { data, error } = await supabaseAdmin()
      .from('user_feedback')
      .update({
        status: body.status,
        admin_note: typeof body.adminNote === 'string' ? body.adminNote.slice(0, 2000) : null,
      })
      .eq('id', body.id)
      .select()
      .single()
    if (error) throw error
    await audit(user.id, 'update_feedback', 'user_feedback', body.id, { status: body.status })
    return Response.json({ feedback: data })
  } catch (error) {
    return apiError(error)
  }
}
