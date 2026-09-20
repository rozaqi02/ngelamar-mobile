import { timingSafeEqual } from 'node:crypto'

import { supabaseAdmin } from '@/lib/admin-server'

export const dynamic = 'force-dynamic'

function isAuthorized(request: Request) {
  const cronSecret = process.env.CRON_SECRET
  const authorization = request.headers.get('authorization')
  const expected = cronSecret ? `Bearer ${cronSecret}` : ''

  if (!authorization || !expected) return false

  const actualBuffer = Buffer.from(authorization)
  const expectedBuffer = Buffer.from(expected)
  return (
    actualBuffer.length === expectedBuffer.length &&
    timingSafeEqual(actualBuffer, expectedBuffer)
  )
}

export async function GET(request: Request) {
  if (!isAuthorized(request)) {
    return Response.json(
      { ok: false, error: 'Unauthorized' },
      { status: 401 },
    )
  }

  const { error } = await supabaseAdmin()
    .from('admin_users')
    .select('user_id')
    .limit(1)

  if (error) {
    console.error('Supabase keepalive failed:', error.message)
    return Response.json(
      { ok: false, error: 'Supabase keepalive failed' },
      { status: 503 },
    )
  }

  return Response.json(
    { ok: true, checkedAt: new Date().toISOString() },
    { headers: { 'Cache-Control': 'no-store' } },
  )
}
