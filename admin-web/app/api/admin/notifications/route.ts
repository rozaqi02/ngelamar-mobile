import { apiError, audit, requireAdmin, supabaseAdmin } from '@/lib/admin-server'

export async function POST(request: Request) {
  try {
    const user = await requireAdmin(request)
    const body = await request.json()
    const title = typeof body.title === 'string' ? body.title.trim() : ''
    const message = typeof body.message === 'string' ? body.message.trim() : ''
    if (!title || !message || title.length > 120 || message.length > 1000) {
      return Response.json({ error: 'Isi pengumuman tidak valid.' }, { status: 400 })
    }
    const { data, error } = await supabaseAdmin()
      .from('notification_inbox')
      .insert({
        user_id: typeof body.userId === 'string' && body.userId ? body.userId : null,
        title,
        body: message,
        type: body.type === 'pro' ? 'pro' : 'announcement',
        action_url: typeof body.actionUrl === 'string' && body.actionUrl ? body.actionUrl : null,
      })
      .select()
      .single()
    if (error) throw error
    await audit(user.id, 'send_inbox_notification', 'notification_inbox', data.id, { broadcast: !body.userId })
    return Response.json({ notification: data }, { status: 201 })
  } catch (error) {
    return apiError(error)
  }
}
