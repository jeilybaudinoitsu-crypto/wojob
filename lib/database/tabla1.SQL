-- ==========================================
-- 1. TABLA DE EMPRESAS / SALAS
-- ==========================================
create table public.empresas (
    id uuid default gen_random_uuid() primary key,
    -- ID autogenerado único para la sala (ej. NOR-4826)
    id_sala text unique not null default ('NOR-' || lpad(floor(random() * 10000)::text, 4, '0')),
    nombre_empresa text unique not null,
    direccion_empresa text unique not null,
    -- Contraseña de la empresa con la misma validación de seguridad
    password_hash text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint empresa_password_check check (
        char_length(password_hash) between 8 and 16 AND
        password_hash ~ '[A-Z]' AND
        password_hash ~ '[a-z]' AND
        password_hash ~ '[0-9]' AND
        password_hash ~ '[.*/_]'
    )
);