'use client'

import { FormEvent, useEffect, useMemo, useState } from 'react'
import { isSupabaseBrowserConfigured, supabaseBrowser } from '@/lib/supabase-browser'

type Overview = {
  metrics: { totalUsers: number; dau: number; wau: number; mau: number; activePro: number; newFeedback: number }
  events: Record<string, number>
}
type Feedback = { id: string; category: string; message: string; app_version: string | null; status: string; created_at: string }
type RemoteConfig = { key: string; value: Record<string, unknown>; description: string | null; is_enabled: boolean }
type InboxNotification = {
  id: string
  user_id: string | null
  title: string
  body: string
  type: 'announcement' | 'pro' | 'reminder' | 'system'
  action_url: string | null
  created_at: string
}
type AnnouncementHistoryItem = {
  id: string
  title: string
  message: string
  action_url?: string
  created_at: string
  is_active: boolean
}
type BusyAction = 'load' | 'code' | 'announcement' | 'deactivate_announcement' | 'broadcast' | `edit_inbox:${string}` | `del_inbox:${string}` | `feedback:${string}` | null

const eventLabels: Record<string, string> = {
  app_open: 'Aplikasi dibuka',
  feedback_submitted: 'Masukan dikirim',
  pro_activated: 'PRO diaktifkan',
  job_created: 'Lamaran ditambahkan',
  job_status_updated: 'Status lamaran diperbarui',
}

const typeLabels: Record<string, string> = {
  announcement: 'Pengumuman',
  pro: 'Info PRO',
  reminder: 'Pengingat',
  system: 'Sistem',
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
  const [inboxList, setInboxList] = useState<InboxNotification[]>([])
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [busyAction, setBusyAction] = useState<BusyAction>(null)

  // PRO Code State
  const [code, setCode] = useState('')
  const [plan, setPlan] = useState('monthly')

  // Announcement State
  const [announcementTitle, setAnnouncementTitle] = useState('')
  const [announcementMessage, setAnnouncementMessage] = useState('')
  const [announcementUrl, setAnnouncementUrl] = useState('')
  const [isAnnouncementActive, setIsAnnouncementActive] = useState(false)
  const [announcementHistory, setAnnouncementHistory] = useState<AnnouncementHistoryItem[]>([])

  // Inbox Broadcast / Edit State
  const [editingInboxId, setEditingInboxId] = useState<string | null>(null)
  const [broadcastTitle, setBroadcastTitle] = useState('')
  const [broadcastMessage, setBroadcastMessage] = useState('')
  const [broadcastType, setBroadcastType] = useState<'announcement' | 'pro' | 'reminder' | 'system'>('announcement')
  const [broadcastUrl, setBroadcastUrl] = useState('')

  // Feedback filter state
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
      const [dashboard, feedbackResponse, configResponse, inboxResponse] = await Promise.all([
        adminFetch<Overview>('/api/admin/overview'),
        adminFetch<{ feedback: Feedback[] }>('/api/admin/feedback'),
        adminFetch<{ config: RemoteConfig[] }>('/api/admin/config'),
        adminFetch<{ notifications: InboxNotification[] }>('/api/admin/notifications'),
      ])
      setOverview(dashboard)
      setFeedback(feedbackResponse.feedback)
      setConfig(configResponse.config)
      setInboxList(inboxResponse.notifications)

      const announcementConfig = configResponse.config.find((item) => item.key === 'app_announcement')?.value
      if (announcementConfig && typeof announcementConfig === 'object') {
        const enabled = announcementConfig.enabled === true
        const title = typeof announcementConfig.title === 'string' ? announcementConfig.title : ''
        const message = typeof announcementConfig.message === 'string' ? announcementConfig.message : ''
        const actionUrl = typeof announcementConfig.action_url === 'string' ? announcementConfig.action_url : ''
        setIsAnnouncementActive(enabled && Boolean(title && message))
        setAnnouncementTitle(title)
        setAnnouncementMessage(message)
        setAnnouncementUrl(actionUrl)

        const rawHistory = Array.isArray(announcementConfig.history) ? announcementConfig.history : []
        setAnnouncementHistory(rawHistory as AnnouncementHistoryItem[])
      } else {
        setIsAnnouncementActive(false)
        setAnnouncementTitle('')
        setAnnouncementMessage('')
        setAnnouncementUrl('')
        setAnnouncementHistory([])
      }
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
        setInboxList([])
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

  // --- ANNOUNCEMENT (CRUD & HISTORY) ---
  const saveAnnouncement = async (event: FormEvent) => {
    event.preventDefault()
    setBusyAction('announcement'); clearMessages()
    const title = announcementTitle.trim()
    const message = announcementMessage.trim()
    const actionUrl = announcementUrl.trim()
    const isActivating = Boolean(title && message)

    try {
      let updatedHistory = [...announcementHistory]
      if (isActivating) {
        const newItem: AnnouncementHistoryItem = {
          id: String(Date.now()),
          title,
          message,
          action_url: actionUrl,
          created_at: new Date().toISOString(),
          is_active: true,
        }
        updatedHistory = [newItem, ...updatedHistory.filter((h) => h.title !== title || h.message !== message)].slice(0, 20)
      } else {
        updatedHistory = updatedHistory.map((h) => ({ ...h, is_active: false }))
      }

      await adminFetch('/api/admin/config', {
        method: 'PUT',
        body: JSON.stringify({
          key: 'app_announcement',
          description: 'Pengumuman yang tampil di aplikasi',
          isEnabled: true,
          value: {
            enabled: isActivating,
            title,
            message,
            action_url: actionUrl,
            history: updatedHistory,
          },
        }),
      })

      setIsAnnouncementActive(isActivating)
      setAnnouncementHistory(updatedHistory)
      setNotice(isActivating ? 'Pengumuman aplikasi berhasil disimpan dan diaktifkan.' : 'Pengumuman aplikasi dinonaktifkan.')
      await load()
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Pengumuman gagal disimpan.')
    } finally {
      setBusyAction(null)
    }
  }

  const deactivateAnnouncement = async () => {
    const confirmed = window.confirm('Nonaktifkan pengumuman aplikasi sekarang? Pengumuman tidak akan tampil di aplikasi.')
    if (!confirmed) return
    setBusyAction('deactivate_announcement'); clearMessages()
    try {
      const updatedHistory = announcementHistory.map((h) => ({ ...h, is_active: false }))
      await adminFetch('/api/admin/config', {
        method: 'PUT',
        body: JSON.stringify({
          key: 'app_announcement',
          description: 'Pengumuman yang tampil di aplikasi',
          isEnabled: true,
          value: {
            enabled: false,
            title: '',
            message: '',
            action_url: '',
            history: updatedHistory,
          },
        }),
      })
      setIsAnnouncementActive(false)
      setAnnouncementTitle('')
      setAnnouncementMessage('')
      setAnnouncementUrl('')
      setAnnouncementHistory(updatedHistory)
      setNotice('Pengumuman aplikasi berhasil dinonaktifkan.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Gagal menonaktifkan pengumuman.')
    } finally {
      setBusyAction(null)
    }
  }

  const activateHistoryItem = async (item: AnnouncementHistoryItem) => {
    setAnnouncementTitle(item.title)
    setAnnouncementMessage(item.message)
    setAnnouncementUrl(item.action_url ?? '')
    setBusyAction('announcement'); clearMessages()
    try {
      const updatedHistory = [
        { ...item, is_active: true, created_at: new Date().toISOString() },
        ...announcementHistory.filter((h) => h.id !== item.id),
      ].slice(0, 20)

      await adminFetch('/api/admin/config', {
        method: 'PUT',
        body: JSON.stringify({
          key: 'app_announcement',
          description: 'Pengumuman yang tampil di aplikasi',
          isEnabled: true,
          value: {
            enabled: true,
            title: item.title,
            message: item.message,
            action_url: item.action_url ?? '',
            history: updatedHistory,
          },
        }),
      })
      setIsAnnouncementActive(true)
      setAnnouncementHistory(updatedHistory)
      setNotice(`Pengumuman "${item.title}" berhasil diaktifkan kembali.`)
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Gagal mengaktifkan pengumuman riwayat.')
    } finally {
      setBusyAction(null)
    }
  }

  const deleteHistoryItem = async (id: string) => {
    const confirmed = window.confirm('Hapus item ini dari riwayat pengumuman?')
    if (!confirmed) return
    setBusyAction('announcement'); clearMessages()
    try {
      const updatedHistory = announcementHistory.filter((h) => h.id !== id)
      await adminFetch('/api/admin/config', {
        method: 'PUT',
        body: JSON.stringify({
          key: 'app_announcement',
          description: 'Pengumuman yang tampil di aplikasi',
          isEnabled: true,
          value: {
            enabled: isAnnouncementActive,
            title: announcementTitle,
            message: announcementMessage,
            action_url: announcementUrl,
            history: updatedHistory,
          },
        }),
      })
      setAnnouncementHistory(updatedHistory)
      setNotice('Item berhasil dihapus dari riwayat pengumuman.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Gagal menghapus riwayat.')
    } finally {
      setBusyAction(null)
    }
  }

  // --- KOTAK MASUK / INBOX (CRUD & HISTORY) ---
  const saveInboxNotification = async (event: FormEvent) => {
    event.preventDefault()
    clearMessages()
    const title = broadcastTitle.trim()
    const message = broadcastMessage.trim()
    const type = broadcastType
    const actionUrl = broadcastUrl.trim()

    if (editingInboxId) {
      // UPDATE EXISTING
      setBusyAction(`edit_inbox:${editingInboxId}`)
      try {
        const res = await adminFetch<{ notification: InboxNotification }>('/api/admin/notifications', {
          method: 'PATCH',
          body: JSON.stringify({ id: editingInboxId, title, message, type, actionUrl }),
        })
        setInboxList((prev) => prev.map((item) => (item.id === editingInboxId ? res.notification : item)))
        setEditingInboxId(null)
        setBroadcastTitle('')
        setBroadcastMessage('')
        setBroadcastUrl('')
        setBroadcastType('announcement')
        setNotice('Pesan kotak masuk berhasil diperbarui.')
      } catch (requestError) {
        setError(requestError instanceof Error ? requestError.message : 'Pesan gagal diperbarui.')
      } finally {
        setBusyAction(null)
      }
    } else {
      // CREATE / BROADCAST NEW
      const confirmed = window.confirm(`Kirim "${title}" ke kotak masuk seluruh pengguna? Pesan akan tersimpan di database.`)
      if (!confirmed) return
      setBusyAction('broadcast')
      try {
        const res = await adminFetch<{ notification: InboxNotification }>('/api/admin/notifications', {
          method: 'POST',
          body: JSON.stringify({ title, message, type, actionUrl }),
        })
        setInboxList((prev) => [res.notification, ...prev])
        setBroadcastTitle('')
        setBroadcastMessage('')
        setBroadcastUrl('')
        setBroadcastType('announcement')
        setNotice('Pesan baru berhasil dikirim ke kotak masuk seluruh pengguna.')
      } catch (requestError) {
        setError(requestError instanceof Error ? requestError.message : 'Pesan gagal dikirim.')
      } finally {
        setBusyAction(null)
      }
    }
  }

  const startEditInbox = (item: InboxNotification) => {
    setEditingInboxId(item.id)
    setBroadcastTitle(item.title)
    setBroadcastMessage(item.body)
    setBroadcastType(item.type)
    setBroadcastUrl(item.action_url ?? '')
    window.scrollTo({ top: 500, behavior: 'smooth' })
  }

  const cancelEditInbox = () => {
    setEditingInboxId(null)
    setBroadcastTitle('')
    setBroadcastMessage('')
    setBroadcastUrl('')
    setBroadcastType('announcement')
  }

  const deleteInboxNotification = async (id: string) => {
    const confirmed = window.confirm('Hapus pesan ini dari kotak masuk? Pesan akan terhapus permanen dari aplikasi semua pengguna.')
    if (!confirmed) return
    setBusyAction(`del_inbox:${id}`); clearMessages()
    try {
      await adminFetch(`/api/admin/notifications?id=${encodeURIComponent(id)}`, { method: 'DELETE' })
      setInboxList((prev) => prev.filter((item) => item.id !== id))
      if (editingInboxId === id) cancelEditInbox()
      setNotice('Pesan kotak masuk berhasil dihapus permanen.')
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Pesan gagal dihapus.')
    } finally {
      setBusyAction(null)
    }
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

  return (
    <main className="shell">
      <header>
        <div>
          <p className="eyebrow">NGELAMAR / CONTROL ROOM</p>
          <h1>Halo, {email}</h1>
        </div>
        <div className="header-actions">
          <button className="ghost" onClick={() => void load()} disabled={Boolean(busyAction)}>{isLoading ? 'Memuat…' : 'Muat ulang'}</button>
          <button className="ghost" onClick={() => void supabaseBrowser().auth.signOut()} disabled={Boolean(busyAction)}>Keluar</button>
        </div>
      </header>

      <div className="status-region" aria-live="polite" aria-atomic="true">
        {error && <p className="error" role="alert">{error}</p>}
        {notice && <p className="notice">{notice}</p>}
      </div>

      {!overview ? (
        <section className="loading-state" aria-live="polite">
          <span className="spinner"/>
          <div><strong>Memuat control room</strong><p>Memeriksa izin admin dan mengambil data terbaru…</p></div>
        </section>
      ) : (
        <>
          {/* 1. METRICS */}
          <section className="metrics" aria-label="Ringkasan pengguna">
            {[
              ['Pengguna total', overview.metrics.totalUsers],
              ['Aktif 24 jam', overview.metrics.dau],
              ['Aktif 7 hari', overview.metrics.wau],
              ['Aktif 30 hari', overview.metrics.mau],
              ['PRO aktif', overview.metrics.activePro],
              ['Masukan baru', overview.metrics.newFeedback],
            ].map(([label, value]) => (
              <article key={String(label)}>
                <span>{label}</span>
                <strong>{value}</strong>
              </article>
            ))}
          </section>

          {/* 2. TOP GRID: KODE PRO & PENGUMUMAN APLIKASI */}
          <section className="grid two">
            {/* Panel Buat Kode PRO */}
            <article className="panel">
              <h2>Buat kode PRO</h2>
              <p>Kode angka 10 digit, sekali pakai, dan hanya ditampilkan sekali.</p>
              <form onSubmit={createCode}>
                <label>
                  Paket
                  <select value={plan} onChange={(event) => setPlan(event.target.value)}>
                    <option value="monthly">Bulanan · 30 hari</option>
                    <option value="yearly">Tahunan · 365 hari</option>
                  </select>
                </label>
                <p className="helper">Durasi mengikuti paket secara otomatis agar masa aktif selalu konsisten.</p>
                <button disabled={Boolean(busyAction)}>{busyAction === 'code' ? 'Membuat…' : 'Buat kode'}</button>
              </form>
              {code && (
                <div className="code" aria-live="polite">
                  <code>{code}</code>
                  <button className="ghost" onClick={() => void copyCode()}>Salin</button>
                </div>
              )}
            </article>

            {/* Panel Pengumuman Aplikasi (CRUD & History) */}
            <article className="panel">
              <div className="card-header-flex">
                <div>
                  <h2>Pengumuman aplikasi</h2>
                  <p>Tampil sebagai banner utama di layar Kabar/Notifikasi aplikasi.</p>
                </div>
                <span className={`badge ${isAnnouncementActive ? 'active' : 'inactive'}`}>
                  {isAnnouncementActive ? 'Aktif di Aplikasi' : 'Nonaktif'}
                </span>
              </div>

              <form onSubmit={saveAnnouncement}>
                <label>
                  Judul <span className="counter">{announcementTitle.length}/80</span>
                  <input
                    value={announcementTitle}
                    onChange={(event) => setAnnouncementTitle(event.target.value)}
                    maxLength={80}
                    placeholder="Contoh: Pembaruan Sistem v2.21"
                    required
                  />
                </label>
                <label>
                  Pesan <span className="counter">{announcementMessage.length}/280</span>
                  <textarea
                    value={announcementMessage}
                    onChange={(event) => setAnnouncementMessage(event.target.value)}
                    maxLength={280}
                    placeholder="Pesan singkat yang akan dibaca pengguna…"
                    required
                  />
                </label>
                <label>
                  Tautan Aksi (Opsional)
                  <input
                    value={announcementUrl}
                    onChange={(event) => setAnnouncementUrl(event.target.value)}
                    placeholder="https://... (opsional)"
                  />
                </label>

                <div className="btn-row">
                  <button disabled={Boolean(busyAction)}>
                    {busyAction === 'announcement' ? 'Menyimpan…' : 'Simpan & Aktifkan'}
                  </button>
                  {isAnnouncementActive && (
                    <button
                      type="button"
                      className="danger"
                      onClick={() => void deactivateAnnouncement()}
                      disabled={Boolean(busyAction)}
                    >
                      {busyAction === 'deactivate_announcement' ? 'Memproses…' : 'Nonaktifkan Pengumuman'}
                    </button>
                  )}
                </div>
              </form>

              {/* Riwayat Pengumuman Aplikasi */}
              {announcementHistory.length > 0 && (
                <div style={{ marginTop: '20px' }}>
                  <div className="section-heading">
                    <strong>Riwayat Pengumuman ({announcementHistory.length})</strong>
                  </div>
                  <div className="history-list">
                    {announcementHistory.map((item) => (
                      <div key={item.id} className="history-item">
                        <div className="history-item-header">
                          <div>
                            <strong>{item.title}</strong>
                            {item.is_active && isAnnouncementActive && (
                              <span className="badge active" style={{ marginLeft: '6px' }}>Sedang Aktif</span>
                            )}
                          </div>
                          <div className="btn-row">
                            <button
                              type="button"
                              className="ghost btn-sm"
                              disabled={Boolean(busyAction)}
                              onClick={() => void activateHistoryItem(item)}
                            >
                              Gunakan
                            </button>
                            <button
                              type="button"
                              className="danger btn-sm"
                              disabled={Boolean(busyAction)}
                              onClick={() => void deleteHistoryItem(item.id)}
                            >
                              Hapus
                            </button>
                          </div>
                        </div>
                        <div className="history-item-content">{item.message}</div>
                        <div className="history-item-footer">
                          <span>{new Date(item.created_at).toLocaleString('id-ID')}</span>
                          {item.action_url && <span>Tautan: {item.action_url}</span>}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </article>
          </section>

          {/* 3. MIDDLE GRID: KIRIM KE KOTAK MASUK (CRUD & HISTORY) & EVENT */}
          <section className="grid two">
            {/* Panel Kotak Masuk (Broadcast CRUD) */}
            <article className="panel">
              <div className="card-header-flex">
                <div>
                  <h2>{editingInboxId ? 'Edit Pesan Kotak Masuk' : 'Kirim ke Kotak Masuk'}</h2>
                  <p>
                    {editingInboxId
                      ? 'Perbarui konten pesan yang sudah terkirim ke database.'
                      : 'Pesan tersimpan di Kotak Masuk aplikasi untuk seluruh pengguna.'}
                  </p>
                </div>
                {editingInboxId && (
                  <span className="badge pro">Mode Edit</span>
                )}
              </div>

              {editingInboxId && (
                <div className="edit-box">
                  <h4>Mengedit Pesan Terkirim</h4>
                  <p style={{ margin: 0, fontSize: '12px', color: '#555' }}>
                    Perubahan akan langsung terupdate pada kotak masuk aplikasi pengguna saat dibuka.
                  </p>
                </div>
              )}

              <form onSubmit={saveInboxNotification}>
                <label>
                  Tipe Pesan
                  <select
                    value={broadcastType}
                    onChange={(event) => setBroadcastType(event.target.value as 'announcement' | 'pro' | 'reminder' | 'system')}
                  >
                    <option value="announcement">Pengumuman Resmi</option>
                    <option value="pro">Info PRO / Langganan</option>
                    <option value="reminder">Pengingat / Tips Karir</option>
                    <option value="system">Pemberitahuan Sistem</option>
                  </select>
                </label>
                <label>
                  Judul <span className="counter">{broadcastTitle.length}/80</span>
                  <input
                    value={broadcastTitle}
                    onChange={(event) => setBroadcastTitle(event.target.value)}
                    maxLength={80}
                    placeholder="Contoh: Fitur Ekspor CV Resmi Rilis"
                    required
                  />
                </label>
                <label>
                  Pesan <span className="counter">{broadcastMessage.length}/1000</span>
                  <textarea
                    value={broadcastMessage}
                    onChange={(event) => setBroadcastMessage(event.target.value)}
                    maxLength={1000}
                    placeholder="Tuliskan isi pesan detail…"
                    required
                  />
                </label>
                <label>
                  Tautan Aksi (Opsional)
                  <input
                    value={broadcastUrl}
                    onChange={(event) => setBroadcastUrl(event.target.value)}
                    placeholder="https://... (opsional)"
                  />
                </label>

                <div className="btn-row">
                  <button disabled={Boolean(busyAction)}>
                    {busyAction === 'broadcast' || (editingInboxId && busyAction === `edit_inbox:${editingInboxId}`)
                      ? 'Menyimpan…'
                      : editingInboxId
                      ? 'Simpan Perubahan'
                      : 'Kirim ke Kotak Masuk'}
                  </button>
                  {editingInboxId && (
                    <button type="button" className="ghost" onClick={cancelEditInbox}>
                      Batal
                    </button>
                  )}
                </div>
              </form>

              {/* Riwayat Kotak Masuk */}
              <div style={{ marginTop: '24px' }}>
                <div className="section-heading">
                  <strong>Riwayat Kotak Masuk ({inboxList.length})</strong>
                </div>
                {inboxList.length === 0 ? (
                  <p style={{ color: '#888', fontSize: '13px', marginTop: '10px' }}>Belum ada pesan terkirim di kotak masuk.</p>
                ) : (
                  <div className="history-list">
                    {inboxList.map((item) => (
                      <div key={item.id} className="history-item">
                        <div className="history-item-header">
                          <div>
                            <span className={`badge ${item.type}`} style={{ marginRight: '6px' }}>
                              {typeLabels[item.type] ?? item.type}
                            </span>
                            <strong>{item.title}</strong>
                          </div>
                          <div className="btn-row">
                            <button
                              type="button"
                              className="ghost btn-sm"
                              disabled={Boolean(busyAction)}
                              onClick={() => startEditInbox(item)}
                            >
                              Edit
                            </button>
                            <button
                              type="button"
                              className="danger btn-sm"
                              disabled={Boolean(busyAction)}
                              onClick={() => void deleteInboxNotification(item.id)}
                            >
                              Hapus
                            </button>
                          </div>
                        </div>
                        <div className="history-item-content">{item.body}</div>
                        <div className="history-item-footer">
                          <span>{new Date(item.created_at).toLocaleString('id-ID')}</span>
                          {item.action_url && <span>Tautan: {item.action_url}</span>}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </article>

            {/* Panel Event Terbaru */}
            <article className="panel">
              <h2>Event terbaru</h2>
              <p>Aktivitas privat yang dicatat aplikasi.</p>
              <div className="event-list">
                {Object.entries(overview.events).length ? (
                  Object.entries(overview.events).map(([name, count]) => (
                    <p key={name}>
                      <span>{eventLabels[name] ?? name.replaceAll('_', ' ')}</span>
                      <strong>{count}</strong>
                    </p>
                  ))
                ) : (
                  <p>Belum ada event privat yang masuk.</p>
                )}
              </div>
            </article>
          </section>

          {/* 4. MASUKAN PENGGUNA */}
          <section className="panel feedback-panel">
            <div className="section-heading">
              <div>
                <h2>Masukan pengguna</h2>
                <p>{filteredFeedback.length} dari {feedback.length} masukan ditampilkan</p>
              </div>
              <div className="feedback-filters">
                <label>
                  <span className="sr-only">Cari masukan</span>
                  <input
                    type="search"
                    value={feedbackQuery}
                    onChange={(event) => setFeedbackQuery(event.target.value)}
                    placeholder="Cari isi atau kategori…"
                  />
                </label>
                <label>
                  <span className="sr-only">Filter status</span>
                  <select value={feedbackStatus} onChange={(event) => setFeedbackStatus(event.target.value)}>
                    <option value="open">Belum selesai</option>
                    <option value="resolved">Selesai</option>
                    <option value="all">Semua status</option>
                  </select>
                </label>
              </div>
            </div>
            {filteredFeedback.length ? (
              <div className="feedback">
                {filteredFeedback.map((item) => (
                  <article key={item.id}>
                    <div>
                      <span className={`badge ${item.status}`}>{item.status === 'resolved' ? 'Selesai' : 'Baru'}</span>
                      <strong>{item.category}</strong>
                      <small>{new Date(item.created_at).toLocaleString('id-ID')} · v{item.app_version ?? '—'}</small>
                      <p>{item.message}</p>
                    </div>
                    {item.status !== 'resolved' && (
                      <button
                        className="ghost"
                        disabled={Boolean(busyAction)}
                        onClick={() => void resolveFeedback(item.id)}
                      >
                        {busyAction === `feedback:${item.id}` ? 'Menyimpan…' : 'Tandai selesai'}
                      </button>
                    )}
                  </article>
                ))}
              </div>
            ) : (
              <div className="empty-state">
                <strong>Tidak ada masukan yang cocok.</strong>
                <p>Ubah pencarian atau filter status untuk melihat data lain.</p>
              </div>
            )}
          </section>
          <p className="config-count">{config.length} konfigurasi jarak jauh dimuat.</p>
        </>
      )}
    </main>
  )
}
