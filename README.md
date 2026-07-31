# Ngelamar App (v1.5.2)

Aplikasi Personal Career CRM dan Penglacak Lamaran Kerja dengan Desain Modern Berstandar Apple iOS Human Interface Guidelines (HIG).

Dikembangkan oleh **idka-solutions team**.

---

## Fitur Utama

1. **Dashboard & Ringkasan Progres**
   - Salam pembuka dinamis sesuai waktu lokal dan nama pengguna.
   - Ringkasan statistik lamaran aktif (Total, Dikirim, Interview & Tes, Offering).
   - Indikator Response Rate HRD dalam bentuk persentase.
   - Smart Auto-Fill CTA untuk mengisi form otomatis dari teks loker.

2. **Manajemen Lamaran Kerja (Lamaran)**
   - Pencarian cepat posisi, nama perusahaan, dan lokasi.
   - Filter chip cepat untuk pekerjaan favorit dan WFH.
   - Tab navigasi kategori status (Semua, Dikirim, Interview & Tes, Offering, Diterima, Ditolak).
   - Tampilan tab dinamis dengan ikon dan jumlah lamaran.

3. **Detail Lamaran Lengkap**
   - Informasi detail status, tanggal melamar, tipe kerja, lokasi, sumber loker, dan ekspektasi gaji.
   - Jadwal interview dan pengingat otomatis.
   - Kontak HRD dengan tombol pintas Follow-Up.
   - Cheat-Sheet Interview: Penilaian skill otomatis dan rekomendasi jawaban pertanyaan wawancara.
   - Follow-Up Generator: Template pesan WhatsApp / Email untuk follow-up ke HRD.
   - Evaluator Gaji & UMR: Perhitungan kelayakan gaji terhadap UMR kota dan biaya hidup.

4. **Pengaturan & Kustomisasi (Settings)**
   - Mode Gelap (Dark Mode) dan Mode Terang (Light Mode) khas Apple iOS.
   - Edit profil dan nama pengguna.
   - Ekspor laporan ringkasan teks ke WhatsApp atau Catatan.
   - Cadangkan data dalam format JSON (Backup & Restore).
   - Informasi aplikasi dan pengembang.

---

## Teknologi yang Digunakan

- **Framework:** Flutter (Dart)
- **State Management:** Flutter Riverpod
- **Local Database:** Hive / Hive Flutter
- **Penyimpanan Preferensi:** SharedPreferences
- **Desain UI/UX:** Apple iOS 18 HIG Design System

---

## Langkah Menjalankan Aplikasi

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
