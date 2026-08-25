# Setup Supabase untuk Ngelamar Cloud & PRO

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

## 2. Buat tabel, RLS, dan RPC PRO

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

## 5. Aktifkan platform cloud, admin, dan Storage privat

Jalankan seluruh isi migration berikut setelah dua migration sebelumnya:

```text
supabase/migrations/202608230003_cloud_admin_platform.sql
```

Migration ini membuat profile akun, backup cloud terenkripsi, CV privat,
preferensi/cloud templates, event analitik privat, remote config, feedback,
inbox notifikasi, referral, audit admin, serta bucket Storage privat:

- `cloud-backups`: ZIP backup yang sudah dienkripsi oleh aplikasi sebelum
  diunggah. Kata sandi tidak pernah disimpan server.
- `user-documents`: CV PDF privat.

Setiap objek Storage harus menggunakan folder awal berupa `auth.uid()`. RLS
memastikan seorang pengguna tidak dapat melihat objek milik UID lain.

## 6. Terapkan penguatan keamanan & pengiriman notifikasi

Jalankan migration berikut setelah migration cloud platform:

```text
supabase/migrations/202608250004_security_and_delivery_hardening.sql
```

Migration ini membuat kuota AI atomik per pengguna/hari, membatasi ukuran
konteks feedback, dan menambahkan kunci pengiriman unik untuk notifikasi
mingguan. Pastikan migration ini sudah diterapkan **sebelum** men-deploy ulang
Edge Function `career-ai` dan `weekly-digest`.

## 7. Aktifkan Google Sign-In

1. Buka **Google Cloud Console → Google Auth Platform → Clients**.
2. Buat OAuth Client bertipe **Web application**.
3. Pada **Authorized redirect URIs**, masukkan callback yang terlihat pada
   Supabase Dashboard → Authentication → Providers → Google. Untuk proyek ini
   formatnya adalah:

   ```text
   https://jfmmfnfxofodmallkmsq.supabase.co/auth/v1/callback
   ```

4. Salin Client ID dan Client Secret ke provider Google di Supabase lalu
   aktifkan provider tersebut.
5. Di Supabase **Authentication → URL Configuration → Redirect URLs**, tambah:

   ```text
   ngelamar://auth/callback
   http://localhost:3000
   https://URL_DASHBOARD_VERCEL_ANDA
   ```

6. Android dan iOS aplikasi sudah memiliki deep link `ngelamar://auth/callback`.
   Pengguna anonim akan *link* ke Google sehingga UID, PRO, dan backupnya
   tetap sama.

## 8. Deploy dashboard admin Vercel

Ikuti [panduan dashboard admin](../admin-web/README.md). Environment variable
`SUPABASE_SERVICE_ROLE_KEY` hanya untuk Vercel server. Jangan menambahkannya ke
Flutter, GitHub Actions yang tidak terlindungi, atau aplikasi klien.

## 9. Aktifkan tugas server (opsional)

Deploy function berikut melalui Supabase CLI:

```bash
supabase functions deploy weekly-digest --no-verify-jwt
supabase functions deploy career-ai
supabase secrets set CRON_SECRET=<secret-acak>
supabase secrets set OPENAI_API_KEY=<api-key-anda>
```

Untuk `weekly-digest`, buat schedule `pg_cron` yang memanggil function dan
mengirim header `x-cron-secret`. Untuk `career-ai`, set juga `OPENAI_MODEL`
jika ingin menggunakan model selain default. Jangan deploy fitur AI sebelum
Anda siap menanggung biaya API dan menyampaikan persetujuan pengiriman konteks
karier kepada pengguna.

## 10. Aktifkan push notification Android (Supabase + FCM)

Sistem ini memakai Supabase sebagai sumber data notifikasi dan FCM hanya
sebagai kurir ke Android. File private key Firebase **tidak** disimpan di
repository maupun APK.

1. Di SQL Editor Supabase, jalankan:

   ```text
   supabase/migrations/202608250005_push_notifications.sql
   ```

   Ini membuat tabel aman `device_push_tokens`. Aplikasi otomatis menyimpan
   token perangkat untuk sesi pengguna yang sedang aktif saat pertama dibuka.

2. Pastikan secret `FCM_SERVICE_ACCOUNT_JSON` sudah berisi keseluruhan JSON
   service account Firebase. Secret ini hanya dibaca oleh Edge Function.

3. Deploy Edge Function:

   ```bash
   supabase functions deploy push-notification --no-verify-jwt
   ```

   Tanpa terminal, buka **Edge Functions → Deploy a new function → Via
   Editor**, beri nama `push-notification`, lalu salin isi file
   `supabase/functions/push-notification/index.ts`. Pada pengaturan function,
   nonaktifkan **Verify JWT** sebelum menekan **Deploy function**. Keamanan
   tetap ada karena kode function memverifikasi secret key dari webhook.

4. Di **Supabase Dashboard → Database → Webhooks**, buat webhook baru:

   - Table: `public.notification_inbox`
   - Event: `Insert`
   - Type: **Supabase Edge Function**
   - Function: `push-notification`
   - Method: `POST`
   - HTTP Headers: pilih **Add auth header with service key** dan biarkan
     `Content-Type: application/json`.

   Header tersebut mengizinkan webhook internal memanggil function; function
   tidak menerima panggilan anonim. Setiap baris inbox yang dimasukkan lewat
   dashboard admin akan langsung dikirim ke perangkat Android yang terdaftar.

5. Pasang atau jalankan aplikasi di Android, buka sekali saat internet aktif,
   lalu kirim satu notifikasi dari dashboard admin. Token akan ada di
   `device_push_tokens` dan pesan harus tetap sampai ketika aplikasi berada di
   background. Android tetap tidak mengizinkan delivery setelah aplikasi di
   **Force stop**; buka aplikasinya sekali lagi setelah force stop.

Token yang FCM tandai sudah tidak berlaku akan dihapus otomatis. Untuk pesan
siaran, function mengirim ke maksimal 1.000 perangkat aktif pada satu event.

## 11. Uji alur

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
