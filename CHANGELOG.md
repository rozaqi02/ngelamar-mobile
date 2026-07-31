# Changelog

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
