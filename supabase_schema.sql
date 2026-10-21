-- =============================================================================
-- WORDVERSE — Esquema SQL Completo + Políticas RLS + Datos Semilla para Supabase
-- Instrucciones: Copia todo este archivo en Supabase -> SQL Editor -> Run.
-- =============================================================================

-- 1. Tabla de Usuarios (users)
create table if not exists public.users (
  id text primary key,
  nombre text not null,
  empresa text not null,
  cargo text default 'Ejecutivo',
  descripcion text default '',
  avatar text not null,
  avatar_color bigint default 4278248959,
  estado text default 'AVAILABLE' check (estado in ('AVAILABLE', 'BUSY', 'UNAVAILABLE')),
  es_favorito boolean default false,
  conectado boolean default false,
  updated_at timestamptz default now()
);

-- 2. Tabla de Wallets (wallets)
create table if not exists public.wallets (
  user_id text primary key references public.users(id) on delete cascade,
  balance_usdt numeric(18, 2) not null default 0.00,
  trc20_address text not null default 'TShestWordVerse9xK2L8mQvP4r7Wz89TRC20',
  updated_at timestamptz default now()
);

-- 3. Tabla de Reuniones (meetings)
create table if not exists public.meetings (
  id text primary key,
  codigo text unique not null, -- Ej: WV-45821
  nombre text not null,
  tipo text not null default 'Negocios',
  descripcion text default '',
  es_privada boolean default false,
  duracion_min int default 45,
  creador text not null references public.users(id),
  creador_nombre text not null default 'Usuario Shest',
  created_at timestamptz default now()
);

-- 4. Tabla de Escrows (escrows)
create table if not exists public.escrows (
  id text primary key, -- Ej: 45821
  creador_id text not null references public.users(id),
  creador_nombre text not null default 'Daniel (Tú)',
  contraparte_id text not null references public.users(id),
  contraparte_nombre text not null default 'Valeria Méndez',
  monto numeric(18, 2) not null check (monto > 0),
  moneda text not null default 'USDT',
  descripcion text default '',
  condiciones text default '',
  estado text not null default 'PENDING' check (
    estado in (
      'PENDING',
      'FUNDED',
      'IN_PROGRESS',
      'RELEASE_REQUESTED',
      'RELEASED',
      'DISPUTED',
      'CANCELLED',
      'COMPLETED'
    )
  ),
  created_at timestamptz default now()
);

-- =============================================================================
-- POLÍTICAS RLS PARA PRUEBAS DE DESARROLLO (Dev 1 + Dev 2 con ANON_KEY)
-- =============================================================================
alter table public.users enable row level security;
alter table public.wallets enable row level security;
alter table public.meetings enable row level security;
alter table public.escrows enable row level security;

drop policy if exists "Allow anon all users" on public.users;
create policy "Allow anon all users" on public.users for all using (true) with check (true);

drop policy if exists "Allow anon all wallets" on public.wallets;
create policy "Allow anon all wallets" on public.wallets for all using (true) with check (true);

drop policy if exists "Allow anon all meetings" on public.meetings;
create policy "Allow anon all meetings" on public.meetings for all using (true) with check (true);

drop policy if exists "Allow anon all escrows" on public.escrows;
create policy "Allow anon all escrows" on public.escrows for all using (true) with check (true);

-- =============================================================================
-- DATOS SEMILLA INICIALES (Idénticos a MockShestApi)
-- =============================================================================
insert into public.users (id, nombre, empresa, cargo, descripcion, avatar, avatar_color, estado, es_favorito, conectado)
values
  ('usr_1', 'Daniel (Tú)', 'Shest Labs Partner', 'Director de Negocios', 'Cerrando acuerdos B2B con Escrow USDT TRC20 en WordVerse.', 'DN', 4278248959, 'AVAILABLE', false, true),
  ('usr_2', 'Valeria Méndez', 'Andes FinTech Latam', 'Head of OTC & Liquidity', 'Liquidez corporativa USDT/USD y alianzas estratégicas.', 'VM', 4286336511, 'AVAILABLE', true, true),
  ('usr_3', 'Carlos Mendoza', 'BlockBean Trade', 'Importador Internacional', 'Contratos comerciales con garantía Escrow en tiempo real.', 'CM', 4278249078, 'BUSY', false, false),
  ('usr_4', 'Sofía Herrera', 'Global Ventures Capital', 'Managing Partner', 'Inversión semilla Web3 y rondas privadas en Latinoamérica.', 'SH', 4294945536, 'AVAILABLE', false, false)
on conflict (id) do nothing;

insert into public.wallets (user_id, balance_usdt, trc20_address)
values
  ('usr_1', 12500.00, 'TShestWordVerse9xK2L8mQvP4r7Wz89TRC20'),
  ('usr_2', 48000.00, 'TShestAndesFinTech88TRC20Address'),
  ('usr_3', 19200.00, 'TShestBlockBeanTrade77TRC20Address'),
  ('usr_4', 85000.00, 'TShestGlobalVentures99TRC20Address')
on conflict (user_id) do nothing;

insert into public.meetings (id, codigo, nombre, tipo, descripcion, es_privada, duracion_min, creador, creador_nombre)
values
  ('mtg_1', 'WV-45821', 'Mesa de Negocios OTC Latam', 'Negocios', 'Reunión principal para acuerdos comerciales con Escrow.', false, 60, 'usr_2', 'Valeria Méndez')
on conflict (id) do nothing;
