-- OPSIONAL. Isi katalog supaya aplikasi tidak kosong saat dites.
-- Nama dan harga di bawah hanya contoh, ganti sesuai kebutuhan.
-- Kalau tidak mau dipakai, lewati file ini dan isi tabel products lewat Table Editor.

insert into public.products (name, category, description, price) values
  ('Michelin Primacy 4 ST 205/55 R16', 'Ban', 'Ban mobil untuk kenyamanan dan pengereman di jalan basah', 1650000),
  ('Michelin Pilot Sport 4 225/45 R17', 'Ban', 'Ban mobil untuk performa dan cengkeraman tinggi', 2400000),
  ('Michelin Energy XM2+ 185/65 R15', 'Ban', 'Ban mobil yang awet dan irit bahan bakar', 1100000),
  ('Michelin Pilot Street 2 80/90-17', 'Ban', 'Ban motor untuk pemakaian harian', 450000),
  ('Pasang ban', 'Layanan', 'Pemasangan ban per roda', 50000),
  ('Balancing', 'Layanan', 'Penyeimbangan roda per roda', 40000),
  ('Spooring', 'Layanan', 'Pengaturan sudut roda, 4 roda', 250000),
  ('Rotasi ban', 'Layanan', 'Tukar posisi ban supaya keausan merata', 100000);
