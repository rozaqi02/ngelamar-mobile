# Setup Supabase untuk Ngelamar PRO

Implementasi aplikasi memakai **Supabase Anonymous Auth** agar pengguna tidak
perlu membuat akun pada versi awal. Setiap instalasi mendapatkan `auth.uid()`
dan entitlement PRO hanya dapat dibaca oleh pemilik UID tersebut.

## 1. Aktifkan Anonymous Auth

Di Supabase Dashboard buka **Authentication → Providers / Sign In Methods →
Anonymous Sign-Ins**, lalu aktifkan provider tersebut.

Anonymous Auth cocok untuk MVP tanpa layar login, tetapi akses tidak dapat
dipulihkan setelah pengguna menghapus data aplikasi atau pindah perangkat.
Sebelum rilis publik besar, tautkan akun anonim ke email/Google dan aktifkan
CAPTCHA/Turnstile untuk mengurangi penyalahgunaan pembuatan akun anonim.

## 2. Buat tabel, RLS, dan RPC

Buka **SQL Editor → New query**, salin seluruh isi
`supabase/migrations/202608230001_pro_entitlements.sql`, lalu tekan **Run**.

Migration tersebut membuat:

- `pro_activation_codes`: kode tersimpan sebagai hash SHA-256 dan tidak dapat
  dibaca oleh aplikasi.
- `pro_entitlements`: status paket dan masa aktif per `auth.uid()`.
- `pro_activation_attempts`: pembatasan maksimal 10 percobaan per 15 menit.
- RLS: pengguna hanya boleh membaca entitlement miliknya sendiri.
- `activate_pro`: RPC tervalidasi yang mengonsumsi kode satu kali.
- `deactivate_my_pro`: RPC untuk menonaktifkan entitlement milik sendiri.

## 3. Buat kode aktivasi

Jalankan dari SQL Editor. Ganti kode contoh sebelum menjalankannya:

```sql
insert into public.pro_activation_codes (code_hash, plan, duration_days)
values (
  encode(extensions.digest(upper(trim('4829157306')), 'sha256'), 'hex'),
  'monthly',
  30
);
```

Untuk paket tahunan gunakan `plan = 'yearly'` dan `duration_days = 365`.
Kode yang sama default-nya hanya dapat digunakan satu kali.

## 4. Aktifkan statistik pengguna aktif

Buka **SQL Editor → New query**, salin seluruh isi
`supabase/migrations/202608230002_user_activity.sql`, lalu tekan **Run**.
Ini membuat tabel aktivitas yang tidak dapat diakses aplikasi secara langsung.
Aplikasi hanya menjalankan fungsi `mark_user_active()` untuk UID miliknya saat
dibuka atau kembali ke latar depan (maksimal sekali per 5 menit).

Gunakan query ini di SQL Editor untuk melihat angka pengguna:

```sql
select count(*) as total_pengguna
from public.user_activity;

select count(*) as pengguna_aktif_24_jam
from public.user_activity
where last_seen_at > now() - interval '24 hours';

select count(*) as pengguna_aktif_7_hari
from public.user_activity
where last_seen_at > now() - interval '7 days';

select count(*) as pengguna_aktif_30_hari
from public.user_activity
where last_seen_at > now() - interval '30 days';
```

`total_pengguna` berarti instalasi unik yang pernah membuka versi aplikasi ini
setelah migration dipasang. Karena memakai Anonymous Auth, hapus data aplikasi
atau instal ulang akan dihitung sebagai instalasi baru.

## 5. Uji alur

1. Buka halaman PRO dan pilih paket yang sesuai dengan kode.
2. Masukkan kode 10 digit.
3. Pastikan baris baru muncul di `pro_entitlements` dan
   `redemption_count` pada `pro_activation_codes` bertambah.
4. Tutup dan buka kembali aplikasi. PRO harus tetap aktif selama server
   mengembalikan entitlement aktif dan belum kedaluwarsa.
5. Matikan internet atau hapus entitlement. Fitur PRO harus kembali terkunci.

## Catatan keamanan

Anon/publishable key memang digunakan di aplikasi klien dan bukan rahasia.
Keamanan bergantung pada grants, RLS, dan RPC di atas. Jangan pernah memasukkan
`service_role` atau secret key ke source code maupun APK.
