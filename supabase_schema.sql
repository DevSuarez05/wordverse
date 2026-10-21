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

-- 5. Tabla de Presencia Multiplayer en Sala 3D (room_presence - Fase 7)
create table if not exists public.room_presence (
  user_id text primary key references public.users(id) on delete cascade,
  sala text not null default 'Sala Principal',
  pos_x double precision not null default 0.0,
  pos_z double precision not null default 0.42,
  rotacion double precision not null default 0.0,
  emote text,
  online boolean default true,
  updated_at timestamptz default now()
);

-- 6. Tabla de Operaciones P2P (p2p_operations - Fase 21)
create table if not exists public.p2p_operations (
  id text primary key,
  maker_id text not null references public.users(id),
  maker_nombre text not null default 'Valeria Méndez',
  monto_usdt numeric(18, 2) not null check (monto_usdt > 0),
  tasa_usd numeric(10, 4) not null default 1.0000,
  metodo_pago text not null default 'Transferencia Bancaria / USDT TRC20',
  estado text not null default 'OPEN' check (estado in ('OPEN', 'IN_ESCROW', 'COMPLETED', 'CANCELLED')),
  created_at timestamptz default now()
);

-- 7. Tabla de Mensajes de Chat por Sala/Canal (chat_messages - Fase 14)
create table if not exists public.chat_messages (
  id text primary key,
  channel_id text not null default 'Sala Principal',
  sender_id text not null references public.users(id),
  sender_name text not null,
  texto text not null,
  created_at timestamptz default now()
);

-- =============================================================================
-- POLÍTICAS RLS PARA PRUEBAS DE DESARROLLO (Dev 1 + Dev 2 con ANON_KEY)
-- =============================================================================
alter table public.users enable row level security;
alter table public.wallets enable row level security;
alter table public.meetings enable row level security;
alter table public.escrows enable row level security;
alter table public.room_presence enable row level security;
alter table public.p2p_operations enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Allow anon all users" on public.users;
create policy "Allow anon all users" on public.users for all using (true) with check (true);

drop policy if exists "Allow anon all wallets" on public.wallets;
create policy "Allow anon all wallets" on public.wallets for all using (true) with check (true);

drop policy if exists "Allow anon all meetings" on public.meetings;
create policy "Allow anon all meetings" on public.meetings for all using (true) with check (true);

drop policy if exists "Allow anon all escrows" on public.escrows;
create policy "Allow anon all escrows" on public.escrows for all using (true) with check (true);

drop policy if exists "Allow anon all room_presence" on public.room_presence;
create policy "Allow anon all room_presence" on public.room_presence for all using (true) with check (true);

drop policy if exists "Allow anon all p2p_operations" on public.p2p_operations;
create policy "Allow anon all p2p_operations" on public.p2p_operations for all using (true) with check (true);

drop policy if exists "Allow anon all chat_messages" on public.chat_messages;
create policy "Allow anon all chat_messages" on public.chat_messages for all using (true) with check (true);

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

insert into public.room_presence (user_id, sala, pos_x, pos_z, rotacion, emote, online)
values
  ('usr_2', 'Sala Principal', -0.32, -0.18, 0.0, 'negotiate', true),
  ('usr_3', 'Sala Principal',  0.34, -0.12, 0.0, null, true),
  ('usr_4', 'Sala Principal',  0.28,  0.30, 0.0, null, true)
on conflict (user_id) do nothing;

insert into public.p2p_operations (id, maker_id, maker_nombre, monto_usdt, tasa_usd, metodo_pago, estado)
values
  ('p2p_901', 'usr_2', 'Valeria Méndez', 2500.00, 1.0020, 'Transferencia Bancaria Instantánea', 'OPEN'),
  ('p2p_902', 'usr_3', 'Carlos Mendoza', 5000.00, 0.9990, 'Wire USD / Sepa Instant', 'OPEN')
on conflict (id) do nothing;
