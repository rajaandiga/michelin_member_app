# Michelin Member App (Flutter)

Aplikasi member untuk usaha ban Michelin. Dibuat dengan Flutter dan Supabase.

Versi yang dipakai saat aplikasi dibuat:
Flutter 3.38.9 (channel stable), Dart 3.10.8

## Yang perlu dipasang dulu
1. Flutter SDK (https://docs.flutter.dev/get-started/install)
2. Android Studio, lalu pasang plugin Flutter dan Dart
   (File > Settings > Plugins)
3. Android SDK dan satu emulator
   (Android Studio > Device Manager > Create Device)
4. Git (kalau mau clone dari GitHub)

## Cek instalasi
Buka terminal, jalankan:

    flutter doctor

Pastikan bagian Flutter dan Android toolchain bertanda centang.
Kalau ada lisensi Android yang belum disetujui, jalankan:

    flutter doctor --android-licenses

## Membuka proyek
1. Download ZIP dari GitHub, lalu extract
   (atau: git clone https://github.com/rajaandiga/michelin_member_app.git)
2. Buka Android Studio > File > Open > pilih folder michelin_member_app
3. Tunggu proses indexing selesai
4. Buka terminal di Android Studio, jalankan:

       flutter pub get

## Menyiapkan database (Supabase)
Aplikasi ini memakai Supabase sebagai database dan login. Siapkan proyek Supabase sendiri:

1. Daftar di https://supabase.com, lalu klik New project. Tunggu sampai selesai dibuat.
2. Buka SQL Editor > New query. Buka file database.sql dari repo ini, salin seluruh isinya,
   tempel di SQL Editor, lalu klik Run. File ini membuat tabel, fungsi, aturan akses,
   dan data awal (produk dan voucher).
3. Buka Project Settings > API. Salin dua nilai ini:
   - Project URL
   - anon public key
4. Di Android Studio, cari tulisan Supabase.initialize di folder lib
   (tekan Ctrl+Shift+F lalu ketik Supabase.initialize).
   Ganti nilai url dan anonKey dengan dua nilai dari langkah 3.
5. Buka Authentication > Sign In / Providers > Email.
   Matikan Confirm email supaya pendaftaran akun langsung bisa dipakai.

## Menjadikan satu akun sebagai admin
1. Jalankan aplikasi, lalu daftar satu akun baru lewat halaman daftar.
2. Di SQL Editor Supabase, jalankan (ganti emailnya dengan email akun tadi):

       update public.profiles set role = 'admin'
        where id = (select id from auth.users where email = 'email_kamu@contoh.com');

3. Keluar dari aplikasi lalu masuk lagi. Akun itu sekarang punya akses admin.

## Menjalankan aplikasi
1. Nyalakan emulator dari Device Manager
   (atau colok HP Android dengan USB debugging aktif)
2. Pilih perangkat di bagian atas Android Studio
3. Klik tombol Run (segitiga hijau) atau jalankan:

       flutter run

## Kalau ada error
- Error versi Gradle atau SDK: ikuti saran perbaikan yang muncul
  di Android Studio, lalu jalankan flutter clean dan flutter pub get
- Error package: pastikan sudah flutter pub get dan ada internet
- Build pertama biasanya lama (5 sampai 15 menit), tunggu saja
- Login atau data tidak muncul: cek lagi Project URL dan anon key di kode,
  dan pastikan database.sql sudah dijalankan tanpa error
- Error saat menjalankan database.sql: pastikan proyek Supabase masih baru dan kosong,
  lalu jalankan file itu sekali saja
