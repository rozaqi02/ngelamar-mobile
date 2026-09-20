# Ngelamar Admin Web

Dashboard admin privat untuk mengelola metrik penggunaan, kode PRO, remote
config, pengumuman inbox, dan masukan pengguna. Proyek ini dibuat untuk
**Vercel**; aplikasi Flutter tidak pernah menerima `service_role key`.

## Jalankan lokal

```bash
cd admin-web
copy .env.example .env.local
npm install
npm run dev
```

Isi `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://jfmmfnfxofodmallkmsq.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<publishable-or-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key-rahasia>
CRON_SECRET=<string-acak-panjang>
```

`SUPABASE_SERVICE_ROLE_KEY` hanya boleh berada di environment server Vercel,
tidak boleh dimasukkan ke APK, Git, atau variabel yang berawalan
`NEXT_PUBLIC_`. Buat `CRON_SECRET` berupa string acak minimal 32 karakter.

## Deploy ke Vercel

1. Push repo ini ke GitHub.
2. Di Vercel pilih **Add New → Project** lalu impor repo `ngelamar-mobile`.
3. Pada **Root Directory**, pilih `admin-web`.
4. Tambahkan empat environment variable di atas untuk **Production**,
   **Preview**, dan **Development** sesuai kebutuhan.
5. Deploy. Tambahkan URL Vercel, misalnya
   `https://ngelamar-admin.vercel.app`, ke **Supabase Auth → URL
   Configuration → Redirect URLs**.
6. Login Google ke dashboard sekali, salin UUID pengguna dari Supabase
   Authentication, lalu jalankan pada SQL Editor:

   ```sql
   insert into public.admin_users (user_id, role)
   values ('UUID_ADMIN_ANDA', 'owner')
   on conflict (user_id) do update set role = excluded.role;
   ```

Tanpa langkah terakhir, akun dapat login ke Google tetapi tetap ditolak dari
dashboard—ini disengaja.

## Menjaga Supabase Free tetap aktif

Vercel Cron memanggil `/api/cron/keepalive` setiap hari pukul 09.17 WIB. Route
ini menjalankan satu query `SELECT` ringan ke tabel `admin_users`, sehingga
proyek tetap memiliki aktivitas database tanpa membuat atau mengubah data.

Vercel otomatis mengirim header `Authorization: Bearer <CRON_SECRET>` pada
request cron. Endpoint menolak request tanpa secret yang sesuai. Setelah
deploy, periksa **Vercel → Project → Settings → Cron Jobs** dan **Logs** untuk
memastikan eksekusi mendapat respons HTTP 200.

## Fitur

- Metrik total pengguna, DAU/WAU/MAU, PRO aktif, dan feedback baru.
- Pembuatan kode PRO secara server-side. Kode mentah hanya muncul sekali.
- Remote announcement untuk aplikasi.
- Pengumuman ke inbox aplikasi.
- Review dan penandaan feedback selesai.
- Audit log setiap aksi administrasi di `admin_audit_logs`.
