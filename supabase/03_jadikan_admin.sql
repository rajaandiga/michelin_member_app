-- Jalankan SETELAH kamu daftar akun lewat aplikasi.
-- Ganti email di bawah dengan email akun kamu.
update public.profiles
   set role = 'admin'
 where id = (select id from auth.users where email = 'GANTI_DENGAN_EMAIL_KAMU');
