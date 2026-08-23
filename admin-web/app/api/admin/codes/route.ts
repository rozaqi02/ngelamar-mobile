import { createHash, randomBytes } from 'node:crypto'
import { apiError, audit, requireAdmin, supabaseAdmin } from '@/lib/admin-server'

export const dynamic = 'force-dynamic'

function makeCode() {
  return randomBytes(5).toString('hex').toUpperCase()
}

export async function GET(request: Request) {
  try {
    await requireAdmin(request)
    const { data, error } = await supabaseAdmin()
      .from('pro_activation_codes')
      .select('id, plan, duration_days, valid_until, max_redemptions, redemption_count, active, created_at, last_redeemed_at')
      .order('created_at', { ascending: false })
      .limit(100)
    if (error) throw error
    return Response.json({ codes: data ?? [] })
  } catch (error) {
    return apiError(error)
  }
}

export async function POST(request: Request) {
  try {
    const user = await requireAdmin(request)
    const body = await request.json()
    const plan = body.plan === 'yearly' ? 'yearly' : 'monthly'
    const durationDays = Number(body.durationDays)
    const maxRedemptions = Number(body.maxRedemptions ?? 1)
    const validUntil = typeof body.validUntil === 'string' && body.validUntil ? body.validUntil : null
    if (!Number.isInteger(durationDays) || durationDays < 1 || durationDays > 3650 ||
        !Number.isInteger(maxRedemptions) || maxRedemptions < 1 || maxRedemptions > 10000) {
      return Response.json({ error: 'Parameter kode PRO tidak valid.' }, { status: 400 })
    }
    const code = makeCode()
    const codeHash = createHash('sha256').update(code).digest('hex')
    const { data, error } = await supabaseAdmin()
      .from('pro_activation_codes')
      .insert({
        code_hash: codeHash,
        plan,
        duration_days: durationDays,
        max_redemptions: maxRedemptions,
        valid_until: validUntil,
      })
      .select('id, plan, duration_days, max_redemptions, valid_until, created_at')
      .single()
    if (error) throw error
    await audit(user.id, 'create_pro_code', 'pro_activation_code', data.id, { plan, durationDays, maxRedemptions })
    // The plaintext code exists only in this response and is never persisted.
    return Response.json({ code, record: data }, { status: 201 })
  } catch (error) {
    return apiError(error)
  }
}
