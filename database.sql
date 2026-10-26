-- =====================================================================
-- database.sql - Struktur database Michelin Member App (Supabase)
-- Cara pakai: Supabase Dashboard > SQL Editor > New query > tempel > Run
-- Jalankan sekali saja di proyek Supabase yang baru dan masih kosong.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Sequence nomor member
-- ---------------------------------------------------------------------
create sequence if not exists public.member_seq start 1;

-- ---------------------------------------------------------------------
-- 2. Tabel
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  member_no text unique,
  role text not null default 'customer'
    check (role in ('customer', 'admin')),
  points integer not null default 0,
  total_spent bigint not null default 0,
  tier text not null default 'Bronze'
    check (tier in ('Bronze', 'Silver', 'Gold', 'Platinum')),
  created_at timestamptz not null default now(),
  visit_count integer not null default 0,
  service_visit_count integer not null default 0,
  last_visit_at timestamptz
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('Ban', 'Layanan')),
  description text,
  price bigint not null check (price > 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.vouchers (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  kind text not null check (kind in ('nominal', 'persen')),
  value integer not null check (value > 0),
  max_discount integer,
  min_spend bigint not null default 0,
  points_cost integer check (points_cost > 0),
  min_tier text check (min_tier in ('Bronze', 'Silver', 'Gold', 'Platinum')),
  target_segment text check (target_segment in ('Baru', 'Aktif', 'Setia', 'Tidur')),
  only_service boolean not null default false,
  active boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text,
  category text,
  qty integer check (qty > 0),
  total bigint not null,
  points_earned integer not null default 0,
  created_at timestamptz not null default now(),
  subtotal bigint,
  discount bigint not null default 0,
  voucher_title text,
  has_service boolean not null default false
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  category text not null,
  price bigint not null,
  qty integer not null check (qty > 0)
);

create table public.complaints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject text not null,
  message text not null,
  status text not null default 'Baru'
    check (status in ('Baru', 'Diproses', 'Selesai')),
  resolution text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_vouchers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  voucher_id uuid not null references public.vouchers(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  used_at timestamptz,
  order_id uuid references public.orders(id) on delete set null
);

-- ---------------------------------------------------------------------
-- 3. Fungsi
-- ---------------------------------------------------------------------
create or replace function public.tier_for(spent bigint)
returns text
language sql
immutable
as $function$
  select case
    when spent >= 40000000 then 'Platinum'
    when spent >= 15000000 then 'Gold'
    when spent >= 5000000 then 'Silver'
    else 'Bronze'
  end;
$function$;

create or replace function public.tier_rank(t text)
returns integer
language sql
immutable
as $function$
  select case t when 'Platinum' then 4 when 'Gold' then 3 when 'Silver' then 2 else 1 end;
$function$;

create or replace function public.segment_of(
  p_created timestamptz, p_visits integer, p_last timestamptz)
returns text
language sql
stable
as $function$
  select case
    when p_last is null then
      case when p_created > now() - interval '30 days' then 'Baru' else 'Tidur' end
    when p_last < now() - interval '60 days' then 'Tidur'
    when p_visits >= 4 then 'Setia'
    when p_visits <= 1 then 'Baru'
    else 'Aktif'
  end;
$function$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$function$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.profiles (id, full_name, phone, member_no)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'phone',
    'MCH-' || lpad(nextval('public.member_seq')::text, 6, '0')
  );
  return new;
end;
$function$;

create or replace function public.protect_role()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not public.is_admin() then
    new.role := old.role;
  end if;
  return new;
end;
$function$;

create or replace function public.checkout_cart(
  p_items jsonb, p_user_voucher_id uuid default null::uuid)
returns orders
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_prod public.products;
  v_qty integer;
  v_subtotal bigint := 0;
  v_has_service boolean := false;
  v_discount bigint := 0;
  v_total bigint;
  v_pts integer;
  v_order public.orders;
  v_uv public.user_vouchers;
  v_v public.vouchers;
  v_vtitle text;
  v_spent bigint;
begin
  if v_uid is null then
    raise exception 'Kamu belum login';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Keranjang kosong';
  end if;
  if jsonb_array_length(p_items) > 20 then
    raise exception 'Terlalu banyak item';
  end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'qty')::integer;
    if v_qty is null or v_qty < 1 or v_qty > 20 then
      raise exception 'Jumlah tidak valid';
    end if;
    select * into v_prod from public.products
     where id = (v_item->>'product_id')::uuid and active;
    if not found then
      raise exception 'Ada produk yang sudah tidak tersedia';
    end if;
    v_subtotal := v_subtotal + v_prod.price * v_qty;
    if v_prod.category = 'Layanan' then
      v_has_service := true;
    end if;
  end loop;

  if p_user_voucher_id is not null then
    select * into v_uv from public.user_vouchers
     where id = p_user_voucher_id and user_id = v_uid and used_at is null
     for update;
    if not found then
      raise exception 'Voucher tidak bisa dipakai';
    end if;
    select * into v_v from public.vouchers where id = v_uv.voucher_id;
    if v_v.expires_at is not null and v_v.expires_at < now() then
      raise exception 'Voucher sudah kedaluwarsa';
    end if;
    if v_subtotal < v_v.min_spend then
      raise exception 'Belanja belum mencapai minimal voucher';
    end if;
    if v_v.only_service and not v_has_service then
      raise exception 'Voucher ini hanya untuk pesanan yang ada jasanya';
    end if;
    if v_v.kind = 'nominal' then
      v_discount := v_v.value;
    else
      v_discount := floor(v_subtotal * v_v.value / 100.0)::bigint;
      if v_v.max_discount is not null and v_discount > v_v.max_discount then
        v_discount := v_v.max_discount;
      end if;
    end if;
    if v_discount > v_subtotal then
      v_discount := v_subtotal;
    end if;
    v_vtitle := v_v.title;
  end if;

  v_total := v_subtotal - v_discount;
  v_pts := (v_total / 10000)::integer;

  insert into public.orders (user_id, subtotal, discount, total, points_earned, voucher_title, has_service)
  values (v_uid, v_subtotal, v_discount, v_total, v_pts, v_vtitle, v_has_service)
  returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_prod from public.products where id = (v_item->>'product_id')::uuid;
    insert into public.order_items (order_id, product_id, product_name, category, price, qty)
    values (v_order.id, v_prod.id, v_prod.name, v_prod.category, v_prod.price, (v_item->>'qty')::integer);
  end loop;

  if p_user_voucher_id is not null then
    update public.user_vouchers set used_at = now(), order_id = v_order.id
     where id = p_user_voucher_id;
  end if;

  -- Satu pesanan = satu kunjungan
  update public.profiles
     set points = points + v_pts,
         total_spent = total_spent + v_total,
         visit_count = visit_count + 1,
         service_visit_count = service_visit_count + (case when v_has_service then 1 else 0 end),
         last_visit_at = now()
   where id = v_uid
  returning total_spent into v_spent;

  update public.profiles set tier = public.tier_for(v_spent) where id = v_uid;

  return v_order;
end;
$function$;

create or replace function public.claim_voucher(p_voucher_id uuid)
returns user_vouchers
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_v public.vouchers;
  v_p public.profiles;
  v_uv public.user_vouchers;
begin
  if v_uid is null then
    raise exception 'Kamu belum login';
  end if;
  select * into v_v from public.vouchers where id = p_voucher_id and active;
  if not found then
    raise exception 'Voucher tidak tersedia';
  end if;
  if v_v.expires_at is not null and v_v.expires_at < now() then
    raise exception 'Voucher sudah kedaluwarsa';
  end if;

  select * into v_p from public.profiles where id = v_uid for update;

  if v_v.min_tier is not null and public.tier_rank(v_p.tier) < public.tier_rank(v_v.min_tier) then
    raise exception 'Voucher ini untuk tier % ke atas', v_v.min_tier;
  end if;
  if v_v.target_segment is not null
     and public.segment_of(v_p.created_at, v_p.visit_count, v_p.last_visit_at) <> v_v.target_segment then
    raise exception 'Voucher ini bukan untuk kamu saat ini';
  end if;

  if v_v.points_cost is null then
    if exists (select 1 from public.user_vouchers where user_id = v_uid and voucher_id = v_v.id) then
      raise exception 'Voucher sudah kamu klaim';
    end if;
  else
    if v_p.points < v_v.points_cost then
      raise exception 'Poin kamu belum cukup';
    end if;
    update public.profiles set points = points - v_v.points_cost where id = v_uid;
  end if;

  insert into public.user_vouchers (user_id, voucher_id)
  values (v_uid, v_v.id) returning * into v_uv;
  return v_uv;
end;
$function$;

-- Hanya pengguna yang sudah login yang boleh memanggil dua fungsi ini
revoke execute on function public.checkout_cart(jsonb, uuid) from public, anon;
grant execute on function public.checkout_cart(jsonb, uuid) to authenticated;
revoke execute on function public.claim_voucher(uuid) from public, anon;
grant execute on function public.claim_voucher(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 4. Trigger
-- ---------------------------------------------------------------------
-- Cegah pengguna biasa mengubah role sendiri
create trigger protect_role_trg
  before update on public.profiles
  for each row execute function public.protect_role();

-- Buat profil otomatis setiap ada akun baru
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- 5. View segmen pelanggan (dipakai panel admin)
-- ---------------------------------------------------------------------
create or replace view public.customer_segments
with (security_invoker = true) as
select
  id, full_name, phone, member_no, role, points, total_spent, tier,
  created_at, visit_count, service_visit_count, last_visit_at,
  case
    when last_visit_at is null then
      case when created_at >= (now() - interval '30 days') then 'Baru' else 'Tidur' end
    when last_visit_at < (now() - interval '60 days') then 'Tidur'
    when coalesce(visit_count, 0) >= 4 then 'Setia'
    when coalesce(visit_count, 0) <= 1 then 'Baru'
    else 'Aktif'
  end as segment
from public.profiles p;

-- ---------------------------------------------------------------------
-- 6. Row Level Security
-- ---------------------------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.products      enable row level security;
alter table public.vouchers      enable row level security;
alter table public.orders        enable row level security;
alter table public.order_items   enable row level security;
alter table public.complaints    enable row level security;
alter table public.user_vouchers enable row level security;

-- products
create policy "produk aktif terlihat" on public.products
  for select to authenticated
  using (active or public.is_admin());
create policy "admin kelola produk" on public.products
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- vouchers
create policy "voucher aktif terlihat" on public.vouchers
  for select to authenticated
  using ((active and (expires_at is null or expires_at > now())) or public.is_admin());
create policy "admin kelola voucher" on public.vouchers
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- profiles
create policy "profil sendiri atau admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy "ubah profil sendiri" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy "admin update profiles" on public.profiles
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- orders
create policy "pesanan sendiri atau admin" on public.orders
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- order_items
create policy "item pesanan sendiri atau admin" on public.order_items
  for select to authenticated
  using (exists (
    select 1 from public.orders o
    where o.id = order_items.order_id
      and (o.user_id = auth.uid() or public.is_admin())
  ));

-- user_vouchers
create policy "voucher milik sendiri atau admin" on public.user_vouchers
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- complaints
create policy "kirim keluhan sendiri" on public.complaints
  for insert to authenticated
  with check (user_id = auth.uid());
create policy "keluhan sendiri atau admin" on public.complaints
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy "admin ubah keluhan" on public.complaints
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- 7. Data awal
-- ---------------------------------------------------------------------

-- Voucher
insert into public.vouchers
  (id, title, description, kind, value, max_discount, min_spend, points_cost,
   min_tier, target_segment, only_service, active, expires_at)
values
  ('0e2c527b-cea7-47cf-9000-19a395af66cb', 'Diskon Rp25.000', 'Potongan untuk belanja apa saja',
   'nominal', 25000, null, 100000, 50, null, null, false, true, null),
  ('fa8c88ee-f529-4288-89fc-535da80dc9d7', 'Diskon Rp100.000', 'Potongan untuk pembelian ban',
   'nominal', 100000, null, 1000000, 200, null, null, false, true, null),
  ('cab59fc4-87aa-41df-af5f-b8706491b26c', 'Diskon 10% jasa', 'Berlaku kalau pesanan ada jasanya',
   'persen', 10, 50000, 100000, 80, null, null, true, true, null),
  ('842ee2fa-0f8c-4ff5-a982-d0d4903a3b5c', 'Selamat datang', 'Hadiah untuk member baru',
   'nominal', 20000, null, 100000, null, null, 'Baru', false, true, null),
  ('3ee10927-62fa-4754-81ff-52a7cd792de3', 'Ayo servis lagi', 'Sudah lama tidak berkunjung? Servis rutin lebih hemat',
   'persen', 15, 75000, 100000, null, null, 'Tidur', true, true, null),
  ('3b4bcc15-4346-46fe-b6ac-38b4492b45af', 'Bonus member Gold', 'Hadiah untuk member Gold ke atas',
   'nominal', 150000, null, 1500000, null, 'Gold', null, false, true, null),
  ('d04d4e5b-c8b1-4e11-8102-4ca0e6638833', 'Diskon Member Baru 10%', 'Diskon 10% untuk pembelian pertama',
   'persen', 10, 50000, 200000, 50, null, 'Baru', false, true, '2026-12-18 16:59:59+00'),
  ('7d7a8562-43b6-4d23-b213-d1082c8d552c', 'Potongan Jasa Rp. 25.000', 'Potongan untuk pemasangan atau balancing',
   'nominal', 25000, null, 100000, 30, null, null, true, true, null),
  ('33abaa6a-1c50-4f6c-9d7a-bd9c54e07da3', 'Kami Rindu Kamu, Diskon Rp. 50.000', null,
   'nominal', 50000, null, 300000, 10, null, 'Tidur', false, true, null);

-- Produk
insert into public.products (id, name, category, description, price, active)
values
  ('277b453c-7948-40bd-be53-04e2ec2e7cf2', 'Michelin Primacy 4 ST 205/55 R16', 'Ban',
   'Ban mobil untuk kenyamanan dan pengereman di jalan basah', 1650000, true),
  ('c1b2f237-ee42-4802-a6c4-e4acbb2a83be', 'Michelin Pilot Sport 4 225/45 R17', 'Ban',
   'Ban mobil untuk performa dan cengkeraman tinggi', 2400000, true),
  ('345bed9a-1144-4b7d-9e11-a6aa4128cabf', 'Michelin Energy XM2+ 185/65 R15', 'Ban',
   'Ban mobil yang awet dan irit bahan bakar', 1100000, true),
  ('f0c3be2a-6c07-472f-9a5e-cd5cc9421cf4', 'Michelin Pilot Street 2 80/90-17', 'Ban',
   'Ban motor untuk pemakaian harian', 450000, true),
  ('1a6bfb6c-aec3-43d2-9650-19bf2d4ddb35', 'Michelin Primacy 4 205/55 R16', 'Ban',
   'Ban touring nyaman dan senyap', 1850000, true),
  ('edbde4c0-74a4-465e-aba5-171a0bd042a1', 'Pasang ban', 'Layanan',
   'Pemasangan ban per roda', 50000, true),
  ('55431c6b-7bd6-4258-9a31-b84b3c7133de', 'Spooring', 'Layanan',
   'Pengaturan sudut roda, 4 roda', 250000, true),
  ('dcf7d9d5-bada-4a4c-bc0c-dc36d487c1a2', 'Rotasi ban', 'Layanan',
   'Tukar posisi ban supaya keausan merata', 100000, true),
  ('2404a92c-5b48-41f6-becc-81325866dd4a', 'Balancing', 'Layanan',
   'Penyeimbangan roda per roda', 40000, true),
  ('2341fc27-8e6f-417b-836d-51775fc49d89', 'Spooring dan Balancing 4 roda', 'Layanan',
   'Termasuk pengecekan tekanan angin', 950000, true);
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 8. Menjadikan satu akun sebagai admin
-- Daftar dulu satu akun lewat aplikasi, lalu jalankan baris di bawah
-- (ganti emailnya, buka komentarnya):
--
-- update public.profiles set role = 'admin'
--  where id = (select id from auth.users where email = 'email_admin@contoh.com');
-- ---------------------------------------------------------------------
