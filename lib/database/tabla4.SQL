-- ==========================================
-- 4. TABLA DE HORARIOS Y TURNOS
-- ==========================================
create table public.horarios (
    id uuid default gen_random_uuid() primary key,
    empresa_id uuid references public.empresas(id) on delete cascade not null,
    empleado_id uuid references public.perfiles(id) on delete cascade not null,
    dia_semana text check (dia_semana in ('L', 'M', 'Mi', 'J', 'V', 'S', 'D')) not null,
    hora_entrada time not null,
    hora_salida time not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);