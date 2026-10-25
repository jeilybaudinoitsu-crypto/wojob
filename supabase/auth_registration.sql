-- Registration profile creation, profile access, and bcrypt hashing for room passwords.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
alter extension pgcrypto set schema extensions;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

alter table public.empresas
  drop constraint if exists empresa_password_check;

update public.empresas
set password_hash = extensions.crypt(password_hash, extensions.gen_salt('bf'))
where left(password_hash, 4) not in ('$2a$', '$2b$', '$2y$');

create or replace function private.hash_empresa_password()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'UPDATE' and new.password_hash is not distinct from old.password_hash then
    return new;
  end if;

  if char_length(new.password_hash) not between 8 and 16
     or new.password_hash !~ '[A-Z]'
     or new.password_hash !~ '[a-z]'
     or new.password_hash !~ '[0-9]'
     or new.password_hash !~ '[.*/_]' then
    raise exception 'La contraseña de la sala no cumple el formato requerido'
      using errcode = '23514';
  end if;

  new.password_hash :=
    extensions.crypt(new.password_hash, extensions.gen_salt('bf'));
  return new;
end;
$function$;

revoke all on function private.hash_empresa_password() from public, anon, authenticated;

drop trigger if exists hash_empresa_password on public.empresas;
create trigger hash_empresa_password
before insert or update on public.empresas
for each row execute function private.hash_empresa_password();

create or replace function private.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.perfiles (
    id,
    tipo_usuario,
    nombre_completo,
    correo,
    telefono,
    id_personal,
    cargo,
    verificado
  )
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'tipo_usuario', ''), 'empleado'),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'nombre_completo'), ''),
    new.email,
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'telefono'), ''),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'id_personal'), ''),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'cargo'), ''),
    new.email_confirmed_at is not null
  );
  return new;
end;
$function$;

revoke all on function private.create_profile_for_auth_user() from public, anon, authenticated;

drop trigger if exists create_profile_for_auth_user on auth.users;
create trigger create_profile_for_auth_user
after insert on auth.users
for each row execute function private.create_profile_for_auth_user();

create or replace function private.prevent_profile_privilege_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if old.id = (select auth.uid())
     and (
       new.id is distinct from old.id
       or new.tipo_usuario is distinct from old.tipo_usuario
       or new.nombre_completo is distinct from old.nombre_completo
       or new.correo is distinct from old.correo
       or new.telefono is distinct from old.telefono
       or new.id_personal is distinct from old.id_personal
       or new.cargo is distinct from old.cargo
       or new.estado_activo is distinct from old.estado_activo
       or new.verificado is distinct from old.verificado
       or new.created_at is distinct from old.created_at
     ) then
    raise exception 'No puedes cambiar los datos protegidos de tu perfil'
      using errcode = '42501';
  end if;
  return new;
end;
$function$;

revoke all on function private.prevent_profile_privilege_changes() from public, anon, authenticated;

drop trigger if exists prevent_profile_privilege_changes on public.perfiles;
create trigger prevent_profile_privilege_changes
before update on public.perfiles
for each row execute function private.prevent_profile_privilege_changes();

drop policy if exists "WoJob users can read their own profile" on public.perfiles;
create policy "WoJob users can read their own profile"
on public.perfiles
for select
to authenticated
using (id = (select auth.uid()));

drop policy if exists "WoJob users can update their own profile" on public.perfiles;
create policy "WoJob users can update their own profile"
on public.perfiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

select
  n.nspname as schema_name,
  p.proname as function_name,
  p.prosecdef as security_definer,
  p.proconfig as function_settings
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'private'
  and p.proname in (
    'hash_empresa_password',
    'create_profile_for_auth_user',
    'prevent_profile_privilege_changes'
  )
order by p.proname;

select count(*) as room_passwords_not_bcrypt_hashed
from public.empresas
where char_length(password_hash) <> 60
   or left(password_hash, 4) not in ('$2a$', '$2b$', '$2y$');
