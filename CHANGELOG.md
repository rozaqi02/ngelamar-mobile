# Changelog

## 2.21.0+221 - 2026-08-23

### Added

- Login dan penghubungan akun Google sambil mempertahankan identitas anonim,
  hak PRO, serta data lokal pengguna.
- Backup ZIP terenkripsi, dokumen CV, dan preferensi profil ke Supabase
  Storage/database secara privat per pengguna.
- Inbox pengumuman, feedback pengguna, telemetry privat tanpa isi lamaran,
  serta remote configuration dasar.
- Dashboard admin Next.js terpisah di `admin-web/`, siap dideploy ke Vercel
  untuk metrik, kode PRO, pengumuman, feedback, dan audit tindakan admin.
- Fondasi Supabase RLS, bucket privat, referral, dan Edge Functions untuk
  ringkasan mingguan serta bantuan karier berbasis AI.

### Changed

- Memperbarui versi aplikasi menjadi `2.21.0+221`.

## 1.7.4+174 - 2026-08-01

### Fixed

- Mencegah data duplikat saat import atau memuat sample jobs.
- Menunggu operasi simpan dan hapus selesai sebelum menutup layar.
- Menjaga urutan lamaran tetap konsisten berdasarkan tanggal melamar.
- Menyederhanakan state filter agar kategori tidak saling tertinggal.
- Menangani layout sempit dan teks besar tanpa overflow pada form, card, statistik, dan evaluator gaji.

### Changed

- Memperbarui bottom navbar liquid glass dengan active pill dinamis, haptic feedback, semantics, dan state tab yang persisten.
- Menyamakan launcher icon dengan logo briefcase biru-indigo pada splash screen.
- Membuat form lamaran responsif serta menambahkan state loading dan penanganan kegagalan simpan.
- Memperbarui versi aplikasi menjadi `1.7.4+174`.

### Added

- Reminder interview terjadwal dengan tanggal dan jam, sinkronisasi saat startup, serta pembatalan otomatis.
- Permission dan receiver Android untuk notifikasi terjadwal.
- Test regresi serialisasi data dan ID reminder deterministik.
