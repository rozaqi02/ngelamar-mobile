# Ngelamar App (v2.20.0)

Aplikasi personal career CRM dan pelacak lamaran kerja yang menggabungkan pencarian portal, persiapan karier, pengingat, CV, dan tracker lamaran dalam satu pengalaman mobile.

Dikembangkan oleh **idka-solutions team**.

---

## Fitur Utama & Keunggulan Unik

### Pembaruan v2.20.0

- **Detail lowongan baru:** Kualifikasi, deskripsi, dan benefit memakai selector tiga kolom yang selalu terlihat tanpa perlu menggeser tab.
- **Bubble informasi presisi:** Gaji, mode kerja, dan tahap memakai satu permukaan serta satu border; bubble yang menyusut selalu berbentuk lingkaran 50×50.
- **Cari Lokerku:** Pencarian portal dan Siapkan Karirmu disatukan dalam Career Hub yang dapat digeser, dengan identitas portal resmi dan konfirmasi sebelum membuka situs eksternal.
- **Lamaran Saya:** Mendukung tampilan grid/list tersimpan, kontrol bookmark–urutan–tampilan yang ringkas, serta filter status yang lebih jelas.
- **Beranda personal:** Foto profil tidak terdistorsi, label minat mengambil pilihan pengguna, dan stacked card mempunyai ruang judul yang lebih lega.
- **Data contoh konsisten:** Tutorial memuat tepat enam lamaran dummy pada kategori `Contoh`; status data panduan dikunci dan seed lama dimigrasikan otomatis.
- **Notifikasi terpusat:** Menu Kabar menampilkan jadwal seleksi, follow-up, status izin, dan pengingat berikutnya.
- **Form lamaran lebih cepat:** Mode Catat Cepat, impor dari teks/tautan, feedback animasi, dan transisi dari tombol tambah ke form.
- **Interaksi yang lebih hidup:** Animasi status, micro-interaction, haptic terpusat, morph route, dan animasi kartu menuju tracker.
- **Profil dan CV:** Bagian Tentang dapat diisi manual dan tombol CV membuka PDF milik pengguna.
- **Backup aman:** Ekspor ZIP terenkripsi dengan konfirmasi dan visibilitas kata sandi serta peringatan bahwa kata sandi tidak dapat dipulihkan.
- **PRO tervalidasi backend:** Entitlement diverifikasi melalui Supabase dan tidak mempercayai status premium lokal.

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

- **Offline-first & terenkripsi:** Catatan lamaran disimpan di perangkat dalam basis data Hive terenkripsi; preferensi profil yang sensitif memakai penyimpanan aman perangkat.
- **Tanpa formulir registrasi:** Aplikasi membuat sesi anonim Supabase untuk identitas instalasi, validasi PRO, dan pencatatan aktivitas minimal.
- **Koneksi terkontrol:** Membuka portal loker atau meminta isi otomatis dari tautan HTTPS akan terhubung ke situs terkait setelah konfirmasi pengguna. Isi lamaran tetap disimpan lokal.
- **Backup & pemulihan:** Anda dapat membuat dan memulihkan cadangan ZIP terenkripsi berisi riwayat serta lampiran. Kata sandi backup tidak disimpan aplikasi; simpan sendiri dengan aman. Backup JSON versi lama masih bisa diimpor, tetapi tidak membawa lampiran.
- **Hapus tuntas:** Menghapus seluruh data juga menghapus lampiran yang dikelola aplikasi.

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
- **Penyimpanan Aman:** Hive terenkripsi, Flutter Secure Storage, dan SharedPreferences untuk preferensi non-sensitif
- **Backend:** Supabase anonymous authentication, RLS, dan RPC untuk validasi entitlement PRO
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
