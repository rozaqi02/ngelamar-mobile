# Ngelamar App (v1.7.4)

Aplikasi Personal Career CRM dan Pelacak Lamaran Kerja dengan Desain Liquid Glass Apple iOS 26, navbar dinamis Apple HIG, dan Hub Persiapan Karir untuk fresh graduate.

Dikembangkan oleh **idka-solutions team**.

---

## Fitur Utama & Keunggulan Unik

### Pembaruan v1.7.4

- Launcher icon kini konsisten dengan logo briefcase biru-indigo pada splash screen.
- Bottom navbar liquid glass lebih responsif, dinamis, dan mempertahankan state setiap tab.
- Reminder interview kini benar-benar dijadwalkan berdasarkan tanggal dan jam.
- Persistence, import, sorting, filter, dan proses simpan dibuat lebih aman.
- Layout utama diperbaiki untuk layar sempit dan ukuran teks aksesibilitas.

1. **Apple iOS 26 Liquid Glass Bottom Navbar**
   - Dual-layer glassmorphic blur (`sigmaX: 35, sigmaY: 35`).
   - Liquid active pill indicator yang meluncur mulus dengan fisika fluida.
   - Specular edge highlight reflection khas curved glass Apple.
   - Responsif terhadap mode gelap dan mode terang.

2. **FITUR UNGGULAN PEMBEDA: Career Flight Deck & AI Readiness Matrix**
   - Scoring AI Readiness Index (0-100%) secara real-time.
   - Rekomendasi otomatis aksi karir (Follow-Up HRD, Evaluator Gaji UMR, Persiapan Interview).
   - Ekspor Laporan Eksekutif Progres Karir 1-tap ke WhatsApp atau Catatan.
   - Perbandingan Penawaran Berdampingan (Side-by-Side Offer Comparison Sheet) jika memiliki 2+ status Offering.

3. **Notifikasi Lokal & Pengingat Interview**
   - Pengingat otomatis jadwal interview via notifikasi lokal HP.
   - Deteksi otomatis lamaran duplikat saat paste atau pengisian form.

4. **AppleToast v2 Floating Dynamic Capsule**
   - Notifikasi kapsul melayang di bagian bawah layar di atas navbar.
   - Mendukung sistem antrian pesan statis untuk mencegah penumpukan toast.
   - Dilengkapi tombol aksi interaktif (misal: "Lihat", "Kirim WA").

5. **Dashboard & Ringkasan Progres**
   - Salam pembuka dinamis sesuai waktu lokal dan nama pengguna.
   - Ringkasan statistik lamaran aktif (Total, Dikirim, Interview & Tes, Offering).
   - Indikator Response Rate HRD dalam bentuk persentase.
   - Smart Auto-Fill CTA untuk mengisi form otomatis dari teks loker.
   - Dialog opsional untuk memuat contoh data lamaran saat pertama kali digunakan.

6. **Manajemen Lamaran Kerja Overhauled**
   - Pinned Cupertino Search Header dengan filter teks langsung.
   - Monogram Avatar Perusahaan otomatis dengan gradien dinamis.
   - Consolidated Apple Pill Status & Quick Filter Bar.
   - Grouped Card layout dengan indikator status dot dan badge lokasi/tipe kerja.

7. **Detail Lamaran, Skill Gap Checklist & Cheat-Sheet Interview**
   - Informasi detail status, tanggal melamar, tipe kerja, lokasi, sumber loker, dan ekspektasi gaji.
   - Interactive Skill Gap Checklist untuk persiapan interview.
   - Cheat-Sheet Interview & Follow-Up Generator ke HRD.
   - Evaluator Gaji & UMR Kota.

---

## Privasi & Keamanan Data

- **100% Lokal:** Seluruh data lamaran kerja tersimpan secara aman di dalam penyimpanan lokal perangkat Anda (Hive Local Database).
- **Tanpa Akun:** Tidak memerlukan registrasi, login, atau pembuatan akun.
- **Tanpa Server Luar:** Data Anda tidak pernah dikirim ke server pihak ketiga manapun.

---

## Cara Menginstall File APK (`Ngelamar.apk`)

1. Unduh file `Ngelamar.apk` yang berada di root repository ini ke perangkat Android Anda.
2. Buka file `Ngelamar.apk` melalui Pengelola File (File Manager).
3. Jika muncul peringatan keamanan, aktifkan opsi **"Izin dari sumber ini"** atau **"Install aplikasi dari sumber tidak dikenal"** di Pengaturan HP Anda.
4. Tekan **Install** dan tunggu hingga proses selesai.
5. Aplikasi **Ngelamar** siap digunakan!

---

## Teknologi yang Digunakan

- **Framework:** Flutter (Dart)
- **State Management:** Flutter Riverpod
- **Local Database:** Hive / Hive Flutter
- **Penyimpanan Preferensi:** SharedPreferences
- **Notifikasi Lokal:** Flutter Local Notifications
- **Desain UI/UX:** Apple iOS 26 Liquid Glass Design System

---

## Langkah Menjalankan Aplikasi (Developer)

1. Pastikan Flutter SDK telah terinstall di komputer Anda.
2. Clone repository ini:
   ```bash
   git clone https://github.com/rozaqi02/ngelamar-mobile.git
   cd app-mobile-loker
   ```
3. Unduh dependencies:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## Hak Cipta

(c) 2024 idka-solutions team. Seluruh hak cipta dilindungi undang-undang.
