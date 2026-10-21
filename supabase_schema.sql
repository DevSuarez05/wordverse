-- =============================================================================
-- WORDVERSE — Esquema SQL Rápido para Supabase (Dev 2 - Backend de Pruebas)
-- Permite probar P2P, Wallet, Reuniones y Escrow sin depender del Java de Shest.
-- =============================================================================

-- 1. Tabla de Usuarios (users)
create table if not exists public.users (
  id text primary key,
  nombre text not null,
  empresa text not null,
  cargo text default 'Ejecutivo',
  avatar text not null,
  estado text default 'AVAILABLE' check (estado in ('AVAILABLE', 'BUSY', 'UNAVAILABLE')),
  updated_at timestamptz default now()
);

-- 2. Tabla de Wallets (wallets)
create table if not exists public.wallets (
  user_id text primary key references public.users(id) on delete cascade,
  balance_usdt numeric(18, 2) not null default 0.00,
  trc20_address text not null default 'TShestWordVerseTRC20MockAddress',
  updated_at timestamptz default now()
);

-- 3. Tabla de Reuniones (meetings)
create table if not exists public.meetings (
  id text primary key,
  codigo text unique not null, -- Ej: WV-45821
  nombre text not null,
  tipo text not null default 'Negocios',
  descripcion text,
  es_privada boolean default false,
  creador text not null references public.users(id),
  created_at timestamptz default now()
);

-- 4. Tabla de Escrows (escrows)
create table if not exists public.escrows (
  id text primary key, -- Ej: 45821
  creador_id text not null references public.users(id),
  contraparte_id text not null references public.users(id),
  monto numeric(18, 2) not null check (monto > 0),
  moneda text not null default 'USDT',
  descripcion text,
  condiciones text,
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

-- Habilitar Realtime para presencia de avatares y estados de Escrow
alter publication supabase_realtime add table public.users;
alter publication supabase_realtime add table public.meetings;
alter publication supabase_realtime add table public.escrows;
