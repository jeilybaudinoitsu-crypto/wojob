-- ==========================================
-- 5. TABLA DE HISTORIAL DE ASISTENCIAS
-- ==========================================
create table public.asistencias (
    id uuid default gen_random_uuid() primary key,
    empleado_id uuid references public.perfiles(id) on delete set null,
    empresa_id uuid references public.empresas(id) on delete set null,
    tipo text check (tipo in ('entrada', 'salida')) not null,
    fecha_hora timestamp with time zone default timezone('utc'::text, now()) not null,
    latitud double precision not null,
    longitud double precision not null,
    foto_url text not null
);