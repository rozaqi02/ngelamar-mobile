import { apiError, requireAdmin, supabaseAdmin } from '@/lib/admin-server'

export const dynamic = 'force-dynamic'

export async function GET(request: Request) {
  try {
    await requireAdmin(request)
    const admin = supabaseAdmin()
    const now = new Date()
    const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString()
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString()
    const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString()

    const [total, dau, wau, mau, pro, feedback, recentEvents] = await Promise.all([
      admin.from('user_activity').select('*', { count: 'exact', head: true }),
      admin.from('user_activity').select('*', { count: 'exact', head: true }).gte('last_seen_at', dayAgo),
      admin.from('user_activity').select('*', { count: 'exact', head: true }).gte('last_seen_at', weekAgo),
      admin.from('user_activity').select('*', { count: 'exact', head: true }).gte('last_seen_at', monthAgo),
      admin.from('pro_entitlements').select('*', { count: 'exact', head: true }).eq('active', true).gt('expires_at', now.toISOString()),
      admin.from('user_feedback').select('*', { count: 'exact', head: true }).eq('status', 'new'),
      admin.from('app_events').select('name, created_at').order('created_at', { ascending: false }).limit(20),
    ])
    const firstError = [total, dau, wau, mau, pro, feedback, recentEvents]
      .map((result) => result.error)
      .find(Boolean)
    if (firstError) throw firstError
    const events = (recentEvents.data ?? []).reduce<Record<string, number>>((accumulator, event) => {
      accumulator[event.name] = (accumulator[event.name] ?? 0) + 1
      return accumulator
    }, {})

    return Response.json({
      metrics: {
        totalUsers: total.count ?? 0,
        dau: dau.count ?? 0,
        wau: wau.count ?? 0,
        mau: mau.count ?? 0,
        activePro: pro.count ?? 0,
        newFeedback: feedback.count ?? 0,
      },
      events,
    })
  } catch (error) {
    return apiError(error)
  }
}
