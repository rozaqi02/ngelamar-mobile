'use client'

import { FormEvent, useEffect, useState } from 'react'
import { supabaseBrowser } from '@/lib/supabase-browser'

type Overview = {
  metrics: { totalUsers: number; dau: number; wau: number; mau: number; activePro: number; newFeedback: number }
  events: Record<string, number>
}
type Feedback = { id: string; category: string; message: string; app_version: string | null; status: string; created_at: string }
type RemoteConfig = { key: string; value: Record<string, unknown>; description: string | null; is_enabled: boolean }

async function adminFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const { data } = await supabaseBrowser().auth.getSession()
  if (!data.session) throw new Error('Sesi admin belum tersedia.')
  const response = await fetch(path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${data.session.access_token}`,
      ...(options?.headers ?? {}),
    },
  })
  const payload = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(payload.error ?? 'Permintaan admin gagal.')
  return payload as T
}

export default function AdminPage() {
  const [email, setEmail] = useState<string | null>(null)
  const [overview, setOverview] = useState<Overview | null>(null)
  const [feedback, setFeedback] = useState<Feedback[]>([])
  const [config, setConfig] = useState<RemoteConfig[]>([])
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [code, setCode] = useState('')
  const [plan, setPlan] = useState('monthly')
  const [durationDays, setDurationDays] = useState(30)
  const [announcementTitle, setAnnouncementTitle] = useState('')
  const [announcementMessage, setAnnouncementMessage] = useState('')
  const [broadcastTitle, setBroadcastTitle] = useState('')
  const [broadcastMessage, setBroadcastMessage] = useState('')

  const load = async () => {
    setError('')
    try {
      const [dashboard, feedbackResponse, configResponse] = await Promise.all([
        adminFetch<Overview>('/api/admin/overview'),
        adminFetch<{ feedback: Feedback[] }>('/api/admin/feedback'),
        adminFetch<{ config: RemoteConfig[] }>('/api/admin/config'),
      ])
      setOverview(dashboard)
      setFeedback(feedbackResponse.feedback)
      setConfig(configResponse.config)
      const announcement = configResponse.config.find((item) => item.key === 'app_announcement')?.value
      setAnnouncementTitle(typeof announcement?.title === 'string' ? announcement.title : '')
      setAnnouncementMessage(typeof announcement?.message === 'string' ? announcement.message : '')
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Dashboard belum dapat dimuat.')
    }
  }

  useEffect(() => {
    const auth = supabaseBrowser().auth
    auth.getUser().then(({ data }) => {
      setEmail(data.user?.email ?? null)
      if (data.user) void load()
    })
    const { data: listener } = auth.onAuthStateChange((_event, session) => {
      setEmail(session?.user.email ?? null)
      if (session?.user) void load()
      else {
        setOverview(null)
        setFeedback([])
        setConfig([])
      }
    })
    return () => listener.subscription.unsubscribe()
  }, [])

  const signInGoogle = async () => {
    setError('')
    const { error: authError } = await supabaseBrowser().auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin },
    })
    if (authError) setError(authError.message)
  }

  const createCode = async (event: FormEvent) => {
    event.preventDefault()
    setBusy(true); setError(''); setNotice('')
    try {
      const response = await adminFetch<{ code: string }>('/api/admin/codes', {
        method: 'POST',
        body: JSON.stringify({ plan, durationDays, maxRedemptions: 1 }),
      })
      setCode(response.code)
      setNotice('Kode baru dibuat. Salin sekarang; kode asli tidak disimpan di dashboard.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Kode gagal dibuat.')
    } finally { setBusy(false) }
  }

  const saveAnnouncement = async (event: FormEvent) => {
    event.preventDefault()
    setBusy(true); setError(''); setNotice('')
    try {
      await adminFetch('/api/admin/config', {
        method: 'PUT',
        body: JSON.stringify({
          key: 'app_announcement',
          description: 'Pengumuman yang tampil di aplikasi',
          isEnabled: true,
          value: { enabled: Boolean(announcementTitle && announcementMessage), title: announcementTitle, message: announcementMessage, action_url: '' },
        }),
      })
      setNotice('Pengumuman tersimpan. Aplikasi mengambil konfigurasi saat dibuka atau kembali aktif.')
      await load()
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Konfigurasi gagal disimpan.')
    } finally { setBusy(false) }
  }

  const sendBroadcast = async (event: FormEvent) => {
    event.preventDefault()
    setBusy(true); setError(''); setNotice('')
    try {
      await adminFetch('/api/admin/notifications', {
        method: 'POST',
        body: JSON.stringify({ title: broadcastTitle, message: broadcastMessage, type: 'announcement' }),
      })
      setBroadcastTitle(''); setBroadcastMessage('')
      setNotice('Pengumuman masuk telah dikirim ke semua pengguna aktif saat mereka membuka aplikasi.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Pengumuman gagal dikirim.')
    } finally { setBusy(false) }
  }

  const resolveFeedback = async (id: string) => {
    try {
      await adminFetch('/api/admin/feedback', { method: 'PATCH', body: JSON.stringify({ id, status: 'resolved' }) })
      setFeedback((current) => current.map((item) => item.id === id ? { ...item, status: 'resolved' } : item))
    } catch (requestError) { setError(requestError instanceof Error ? requestError.message : 'Status feedback gagal diperbarui.') }
  }

  if (!email) {
    return <main className="auth"><section className="auth-card"><p className="eyebrow">NGELAMAR / ADMIN</p><h1>Kelola aplikasi tanpa menyentuh database manual.</h1><p>Dashboard ini khusus admin. Masuk memakai Google yang sudah didaftarkan sebagai admin pada tabel <code>admin_users</code>.</p><button onClick={signInGoogle}>Masuk dengan Google</button>{error && <p className="error">{error}</p>}</section></main>
  }

  return <main className="shell"><header><div><p className="eyebrow">NGELAMAR / CONTROL ROOM</p><h1>Halo, {email}</h1></div><div className="header-actions"><button className="ghost" onClick={() => void load()}>Muat ulang</button><button className="ghost" onClick={() => void supabaseBrowser().auth.signOut()}>Keluar</button></div></header>
    {error && <p className="error">{error}</p>}{notice && <p className="notice">{notice}</p>}
    {!overview ? <p className="loading">Memeriksa izin admin dan memuat data…</p> : <>
      <section className="metrics">{[
        ['Pengguna total', overview.metrics.totalUsers], ['Aktif 24 jam', overview.metrics.dau], ['Aktif 7 hari', overview.metrics.wau], ['Aktif 30 hari', overview.metrics.mau], ['PRO aktif', overview.metrics.activePro], ['Masukan baru', overview.metrics.newFeedback],
      ].map(([label, value]) => <article key={String(label)}><span>{label}</span><strong>{value}</strong></article>)}</section>
      <section className="grid two"><article className="panel"><h2>Buat kode PRO</h2><p>Plaintext hanya ditampilkan sekali setelah dibuat.</p><form onSubmit={createCode}><label>Paket<select value={plan} onChange={(event) => setPlan(event.target.value)}><option value="monthly">Bulanan</option><option value="yearly">Tahunan</option></select></label><label>Masa aktif (hari)<input type="number" min="1" max="3650" value={durationDays} onChange={(event) => setDurationDays(Number(event.target.value))}/></label><button disabled={busy}>Buat kode</button></form>{code && <div className="code"><code>{code}</code><button className="ghost" onClick={() => navigator.clipboard.writeText(code)}>Salin</button></div>}</article>
      <article className="panel"><h2>Pengumuman aplikasi</h2><p>Tampil saat aplikasi mengambil remote config.</p><form onSubmit={saveAnnouncement}><label>Judul<input value={announcementTitle} onChange={(event) => setAnnouncementTitle(event.target.value)} placeholder="Contoh: Pembaruan tersedia"/></label><label>Pesan<textarea value={announcementMessage} onChange={(event) => setAnnouncementMessage(event.target.value)} placeholder="Pesan singkat untuk pengguna"/></label><button disabled={busy}>Simpan pengumuman</button></form></article></section>
      <section className="grid two"><article className="panel"><h2>Kirim ke Kotak Masuk</h2><p>Pengumuman server-side untuk seluruh pengguna.</p><form onSubmit={sendBroadcast}><label>Judul<input value={broadcastTitle} onChange={(event) => setBroadcastTitle(event.target.value)} required/></label><label>Pesan<textarea value={broadcastMessage} onChange={(event) => setBroadcastMessage(event.target.value)} required/></label><button disabled={busy}>Kirim</button></form></article>
      <article className="panel"><h2>Event terbaru</h2><div className="event-list">{Object.entries(overview.events).length ? Object.entries(overview.events).map(([name, count]) => <p key={name}><code>{name}</code><span>{count}</span></p>) : <p>Belum ada event privat yang masuk.</p>}</div></article></section>
      <section className="panel"><h2>Masukan pengguna</h2>{feedback.length ? <div className="feedback">{feedback.map((item) => <article key={item.id}><div><span className={`badge ${item.status}`}>{item.status}</span><strong>{item.category}</strong><small>{new Date(item.created_at).toLocaleString('id-ID')} · v{item.app_version ?? '—'}</small><p>{item.message}</p></div>{item.status !== 'resolved' && <button className="ghost" onClick={() => void resolveFeedback(item.id)}>Tandai selesai</button>}</article>)}</div> : <p>Belum ada masukan.</p>}</section>
    </>}
  </main>
}
