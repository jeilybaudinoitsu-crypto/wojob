-- ==========================================
-- 3. TABLA DE SOLICITUDES DE ACCESO A LA SALA
-- ==========================================
create table public.solicitudes_sala (
    id uuid default gen_random_uuid() primary key,
    empresa_id uuid references public.empresas(id) on delete cascade not null,
    usuario_id uuid references public.perfiles(id) on delete cascade not null,
    estado text check (estado in ('pendiente', 'aceptada', 'rechazada')) default 'pendiente' not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);