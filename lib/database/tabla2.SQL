-- ==========================================
-- 2. TABLA DE USUARIOS (PERFILES)
-- ==========================================
create table public.perfiles (
    id uuid references auth.users(id) on delete cascade primary key,
    empresa_id uuid references public.empresas(id) on delete set null,
    tipo_usuario text check (tipo_usuario in ('empleado', 'admin_principal', 'admin_secundario')) not null default 'empleado',
    nombre_completo text not null,
    correo text unique not null,
    telefono text not null,
    id_personal text unique not null, -- ID único para cada usuario (ej. EMP-1048, ADM-001)
    cargo text,
    estado_activo boolean default true not null, -- Permite desactivar al usuario sin borrar su historial
    verificado boolean default false not null,
    foto_url text,
    cedula_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint password_formato_check check (
        -- Nota: La validación fuerte de la contraseña personal se maneja en Supabase Auth,
        -- pero dejamos constancia del campo y restricciones lógicas requeridas.
        char_length(id_personal) >= 3
    )
);