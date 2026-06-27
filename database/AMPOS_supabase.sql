-- ============================================================
-- AMPERSAND POS — Schema Supabase (PostgreSQL)
-- Ejecutar en: supabase.com → proyecto → SQL Editor
-- ============================================================

-- ------------------------------------------------------------
-- licencias  (una por negocio cliente)
-- La columna id = auth.uid() del dueño del negocio
-- ------------------------------------------------------------
create table if not exists licencias (
  id            uuid primary key references auth.users(id) on delete cascade,
  nombre_negocio text,
  plan          text    not null default 'basico',
  fecha_vence   date    not null,
  activo        boolean not null default true,
  created_at    timestamptz not null default now()
);
alter table licencias enable row level security;
create policy "propietario ve su licencia" on licencias
  for all using (auth.uid() = id);

-- ------------------------------------------------------------
-- activaciones  (un registro por dispositivo)
-- ------------------------------------------------------------
create table if not exists activaciones (
  id_licencia    uuid    not null references licencias(id) on delete cascade,
  id_activacion  serial,
  device_id      text    not null unique,
  nombre_terminal text,
  sucursal       text,
  modo           text    not null default 'caja',
  activo         boolean not null default true,
  created_at     timestamptz not null default now(),
  primary key (id_licencia, id_activacion)
);
alter table activaciones enable row level security;
create policy "propietario ve sus activaciones" on activaciones
  for all using (auth.uid() = id_licencia);

-- ------------------------------------------------------------
-- categorias
-- ------------------------------------------------------------
create table if not exists categorias (
  id_licencia  uuid    not null references licencias(id) on delete cascade,
  id_categoria serial,
  nombre       text    not null,
  color        text,
  activo       boolean not null default true,
  primary key (id_licencia, id_categoria)
);
alter table categorias enable row level security;
create policy "propietario ve sus categorias" on categorias
  for all using (auth.uid() = id_licencia);

-- ------------------------------------------------------------
-- productos
-- ------------------------------------------------------------
create table if not exists productos (
  id_licencia     uuid          not null references licencias(id) on delete cascade,
  id_producto     serial,
  id_categoria    int,
  nombre          text          not null,
  precio          numeric(18,0) not null default 0,
  precio_variable boolean       not null default false,
  costo           numeric(18,0) not null default 0,
  codigo          text,
  codigos_extra   text,
  iva             text          not null default '10',
  color           text,
  activo          boolean       not null default true,
  updated_at      timestamptz   not null default now(),
  primary key (id_licencia, id_producto),
  foreign key (id_licencia, id_categoria)
    references categorias(id_licencia, id_categoria)
);
alter table productos enable row level security;
create policy "propietario ve sus productos" on productos
  for all using (auth.uid() = id_licencia);
create index if not exists ix_productos_codigo on productos(id_licencia, codigo)
  where codigo is not null;

-- ------------------------------------------------------------
-- turnos
-- ------------------------------------------------------------
create table if not exists turnos (
  id_licencia      uuid          not null references licencias(id) on delete cascade,
  id_turno         serial,
  id_activacion    int           not null,
  terminal         text          not null,
  sucursal         text,
  efectivo_inicial numeric(18,0) not null default 0,
  estado           text          not null default 'abierto',
  fecha_apertura   timestamptz   not null default now(),
  fecha_cierre     timestamptz,
  total_contado    numeric(18,0),
  diferencia       numeric(18,0),
  primary key (id_licencia, id_turno)
);
alter table turnos enable row level security;
create policy "propietario ve sus turnos" on turnos
  for all using (auth.uid() = id_licencia);

-- ------------------------------------------------------------
-- ventas
-- ------------------------------------------------------------
create table if not exists ventas (
  id_licencia       uuid          not null references licencias(id) on delete cascade,
  id_venta          serial,
  id_turno          int,
  id_activacion     int           not null default 0,
  terminal          text          not null default '',
  sucursal          text,
  fecha             timestamptz   not null default now(),
  total             numeric(18,0) not null default 0,
  metodo_pago       text          not null default 'EFECTIVO',
  cliente_nombre    text,
  estado            text          not null default 'completada',
  motivo_anulacion  text,
  fecha_anulacion   timestamptz,
  primary key (id_licencia, id_venta)
);
alter table ventas enable row level security;
create policy "propietario ve sus ventas" on ventas
  for all using (auth.uid() = id_licencia);
create index if not exists ix_ventas_turno on ventas(id_licencia, id_turno, estado);

-- ------------------------------------------------------------
-- venta_lineas
-- ------------------------------------------------------------
create table if not exists venta_lineas (
  id_licencia     uuid          not null,
  id_venta        int           not null,
  id_venta_linea  serial,
  id_producto     int,
  nombre_producto text          not null,
  cantidad        numeric(18,4) not null default 1,
  precio_unitario numeric(18,0) not null default 0,
  iva             text          not null default '10',
  categoria       text,
  costo           numeric(18,0) not null default 0,
  primary key (id_licencia, id_venta, id_venta_linea),
  foreign key (id_licencia, id_venta)
    references ventas(id_licencia, id_venta) on delete cascade
);
alter table venta_lineas enable row level security;
create policy "propietario ve sus lineas" on venta_lineas
  for all using (auth.uid() = id_licencia);

-- ------------------------------------------------------------
-- egresos (gastos de caja)
-- ------------------------------------------------------------
create table if not exists egresos (
  id_licencia    uuid          not null references licencias(id) on delete cascade,
  id_egreso      serial,
  id_turno       int,
  id_activacion  int           not null default 0,
  terminal       text          not null default '',
  descripcion    text          not null,
  monto          numeric(18,0) not null default 0,
  fecha          timestamptz   not null default now(),
  anulado        boolean       not null default false,
  fecha_anulacion timestamptz,
  primary key (id_licencia, id_egreso)
);
alter table egresos enable row level security;
create policy "propietario ve sus egresos" on egresos
  for all using (auth.uid() = id_licencia);

-- ============================================================
-- PASO FINAL: crear licencia para el primer cliente
-- (ejecutar después de crear el usuario en Auth)
-- ============================================================
-- Reemplazar 'UUID_DEL_USUARIO' con el id real del auth.users

-- insert into licencias (id, nombre_negocio, plan, fecha_vence)
-- values ('UUID_DEL_USUARIO', 'Mi Negocio', 'basico', '2027-12-31');
