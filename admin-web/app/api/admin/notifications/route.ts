import { apiError, audit, requireAdmin, supabaseAdmin } from '@/lib/admin-server'

export const dynamic = 'force-dynamic'

export async function GET(request: Request) {
  try {
    await requireAdmin(request)
    const { data, error } = await supabaseAdmin()
      .from('notification_inbox')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(100)
    if (error) throw error
    return Response.json({ notifications: data ?? [] })
  } catch (error) {
    return apiError(error)
  }
}

export async function POST(request: Request) {
  try {
    const user = await requireAdmin(request)
    const body = await request.json()
    const title = typeof body.title === 'string' ? body.title.trim() : ''
    const message = typeof body.message === 'string' ? body.message.trim() : ''
    if (!title || !message || title.length > 120 || message.length > 1000) {
      return Response.json({ error: 'Isi pesan kotak masuk tidak valid.' }, { status: 400 })
    }
    const type = ['announcement', 'pro', 'reminder', 'system'].includes(body.type) ? body.type : 'announcement'
    const actionUrl = validActionUrl(body.actionUrl)
    if (body.actionUrl && actionUrl === null) {
      return Response.json({ error: 'Tautan aksi harus berupa URL HTTPS yang valid.' }, { status: 400 })
    }
    const { data, error } = await supabaseAdmin()
      .from('notification_inbox')
      .insert({
        user_id: typeof body.userId === 'string' && body.userId ? body.userId : null,
        title,
        body: message,
        type,
        action_url: actionUrl,
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

export async function PATCH(request: Request) {
  try {
    const user = await requireAdmin(request)
    const body = await request.json()
    const id = typeof body.id === 'string' ? body.id : ''
    if (!id) {
      return Response.json({ error: 'ID pesan tidak valid.' }, { status: 400 })
    }
    const updates: Record<string, unknown> = {}
    if (typeof body.title === 'string') {
      const title = body.title.trim()
      if (!title || title.length > 120) return Response.json({ error: 'Judul tidak valid (1-120 karakter).' }, { status: 400 })
      updates.title = title
    }
    if (typeof body.message === 'string') {
      const message = body.message.trim()
      if (!message || message.length > 1000) return Response.json({ error: 'Pesan tidak valid (1-1000 karakter).' }, { status: 400 })
      updates.body = message
    }
    if (typeof body.type === 'string' && ['announcement', 'pro', 'reminder', 'system'].includes(body.type)) {
      updates.type = body.type
    }
    if (typeof body.actionUrl !== 'undefined') {
      const actionUrl = validActionUrl(body.actionUrl)
      if (body.actionUrl && actionUrl === null) {
        return Response.json({ error: 'Tautan aksi harus berupa URL HTTPS yang valid.' }, { status: 400 })
      }
      updates.action_url = actionUrl
    }
    const { data, error } = await supabaseAdmin()
      .from('notification_inbox')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    await audit(user.id, 'update_inbox_notification', 'notification_inbox', id, updates)
    return Response.json({ notification: data })
  } catch (error) {
    return apiError(error)
  }
}

function validActionUrl(value: unknown): string | null {
  if (typeof value !== 'string' || !value.trim()) return null
  try {
    const url = new URL(value.trim())
    return url.protocol === 'https:' ? url.toString() : null
  } catch {
    return null
  }
}

export async function DELETE(request: Request) {
  try {
    const user = await requireAdmin(request)
    const { searchParams } = new URL(request.url)
    const id = searchParams.get('id')
    if (!id) {
      return Response.json({ error: 'ID pesan diperlukan.' }, { status: 400 })
    }
    const { error } = await supabaseAdmin()
      .from('notification_inbox')
      .delete()
      .eq('id', id)
    if (error) throw error
    await audit(user.id, 'delete_inbox_notification', 'notification_inbox', id)
    return Response.json({ success: true, id })
  } catch (error) {
    return apiError(error)
  }
}
