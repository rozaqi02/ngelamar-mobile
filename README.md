# 🚀 Ngelamar — Personal Career CRM & Job Application Tracker

<p align="center">
  <img src="assets/images/app_icon.png" width="120" alt="Ngelamar Logo" style="border-radius: 24px;" />
</p>

<p align="center">
  <b>Aplikasi pelacak lamaran kerja cerdas, persiapan karier, dan manajemen interview dalam satu genggaman.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Version-2.28.0-2E7D32?style=for-the-badge" alt="Version" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-000000?style=for-the-badge" alt="Platforms" />
</p>

---

## 📌 Tentang Aplikasi

**Ngelamar** adalah aplikasi *Personal Career CRM* dan *Job Tracker* berbasis *offline-first* yang dirancang untuk membantu para pencari kerja (jobseeker), fresh graduate, maupun profesional dalam mengelola seluruh proses pencarian kerja secara terstruktur, privat, dan efisien.

Dengan Ngelamar, Anda tidak akan lagi melewatkan jadwal interview, lupa status follow-up HRD, atau bingung mengevaluasi penawaran kerja (*offering*).

---

## ✨ Fitur Unggulan

### 1. 📋 Smart Job Tracker & Status Management
- **Manajemen Status Lengkap:** Lacak status lamaran mulai dari *Tersimpan*, *Terkirim*, *Interview & Tes*, *Offering*, hingga *Diterima* atau *Ditolak*.
- **Filter Cepat & Pencarian Real-time:** Filter berdasarkan status, tipe kerja (WFO, WFH, Hybrid), serta pencarian nama posisi dan perusahaan.
- **Deteksi Duplikasi Otomatis:** Mencegah Anda melamar ke posisi atau perusahaan yang sama dua kali tanpa sengaja.

### 2. 🧠 Career Flight Deck & AI Matrix
- **AI Readiness Index (0–100%):** Evaluasi kesiapan lamaran Anda secara real-time berdasarkan kelengkapan berkas dan persiapan interview.
- **Skill Gap Checklist:** Checklist interaktif untuk memetakan skill yang dibutuhkan vs skill yang dimiliki.
- **Evaluator Gaji & UMR:** Bandingkan ekspektasi gaji yang ditawarkan dengan standar UMR wilayah setempat.
- **Offer Comparison Sheet:** Perbandingan berdampingan (*side-by-side*) jika Anda menerima lebih dari satu tawaran kerja.

### 3. 🌐 Career Hub & Portal Discovery
- **Akses Cepat Portal Terkemuka:** Terintegrasi dengan portal loker resmi seperti **LinkedIn, Jobstreet, Glints, Indeed, Kalibrr, dan KitaLulus**.
- **Konfirmasi Aman:** Membuka tautan eksternal secara aman dengan perlindungan privasi.

### 4. ⏰ Pengingat & Notifikasi Terjadwal
- **Local Interview Reminder:** Pengingat otomatis di ponsel Anda untuk jadwal wawancara, tes teknis, atau psikotes.
- **Pusat Kabar (Notification Center):** Rekap seluruh pengingat aktif, tindak lanjut (*follow-up*), dan status aplikasi dalam satu layar.

### 5. 🔒 Privasi, Keamanan & Cloud Sync
- **Offline-First & Local Encrypted:** Seluruh catatan lamaran disimpan lokal di perangkat dengan basis data Hive terenkripsi.
- **Ngelamar Cloud (Opsional):** Cadangkan data terenkripsi dan sinkronisasi preferensi profil secara aman melalui Supabase.
- **Ekspor & Impor ZIP:** Buat cadangan penuh data beserta lampiran dengan perlindungan kata sandi.

---

## 📲 Cara Instalasi

### 🤖 Pengguna Android (.apk)
1. Unduh file **`ngelamar-v2.28.0-release.apk`** yang berada di root repository ini.
2. Buka file APK melalui aplikasi **Pengelola File (File Manager)** ponsel Anda.
3. Jika muncul peringatan keamanan, izinkan **"Install aplikasi dari sumber tidak dikenal"** di Pengaturan.
4. Tekan **Install** dan tunggu hingga selesai.

### 🍏 Pengguna iPhone / iOS (.ipa)
Aplikasi iOS dapat dipasang (*sideloading*) langsung menggunakan PC/Laptop:
1. Unduh artifact **`Ngelamar-iOS-Release.ipa`** dari menu [GitHub Actions Releases / Artifacts](https://github.com/rozaqi02/ngelamar-mobile/actions).
2. Hubungkan iPhone ke Laptop/PC menggunakan kabel data.
3. Buka software **3uTools** (atau AltStore / Sideloadly) di Laptop Windows.
4. Buka menu **Toolbox > IPA Signature**, masukkan file `.ipa` dan login dengan Apple ID gratis Anda.
5. Klik **Install**, lalu di iPhone buka **Pengaturan > Umum > Manajemen Profil/Perangkat** dan pilih **Percayai Pengembang**.

---

## 🛠️ Panduan Developer (Local Setup)

### Prasyarat:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versi stable terbaru `3.22+` / `3.27+`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode / VS Code
- Git

### Langkah Menjalankan Aplikasi:

1. **Clone repository:**
   ```bash
   git clone https://github.com/rozaqi02/ngelamar-mobile.git
   cd ngelamar-mobile
   ```

2. **Pasang dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan pada emulator / perangkat fisik:**
   ```bash
   flutter run
   ```

4. **Build APK Rilis (Android):**
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
   ```

---

## 🏗️ Arsitektur & Teknologi

- **Core Framework:** Flutter (Dart)
- **State Management:** Flutter Riverpod (`StateNotifierProvider`)
- **Local Database:** Hive & Secure Storage (AES encrypted)
- **Backend & Auth:** Supabase (PostgreSQL, Row Level Security, Edge Functions)
- **Push Notification:** Firebase Cloud Messaging (FCM) & Flutter Local Notifications
- **Design System:** Google Material You (Material 3) solid color design

---

## 📄 Lisensi & Hak Cipta

Dikembangkan oleh **idka-solutions team**.  
Seluruh hak cipta dilindungi undang-undang.
