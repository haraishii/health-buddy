# Menjalankan backend Health Buddy di Render

Panduan ini untuk pemilik proyek yang ingin mencoba backend dari pull request (atau dari `main`) tanpa
memasang Go atau PostgreSQL di laptop. Waktu yang dibutuhkan sekitar 20 menit.

```
Aplikasi Flutter (HP / Chrome)  ──HTTPS──▶  Render: API Go (folder backend/)  ──▶  Supabase: PostgreSQL
```

- **Supabase** menyimpan database. Gratis.
- **Render** menjalankan API dari folder `backend/` memakai `Dockerfile` dan `render.yaml` yang sudah ada di repo. Gratis.
- Aplikasi Flutter **tidak** di-deploy ke Render; aplikasi hanya diarahkan ke alamat API di Render.

> Semua data referensi (makanan, MET, AKG, tips, dll.) masih **DUMMY**: angka perkiraan untuk uji coba,
> belum diverifikasi ke sumber resmi. Jangan dipakai untuk pengguna sungguhan sebelum diganti dengan data
> dari paket data tim.

## Yang perlu disiapkan

- Akses ke repo GitHub ini (pemilik repo sudah otomatis punya).
- Akun [Supabase](https://supabase.com) dan akun [Render](https://render.com). Keduanya bisa daftar dengan akun GitHub.
- Untuk mencoba di HP: Flutter SDK di laptop (seperti biasa untuk menjalankan aplikasi).

## Langkah 1: Buat database di Supabase

1. Masuk ke Supabase → **New project**.
2. Isi:
   - **Name**: misalnya `health-buddy`.
   - **Database Password**: buat password yang kuat dan **simpan**, nanti dipakai di langkah 2.
   - **Region**: **Southeast Asia (Singapore)**, supaya dekat dengan server Render dan pengguna di Indonesia.
3. Tunggu sampai project selesai dibuat (sekitar 2 menit).
4. Klik tombol **Connect** di bagian atas dashboard project.
5. Pilih **Session pooler** lalu salin connection string-nya. Bentuknya seperti ini:
   ```
   postgresql://postgres.abcdefghijkl:[YOUR-PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres
   ```
6. Ganti `[YOUR-PASSWORD]` dengan password dari nomor 2, lalu tambahkan di akhir:
   ```
   ?sslmode=require&pool_max_conns=10
   ```
   Hasil akhirnya (contoh):
   ```
   postgresql://postgres.abcdefghijkl:PasswordAnda@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres?sslmode=require&pool_max_conns=10
   ```
   Ini adalah nilai **`DATABASE_URL`**. Jangan ditaruh di repo atau di chat publik.

Catatan penting:

- Gunakan **Session pooler**, bukan "Direct connection". Direct connection hanya bisa diakses lewat IPv6,
  dan Render tidak bisa menjangkaunya (error `network is unreachable`).
- **Jangan membuat tabel lewat SQL Editor Supabase.** Tabel dibuat otomatis oleh backend saat pertama
  kali jalan (langkah 3). Kalau SQL ditempel manual, backend tidak tahu file itu sudah dijalankan dan
  akan error `relation "foods" already exists` (lihat bagian Masalah umum).

## Langkah 2: Buat service di Render

File [`render.yaml`](../render.yaml) di root repo sudah berisi semua pengaturan, jadi cukup beberapa klik.

1. Masuk ke Render → **New** → **Blueprint**.
2. Hubungkan akun GitHub bila diminta, lalu pilih repo **health-buddy**.
3. Pilih **branch** yang ingin dicoba:
   - branch dari pull request (misalnya `erwin`) untuk mencoba **sebelum** merge, atau
   - `main` setelah pull request di-merge.
4. Render membaca `render.yaml` dan menampilkan service **health-buddy-api**. Render akan meminta nilai
   **`DATABASE_URL`**: tempel connection string dari langkah 1.
5. Klik **Apply** / **Deploy Blueprint**.

Yang sudah diatur otomatis oleh `render.yaml`:

| Pengaturan | Nilai | Keterangan |
|---|---|---|
| Root directory | `backend` | Render hanya membangun folder `backend/`. Commit yang hanya mengubah kode Flutter tidak memicu deploy ulang. |
| Region | Singapore | Sama dengan Supabase. |
| Plan | Free | Lihat catatan "server tertidur" di bawah. |
| Health check | `/healthz` | Render memeriksa API dan koneksi database. |
| `JWT_SECRET` | dibuat acak oleh Render | Kunci untuk token login. |
| `SEED_DUMMY_DATA` | `true` | Mengisi data dummy dan 3 akun uji (sekali saja). |
| `ALLOW_DRAFT_LABEL_RULES` | `true` | Label Healthy/High fat memakai aturan draf yang belum disetujui ahli gizi. |

Kalau ingin membuat service tanpa Blueprint: **New → Web Service** → pilih repo → **Language: Docker**,
**Root Directory: `backend`**, **Health Check Path: `/healthz`**, lalu isi environment variables seperti tabel
di atas (`JWT_SECRET` minimal 32 karakter; buat dengan `openssl rand -hex 32`).

## Langkah 3: Tunggu deploy pertama dan cek log

Buka service **health-buddy-api** → tab **Logs**. Deploy pertama memakan sekitar 3–5 menit. Deploy berhasil
bila muncul baris-baris ini:

```
applied migrations/0001_reference_tables.sql
applied migrations/0002_user_tables.sql
applied migrations/0003_enable_rls.sql
applied migrations/0004_app_features.sql
applied seeds/0001_reference_dummy.sql
applied seeds/0002_test_users.sql
applied seeds/0003_coach_dummy.sql
listening on :10000
```

Pada deploy berikutnya baris `applied ...` hanya muncul untuk file migrasi yang baru; file yang sudah pernah
dijalankan dilewati.

Di Supabase (**Table Editor**) sekarang terlihat tabel-tabel seperti `foods`, `users`, `meal_logs`, masing-masing
berlabel **RLS enabled**. RLS sengaja aktif tanpa policy: data hanya bisa dibaca lewat API ini, tidak lewat
REST API Supabase.

## Langkah 4: Coba API-nya

Alamat API terlihat di bagian atas halaman service, misalnya `https://health-buddy-api.onrender.com`.
Ganti alamat di contoh berikut dengan alamat milik Anda.

```bash
# Harus membalas {"status":"ok"}
curl https://health-buddy-api.onrender.com/healthz

# Login dengan akun uji, membalas token dan data user
curl https://health-buddy-api.onrender.com/api/v1/auth/signin \
  -d '{"email":"annida@example.com","password":"password123"}'
```

Akun uji (password semuanya `password123`):

| Email | Skenario |
|---|---|
| `annida@example.com` | Mahasiswa: tidur turun ~1,5 jam di minggu kedua, protein kurang, stres tinggi 3 hari |
| `bima@example.com` | Aktif: olahraga 5–6 hari per minggu, stres lebih rendah di hari olahraga |
| `citra@example.com` | Kurang aktif: langkah sedikit, sering gorengan, kurang minum |

Akun baru juga bisa dibuat langsung dari halaman **Create an account** di aplikasi.

Data log akun uji mencakup 14 hari sampai tanggal deploy pertama. Setelah beberapa hari, grafik "minggu ini"
akan terlihat kosong; itu wajar karena datanya sudah lewat.

## Langkah 5: Jalankan aplikasi Flutter ke API di Render

Di laptop, dari root repo:

```bash
flutter pub get

# Jalankan di HP atau emulator yang terhubung
flutter run --dart-define=API_URL=https://health-buddy-api.onrender.com

# Atau buat APK untuk dibagikan
flutter build apk --release --dart-define=API_URL=https://health-buddy-api.onrender.com
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

Tanpa `--dart-define`, aplikasi mencari API di `http://localhost:8080` (untuk menjalankan backend di laptop).
Pada build debug, halaman login menampilkan kotak "Developer" berisi alamat API yang sedang dipakai dan
tombol cepat untuk mengisi akun uji.

## Memperbarui backend

- **Push ke branch yang dipakai Render** → Render otomatis build dan deploy ulang, asalkan ada perubahan
  di dalam folder `backend/`.
- **Perubahan database** ditulis sebagai file migrasi baru di `backend/db/migrations/` (misalnya
  `0005_....sql`). Saat deploy, backend menjalankan file yang belum pernah dijalankan saja.
- **Jangan mengubah file migrasi yang sudah pernah dijalankan.** Buat file baru untuk setiap perubahan.
- Setiap tabel baru harus diberi `ALTER TABLE nama_tabel ENABLE ROW LEVEL SECURITY;` di migrasinya.

## Sebelum dipakai pengguna sungguhan

1. Ganti data DUMMY dengan data dari paket data tim (makanan, aktivitas, AKG, tips, dan lainnya).
2. Di Render → **Environment**, ubah `SEED_DUMMY_DATA` dan `ALLOW_DRAFT_LABEL_RULES` menjadi `false`
   (atau hapus).
3. Hapus 3 akun uji dari tabel `users` di Supabase. Log mereka ikut terhapus otomatis.
4. Ubah `CORS_ORIGIN` dari `*` ke domain web aplikasi bila nanti ada versi web.
5. Pertimbangkan paket Render berbayar agar server tidak tertidur.

## Masalah umum

| Gejala | Penyebab dan solusi |
|---|---|
| Aplikasi: "Cannot reach the server" atau "took too long", padahal deploy berhasil | Paket Free **tertidur** setelah 15 menit tanpa request; request pertama butuh ±1 menit. Buka `/healthz` di browser, tunggu sampai `ok`, lalu ketuk **Try again** di aplikasi. |
| Aplikasi masih menghubungi `localhost` | Aplikasi dijalankan tanpa `--dart-define=API_URL=...`. Cek alamat di kotak "Developer" pada halaman login. |
| Log Render: `network is unreachable` atau `dial tcp [2406:...]` | `DATABASE_URL` memakai "Direct connection". Ganti ke **Session pooler** (langkah 1). |
| Log Render: `password authentication failed` | Password di `DATABASE_URL` salah, atau `[YOUR-PASSWORD]` belum diganti. Karakter khusus di password (`@`, `#`, `/`, `?`) harus di-encode, misalnya `@` → `%40`. |
| Log Render: `relation "foods" already exists` | Tabel pernah dibuat manual lewat SQL Editor. Lihat penjelasan di bawah tabel ini. |
| Log Render: `JWT_SECRET must be at least 32 characters` | Isi `JWT_SECRET` dengan minimal 32 karakter acak. |
| `/healthz` membalas `database unavailable` | Project Supabase sedang di-pause (paket Free di-pause setelah 1 minggu tidak dipakai). Buka dashboard Supabase dan klik **Restore project**. |
| Deploy tidak berjalan setelah push | Perubahannya di luar folder `backend/` (memang tidak memicu deploy), atau Render memantau branch lain (**Settings → Branch**). |
| Login gagal "Email or password is incorrect" untuk akun uji | Seed belum jalan. Pastikan `SEED_DUMMY_DATA=true` dan log memuat `applied seeds/0002_test_users.sql`. |

**Memperbaiki `relation ... already exists`.** Backend mencatat file yang sudah dijalankan di tabel
`schema_migrations` dan `seed_runs`. Bila tabel sudah ada tetapi catatannya kosong, tandai file yang memang
sudah dijalankan lewat SQL Editor Supabase, lalu deploy ulang. Contoh bila migrasi 0001–0003 dan seed
0001–0002 sudah ditempel manual:

```sql
CREATE TABLE IF NOT EXISTS seed_runs (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE seed_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE schema_migrations ENABLE ROW LEVEL SECURITY;
INSERT INTO schema_migrations (name) VALUES
  ('migrations/0001_reference_tables.sql'), ('migrations/0002_user_tables.sql'), ('migrations/0003_enable_rls.sql');
INSERT INTO seed_runs (name) VALUES ('seeds/0001_reference_dummy.sql'), ('seeds/0002_test_users.sql');
```

Hanya masukkan nama file yang benar-benar sudah dijalankan. Cara termudah bila datanya hanya data uji:
buat project Supabase baru dan ulangi langkah 1–3.

## Biaya

Render Free dan Supabase Free cukup untuk uji coba (Rp0). Batasannya: server Render tertidur saat tidak
dipakai, dan project Supabase di-pause setelah seminggu tidak aktif. Untuk pengguna sungguhan, rencanakan
paket berbayar keduanya.
