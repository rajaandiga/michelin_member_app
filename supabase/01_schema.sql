-- Michelin Member App, tahap 1
-- Jalankan di Supabase: SQL Editor > New query > tempel > Run

create sequence if not exists public.member_seq start 1001;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  member_no text unique,
  role text not null default 'customer' check (role in ('customer','admin')),
  points integer not null default 0,
  total_spent bigint not null default 0,
  tier text not null default 'Bronze' check (tier in ('Bronze','Silver','Gold','Platinum')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('Ban','Layanan')),
  description text,
  price bigint not null check (price > 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  category text not null,
  qty integer not null check (qty > 0),
  total bigint not null,
  points_earned integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject text not null,
  message text not null,
  status text not null default 'Baru' check (status in ('Baru','Diproses','Selesai')),
  resolution text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Tier ditentukan dari total belanja
create or replace function public.tier_for(spent bigint)
returns text language sql immutable as $$
  select case
    when spent >= 40000000 then 'Platinum'
    when spent >= 15000000 then 'Gold'
    when spent >= 5000000 then 'Silver'
    else 'Bronze'
  end;
$$;

create or replace function public.is_admin()
returns boolean language sql security definer stable
set search_path = public as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- Profil dibuat otomatis saat ada akun baru
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public as $$
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
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Pembelian: poin dan tier bertambah otomatis (1 poin tiap Rp10.000)
create or replace function public.checkout(p_product_id uuid, p_qty integer)
returns public.orders language plpgsql security definer
set search_path = public as $$
declare
  v_prod public.products;
  v_total bigint;
  v_pts integer;
  v_spent bigint;
  v_order public.orders;
begin
  if auth.uid() is null then
    raise exception 'Kamu belum login';
  end if;
  if p_qty < 1 or p_qty > 20 then
    raise exception 'Jumlah tidak valid';
  end if;

  select * into v_prod from public.products where id = p_product_id and active;
  if not found then
    raise exception 'Produk tidak ditemukan';
  end if;

  v_total := v_prod.price * p_qty;
  v_pts := floor(v_total / 10000);

  insert into public.orders (user_id, product_id, product_name, category, qty, total, points_earned)
  values (auth.uid(), v_prod.id, v_prod.name, v_prod.category, p_qty, v_total, v_pts)
  returning * into v_order;

  update public.profiles
     set points = points + v_pts,
         total_spent = total_spent + v_total
   where id = auth.uid()
  returning total_spent into v_spent;

  update public.profiles set tier = public.tier_for(v_spent) where id = auth.uid();

  return v_order;
end;
$$;

revoke execute on function public.checkout(uuid, integer) from public, anon;
grant execute on function public.checkout(uuid, integer) to authenticated;

-- Keamanan: pelanggan hanya bisa melihat datanya sendiri
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.complaints enable row level security;

create policy "profil sendiri atau admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

create policy "ubah profil sendiri" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Pelanggan hanya boleh mengubah nama dan nomor HP, bukan poin, tier, atau role
revoke update on public.profiles from authenticated, anon;
grant update (full_name, phone) on public.profiles to authenticated;

create policy "produk aktif terlihat" on public.products
  for select to authenticated
  using (active or public.is_admin());

create policy "admin kelola produk" on public.products
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "pesanan sendiri atau admin" on public.orders
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "keluhan sendiri atau admin" on public.complaints
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "kirim keluhan sendiri" on public.complaints
  for insert to authenticated
  with check (user_id = auth.uid());

create policy "admin ubah keluhan" on public.complaints
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
