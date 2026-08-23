'use client'

import { FormEvent, useEffect, useMemo, useState } from 'react'
import { isSupabaseBrowserConfigured, supabaseBrowser } from '@/lib/supabase-browser'

type Overview = {
  metrics: { totalUsers: number; dau: number; wau: number; mau: number; activePro: number; newFeedback: number }
  events: Record<string, number>
}
type Feedback = { id: string; category: string; message: string; app_version: string | null; status: string; created_at: string }
type RemoteConfig = { key: string; value: Record<string, unknown>; description: string | null; is_enabled: boolean }
type BusyAction = 'load' | 'code' | 'announcement' | 'broadcast' | `feedback:${string}` | null

const eventLabels: Record<string, string> = {
  app_open: 'Aplikasi dibuka',
  feedback_submitted: 'Masukan dikirim',
  pro_activated: 'PRO diaktifkan',
  job_created: 'Lamaran ditambahkan',
  job_status_updated: 'Status lamaran diperbarui',
}

async function adminFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const { data } = await supabaseBrowser().auth.getSession()
  if (!data.session) throw new Error('Sesi admin belum tersedia. Silakan masuk kembali.')
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
  const supabaseConfigured = isSupabaseBrowserConfigured()
  const [authReady, setAuthReady] = useState(false)
  const [email, setEmail] = useState<string | null>(null)
  const [overview, setOverview] = useState<Overview | null>(null)
  const [feedback, setFeedback] = useState<Feedback[]>([])
  const [config, setConfig] = useState<RemoteConfig[]>([])
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [busyAction, setBusyAction] = useState<BusyAction>(null)
  const [code, setCode] = useState('')
  const [plan, setPlan] = useState('monthly')
  const [announcementTitle, setAnnouncementTitle] = useState('')
  const [announcementMessage, setAnnouncementMessage] = useState('')
  const [broadcastTitle, setBroadcastTitle] = useState('')
  const [broadcastMessage, setBroadcastMessage] = useState('')
  const [feedbackQuery, setFeedbackQuery] = useState('')
  const [feedbackStatus, setFeedbackStatus] = useState('open')

  const filteredFeedback = useMemo(() => {
    const query = feedbackQuery.trim().toLocaleLowerCase('id-ID')
    return feedback.filter((item) => {
      const matchesStatus = feedbackStatus === 'all' || (feedbackStatus === 'open' ? item.status !== 'resolved' : item.status === 'resolved')
      const matchesQuery = !query || `${item.category} ${item.message} ${item.app_version ?? ''}`.toLocaleLowerCase('id-ID').includes(query)
      return matchesStatus && matchesQuery
    })
  }, [feedback, feedbackQuery, feedbackStatus])

  const clearMessages = () => {
    setError('')
    setNotice('')
  }

  const load = async () => {
    setBusyAction('load')
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
    } finally {
      setBusyAction(null)
    }
  }

  useEffect(() => {
    if (!supabaseConfigured) {
      setError('Konfigurasi lokal belum lengkap. Salin .env.example menjadi .env.local lalu isi URL dan publishable key Supabase.')
      setAuthReady(true)
      return
    }
    const auth = supabaseBrowser().auth
    auth.getUser().then(({ data }) => {
      setEmail(data.user?.email ?? null)
      setAuthReady(true)
      if (data.user) void load()
    })
    const { data: listener } = auth.onAuthStateChange((_event, session) => {
      setEmail(session?.user.email ?? null)
      setAuthReady(true)
      if (session?.user) void load()
      else {
        setOverview(null)
        setFeedback([])
        setConfig([])
      }
    })
    return () => listener.subscription.unsubscribe()
  }, [supabaseConfigured])

  const signInGoogle = async () => {
    clearMessages()
    setBusyAction('load')
    const { error: authError } = await supabaseBrowser().auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin },
    })
    if (authError) {
      setError(authError.message)
      setBusyAction(null)
    }
  }

  const createCode = async (event: FormEvent) => {
    event.preventDefault()
    setBusyAction('code'); clearMessages(); setCode('')
    try {
      const response = await adminFetch<{ code: string }>('/api/admin/codes', {
        method: 'POST',
        body: JSON.stringify({ plan }),
      })
      setCode(response.code)
      setNotice('Kode baru dibuat. Salin sekarang; kode asli hanya ditampilkan sekali.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Kode gagal dibuat.')
    } finally { setBusyAction(null) }
  }

  const copyCode = async () => {
    try {
      await navigator.clipboard.writeText(code)
      setNotice('Kode PRO berhasil disalin.')
      setError('')
    } catch {
      setError('Kode tidak dapat disalin otomatis. Pilih kode lalu salin secara manual.')
    }
  }

  const saveAnnouncement = async (event: FormEvent) => {
    event.preventDefault()
    setBusyAction('announcement'); clearMessages()
    try {
      await adminFetch('/api/admin/config', {
        method: 'PUT',
        body: JSON.stringify({
          key: 'app_announcement',
          description: 'Pengumuman yang tampil di aplikasi',
          isEnabled: true,
          value: { enabled: Boolean(announcementTitle && announcementMessage), title: announcementTitle.trim(), message: announcementMessage.trim(), action_url: '' },
        }),
      })
      setNotice(announcementTitle && announcementMessage ? 'Pengumuman aplikasi berhasil disimpan.' : 'Pengumuman aplikasi dinonaktifkan.')
      await load()
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Konfigurasi gagal disimpan.')
      setBusyAction(null)
    }
  }

  const sendBroadcast = async (event: FormEvent) => {
    event.preventDefault()
    const confirmed = window.confirm(`Kirim “${broadcastTitle.trim()}” ke kotak masuk seluruh pengguna? Tindakan ini tidak dapat dibatalkan.`)
    if (!confirmed) return
    setBusyAction('broadcast'); clearMessages()
    try {
      await adminFetch('/api/admin/notifications', {
        method: 'POST',
        body: JSON.stringify({ title: broadcastTitle.trim(), message: broadcastMessage.trim(), type: 'announcement' }),
      })
      setBroadcastTitle(''); setBroadcastMessage('')
      setNotice('Pesan berhasil dikirim ke kotak masuk seluruh pengguna.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Pengumuman gagal dikirim.')
    } finally { setBusyAction(null) }
  }

  const resolveFeedback = async (id: string) => {
    setBusyAction(`feedback:${id}`); clearMessages()
    try {
      await adminFetch('/api/admin/feedback', { method: 'PATCH', body: JSON.stringify({ id, status: 'resolved' }) })
      setFeedback((current) => current.map((item) => item.id === id ? { ...item, status: 'resolved' } : item))
      setNotice('Masukan ditandai selesai.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Status masukan gagal diperbarui.')
    } finally { setBusyAction(null) }
  }

  if (!authReady) {
    return <main className="auth"><section className="auth-card auth-loading" aria-live="polite"><span className="spinner"/><p>Memulihkan sesi admin…</p></section></main>
  }

  if (!email) {
    return <main className="auth"><section className="auth-card"><p className="eyebrow">NGELAMAR / ADMIN</p><h1>Kelola aplikasi tanpa menyentuh database manual.</h1><p>Dashboard ini khusus admin. Masuk memakai Google yang terdaftar pada tabel <code>admin_users</code>.</p><button onClick={signInGoogle} disabled={!supabaseConfigured || busyAction === 'load'}>{busyAction === 'load' ? 'Mengarahkan…' : 'Masuk dengan Google'}</button>{error && <p className="error" role="alert">{error}</p>}</section></main>
  }

  const isLoading = busyAction === 'load'

  return <main className="shell"><header><div><p className="eyebrow">NGELAMAR / CONTROL ROOM</p><h1>Halo, {email}</h1></div><div className="header-actions"><button className="ghost" onClick={() => void load()} disabled={Boolean(busyAction)}>{isLoading ? 'Memuat…' : 'Muat ulang'}</button><button className="ghost" onClick={() => void supabaseBrowser().auth.signOut()} disabled={Boolean(busyAction)}>Keluar</button></div></header>
    <div className="status-region" aria-live="polite" aria-atomic="true">{error && <p className="error" role="alert">{error}</p>}{notice && <p className="notice">{notice}</p>}</div>
    {!overview ? <section className="loading-state" aria-live="polite"><span className="spinner"/><div><strong>Memuat control room</strong><p>Memeriksa izin admin dan mengambil data terbaru…</p></div></section> : <>
      <section className="metrics" aria-label="Ringkasan pengguna">{[
        ['Pengguna total', overview.metrics.totalUsers], ['Aktif 24 jam', overview.metrics.dau], ['Aktif 7 hari', overview.metrics.wau], ['Aktif 30 hari', overview.metrics.mau], ['PRO aktif', overview.metrics.activePro], ['Masukan baru', overview.metrics.newFeedback],
      ].map(([label, value]) => <article key={String(label)}><span>{label}</span><strong>{value}</strong></article>)}</section>
      <section className="grid two"><article className="panel"><h2>Buat kode PRO</h2><p>Kode angka 10 digit, sekali pakai, dan hanya ditampilkan sekali.</p><form onSubmit={createCode}><label>Paket<select value={plan} onChange={(event) => setPlan(event.target.value)}><option value="monthly">Bulanan · 30 hari</option><option value="yearly">Tahunan · 365 hari</option></select></label><p className="helper">Durasi mengikuti paket secara otomatis agar masa aktif selalu konsisten.</p><button disabled={Boolean(busyAction)}>{busyAction === 'code' ? 'Membuat…' : 'Buat kode'}</button></form>{code && <div className="code" aria-live="polite"><code>{code}</code><button className="ghost" onClick={() => void copyCode()}>Salin</button></div>}</article>
      <article className="panel"><h2>Pengumuman aplikasi</h2><p>Tampil sebagai pengumuman utama saat aplikasi dibuka kembali.</p><form onSubmit={saveAnnouncement}><label>Judul <span className="counter">{announcementTitle.length}/80</span><input value={announcementTitle} onChange={(event) => setAnnouncementTitle(event.target.value)} maxLength={80} placeholder="Contoh: Pembaruan tersedia"/></label><label>Pesan <span className="counter">{announcementMessage.length}/280</span><textarea value={announcementMessage} onChange={(event) => setAnnouncementMessage(event.target.value)} maxLength={280} placeholder="Pesan singkat untuk pengguna"/></label><button disabled={Boolean(busyAction)}>{busyAction === 'announcement' ? 'Menyimpan…' : 'Simpan pengumuman'}</button></form></article></section>
      <section className="grid two"><article className="panel"><h2>Kirim ke Kotak Masuk</h2><p>Pesan permanen untuk seluruh pengguna. Konfirmasi akan diminta sebelum dikirim.</p><form onSubmit={sendBroadcast}><label>Judul <span className="counter">{broadcastTitle.length}/80</span><input value={broadcastTitle} onChange={(event) => setBroadcastTitle(event.target.value)} maxLength={80} required/></label><label>Pesan <span className="counter">{broadcastMessage.length}/500</span><textarea value={broadcastMessage} onChange={(event) => setBroadcastMessage(event.target.value)} maxLength={500} required/></label><button disabled={Boolean(busyAction)}>{busyAction === 'broadcast' ? 'Mengirim…' : 'Tinjau dan kirim'}</button></form></article>
      <article className="panel"><h2>Event terbaru</h2><p>Aktivitas privat yang dicatat aplikasi.</p><div className="event-list">{Object.entries(overview.events).length ? Object.entries(overview.events).map(([name, count]) => <p key={name}><span>{eventLabels[name] ?? name.replaceAll('_', ' ')}</span><strong>{count}</strong></p>) : <p>Belum ada event privat yang masuk.</p>}</div></article></section>
      <section className="panel feedback-panel"><div className="section-heading"><div><h2>Masukan pengguna</h2><p>{filteredFeedback.length} dari {feedback.length} masukan ditampilkan</p></div><div className="feedback-filters"><label><span className="sr-only">Cari masukan</span><input type="search" value={feedbackQuery} onChange={(event) => setFeedbackQuery(event.target.value)} placeholder="Cari isi atau kategori…"/></label><label><span className="sr-only">Filter status</span><select value={feedbackStatus} onChange={(event) => setFeedbackStatus(event.target.value)}><option value="open">Belum selesai</option><option value="resolved">Selesai</option><option value="all">Semua status</option></select></label></div></div>{filteredFeedback.length ? <div className="feedback">{filteredFeedback.map((item) => <article key={item.id}><div><span className={`badge ${item.status}`}>{item.status === 'resolved' ? 'Selesai' : 'Baru'}</span><strong>{item.category}</strong><small>{new Date(item.created_at).toLocaleString('id-ID')} · v{item.app_version ?? '—'}</small><p>{item.message}</p></div>{item.status !== 'resolved' && <button className="ghost" disabled={Boolean(busyAction)} onClick={() => void resolveFeedback(item.id)}>{busyAction === `feedback:${item.id}` ? 'Menyimpan…' : 'Tandai selesai'}</button>}</article>)}</div> : <div className="empty-state"><strong>Tidak ada masukan yang cocok.</strong><p>Ubah pencarian atau filter status untuk melihat data lain.</p></div>}</section>
      <p className="config-count">{config.length} konfigurasi jarak jauh dimuat.</p>
    </>}
  </main>
}
