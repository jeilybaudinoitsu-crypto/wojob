-- ============================================================================
-- 7. MENÚ DE CUENTA, CONFIGURACIÓN Y GESTIÓN DE SALA
--
-- Esta migración NO crea tablas nuevas. Agrega:
--   * Columnas de "snapshot" en asistencias para conservar el nombre del
--     empleado aunque su cuenta se elimine.
--   * Funciones RPC protegidas para:
--       - actualizar correo/teléfono del propio usuario,
--       - sincronizar el estado de verificación del correo,
--       - eliminar la propia cuenta sin borrar el historial de asistencias,
--       - salir de una sala,
--       - eliminar un miembro de una sala (solo administradores),
--       - editar la información de una sala verificando su contraseña.
--   * El trigger de perfiles se ajusta para que estas funciones internas
--     puedan actualizar campos protegidos sin abrir la puerta al cliente.
--
-- Ejecutar después de auth_registration.sql y room_access_policies.sql.
-- ============================================================================

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

-- ----------------------------------------------------------------------------
-- 1. HISTORIAL DE ASISTENCIAS QUE SOBREVIVE AL BORRADO DE LA CUENTA
-- ----------------------------------------------------------------------------

alter table public.asistencias
  add column if not exists empleado_nombre text,
  add column if not exists empleado_id_personal text;

-- Rellena el snapshot de los registros que ya existían.
update public.asistencias asistencia
set empleado_nombre = perfil.nombre_completo,
    empleado_id_personal = perfil.id_personal
from public.perfiles perfil
where asistencia.empleado_id = perfil.id
  and (
    asistencia.empleado_nombre is null
    or asistencia.empleado_id_personal is null
  );

-- Guarda el nombre y el ID personal en cada nueva marcación.
create or replace function private.snapshot_asistencia_empleado()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.empleado_id is not null then
    select perfil.nombre_completo, perfil.id_personal
    into new.empleado_nombre, new.empleado_id_personal
    from public.perfiles perfil
    where perfil.id = new.empleado_id;
  end if;
  return new;
end;
$function$;

revoke all on function private.snapshot_asistencia_empleado()
  from public, anon, authenticated;

drop trigger if exists snapshot_asistencia_empleado on public.asistencias;
create trigger snapshot_asistencia_empleado
before insert on public.asistencias
for each row execute function private.snapshot_asistencia_empleado();

-- ----------------------------------------------------------------------------
-- 2. PERMITIR ACTUALIZACIONES INTERNAS CONTROLADAS EN perfiles
-- ----------------------------------------------------------------------------
-- El trigger original bloquea cualquier cambio de correo, teléfono o
-- verificado hecho por el propio usuario. Las funciones RPC de esta migración
-- activan la marca local "wojob.system_update" para poder hacer esos cambios
-- de forma controlada. El cliente nunca puede activar esa marca directamente.

create or replace function private.prevent_profile_privilege_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if pg_catalog.current_setting('wojob.system_update', true) = 'on' then
    return new;
  end if;

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

revoke all on function private.prevent_profile_privilege_changes()
  from public, anon, authenticated;

drop trigger if exists prevent_profile_privilege_changes on public.perfiles;
create trigger prevent_profile_privilege_changes
before update on public.perfiles
for each row execute function private.prevent_profile_privilege_changes();

-- ----------------------------------------------------------------------------
-- 2b. PERMITIR SALIR DE LA SALA A TRAVÉS DE LA FUNCIÓN INTERNA
-- ----------------------------------------------------------------------------
-- room_access_policies.sql impide que un usuario cambie su propia sala, incluso
-- para dejarla vacía. La función leave_room() activa "wojob.system_update" y
-- este trigger respeta esa marca para que la salida controlada funcione.

create or replace function private.prevent_room_membership_self_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if pg_catalog.current_setting('wojob.system_update', true) = 'on' then
    return new;
  end if;

  if old.id = (select auth.uid())
     and new.empresa_id is distinct from old.empresa_id then
    if new.empresa_id is null or not exists (
      select 1
      from public.empresas company
      where company.id = new.empresa_id
        and company.created_by = (select auth.uid())
    ) then
      raise exception 'Solo un administrador puede asignarte a una sala'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$function$;

revoke all on function private.prevent_room_membership_self_assignment()
  from public, anon, authenticated;

drop trigger if exists prevent_room_membership_self_assignment
  on public.perfiles;
create trigger prevent_room_membership_self_assignment
before update on public.perfiles
for each row execute function private.prevent_room_membership_self_assignment();

-- ----------------------------------------------------------------------------
-- 3. ACTUALIZAR CORREO Y TELÉFONO DEL PROPIO USUARIO
-- ----------------------------------------------------------------------------
-- La app pide la contraseña actual antes de llamar a esta función. El correo
-- de Auth se actualiza desde el cliente con Supabase Auth; aquí se guarda el
-- dato visible del perfil y se sincroniza la verificación.

create or replace function public.update_own_contact(
  p_correo text,
  p_telefono text
)
returns public.perfiles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  auth_email text;
  auth_confirmed_at timestamptz;
  perfil public.perfiles;
begin
  if (select auth.uid()) is null then
    raise exception 'Debes iniciar sesión para actualizar tu cuenta'
      using errcode = '42501';
  end if;

  if p_correo is null or pg_catalog.btrim(p_correo) = '' then
    raise exception 'El correo es obligatorio' using errcode = '23514';
  end if;

  if p_telefono is null or pg_catalog.btrim(p_telefono) = '' then
    raise exception 'El teléfono es obligatorio' using errcode = '23514';
  end if;

  select usuario.email, usuario.email_confirmed_at
  into auth_email, auth_confirmed_at
  from auth.users usuario
  where usuario.id = (select auth.uid());

  perform pg_catalog.set_config('wojob.system_update', 'on', true);

  update public.perfiles
  set correo = pg_catalog.btrim(p_correo),
      telefono = pg_catalog.btrim(p_telefono),
      verificado = (
        auth_email = pg_catalog.btrim(p_correo)
        and auth_confirmed_at is not null
      )
  where id = (select auth.uid())
  returning * into perfil;

  if perfil.id is null then
    raise exception 'No se encontró tu perfil' using errcode = 'P0002';
  end if;

  return perfil;
end;
$function$;

-- ----------------------------------------------------------------------------
-- 4. SINCRONIZAR CORREO Y VERIFICACIÓN CON SUPABASE AUTH
-- ----------------------------------------------------------------------------

create or replace function public.sync_own_account()
returns public.perfiles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  auth_email text;
  auth_confirmed_at timestamptz;
  perfil public.perfiles;
begin
  if (select auth.uid()) is null then
    raise exception 'Debes iniciar sesión' using errcode = '42501';
  end if;

  select usuario.email, usuario.email_confirmed_at
  into auth_email, auth_confirmed_at
  from auth.users usuario
  where usuario.id = (select auth.uid());

  perform pg_catalog.set_config('wojob.system_update', 'on', true);

  update public.perfiles
  set correo = coalesce(auth_email, correo),
      verificado = (auth_confirmed_at is not null)
  where id = (select auth.uid())
  returning * into perfil;

  if perfil.id is null then
    raise exception 'No se encontró tu perfil' using errcode = 'P0002';
  end if;

  return perfil;
end;
$function$;

-- ----------------------------------------------------------------------------
-- 5. ELIMINAR LA PROPIA CUENTA SIN BORRAR EL HISTORIAL DE ASISTENCIAS
-- ----------------------------------------------------------------------------
-- perfiles se elimina en cascada desde auth.users. La FK de asistencias usa
-- "on delete set null", así que las marcaciones se conservan con el nombre y
-- el ID personal guardados en el snapshot.

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is null then
    raise exception 'Debes iniciar sesión para eliminar tu cuenta'
      using errcode = '42501';
  end if;

  delete from auth.users where id = (select auth.uid());
end;
$function$;

-- ----------------------------------------------------------------------------
-- 6. SALIR DE LA SALA
-- ----------------------------------------------------------------------------

create or replace function public.leave_room()
returns public.perfiles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_company_id uuid;
  perfil public.perfiles;
begin
  if (select auth.uid()) is null then
    raise exception 'Debes iniciar sesión para salir de la sala'
      using errcode = '42501';
  end if;

  select empresa_id into current_company_id
  from public.perfiles
  where id = (select auth.uid());

  if current_company_id is not null then
    delete from public.horarios
    where empresa_id = current_company_id
      and empleado_id = (select auth.uid());
  end if;

  perform pg_catalog.set_config('wojob.system_update', 'on', true);

  update public.perfiles
  set empresa_id = null
  where id = (select auth.uid())
  returning * into perfil;

  if perfil.id is null then
    raise exception 'No se encontró tu perfil' using errcode = 'P0002';
  end if;

  return perfil;
end;
$function$;

-- ----------------------------------------------------------------------------
-- 7. ELIMINAR UN MIEMBRO DE LA SALA (SOLO ADMINISTRADORES)
-- ----------------------------------------------------------------------------
-- El miembro deja de pertenecer a la sala y se borran sus horarios de esa
-- sala. Su cuenta y su historial de asistencias se conservan.

create or replace function public.remove_room_member(
  p_empresa_id uuid,
  p_member_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  member public.perfiles;
begin
  if (select auth.uid()) is null then
    raise exception 'Debes iniciar sesión' using errcode = '42501';
  end if;

  if not private.is_current_user_admin_for_company(p_empresa_id) then
    raise exception 'Solo un administrador de la sala puede eliminar miembros'
      using errcode = '42501';
  end if;

  if p_member_id = (select auth.uid()) then
    raise exception 'No puedes eliminarte a ti mismo; usa la opción Salir de la sala'
      using errcode = '42501';
  end if;

  select * into member
  from public.perfiles
  where id = p_member_id
    and empresa_id = p_empresa_id;

  if member.id is null then
    raise exception 'El miembro no pertenece a esta sala' using errcode = 'P0002';
  end if;

  if member.tipo_usuario <> 'empleado' then
    raise exception 'Solo se pueden eliminar empleados de la sala'
      using errcode = '42501';
  end if;

  delete from public.horarios
  where empresa_id = p_empresa_id
    and empleado_id = p_member_id;

  perform pg_catalog.set_config('wojob.system_update', 'on', true);

  update public.perfiles
  set empresa_id = null
  where id = p_member_id;
end;
$function$;

-- ----------------------------------------------------------------------------
-- 8. EDITAR LA INFORMACIÓN DE LA SALA (VERIFICANDO SU CONTRASEÑA)
-- ----------------------------------------------------------------------------

create or replace function public.update_empresa_info(
  p_empresa_id uuid,
  p_password text,
  p_nombre_empresa text,
  p_direccion_empresa text,
  p_nueva_password text default null
)
returns public.empresas
language plpgsql
security definer
set search_path = ''
as $function$
declare
  empresa public.empresas;
begin
  if (select auth.uid()) is null then
    raise exception 'Debes iniciar sesión' using errcode = '42501';
  end if;

  if not private.is_current_user_admin_for_company(p_empresa_id) then
    raise exception 'Solo un administrador de la sala puede editarla'
      using errcode = '42501';
  end if;

  select * into empresa
  from public.empresas
  where id = p_empresa_id;

  if empresa.id is null then
    raise exception 'No se encontró la sala' using errcode = 'P0002';
  end if;

  if p_password is null
     or extensions.crypt(p_password, empresa.password_hash) <> empresa.password_hash then
    raise exception 'Contraseña de la sala incorrecta' using errcode = '28P01';
  end if;

  if p_nombre_empresa is null or pg_catalog.btrim(p_nombre_empresa) = '' then
    raise exception 'El nombre de la sala es obligatorio' using errcode = '23514';
  end if;

  if p_direccion_empresa is null or pg_catalog.btrim(p_direccion_empresa) = '' then
    raise exception 'La dirección de la sala es obligatoria' using errcode = '23514';
  end if;

  update public.empresas
  set nombre_empresa = pg_catalog.btrim(p_nombre_empresa),
      direccion_empresa = pg_catalog.btrim(p_direccion_empresa),
      password_hash = case
        when p_nueva_password is null or pg_catalog.btrim(p_nueva_password) = ''
          then password_hash
        else pg_catalog.btrim(p_nueva_password)
      end
  where id = p_empresa_id
  returning * into empresa;

  return empresa;
end;
$function$;

-- ----------------------------------------------------------------------------
-- 9. PERMISOS DE EJECUCIÓN
-- ----------------------------------------------------------------------------

revoke all on function public.update_own_contact(text, text)
  from public, anon;
revoke all on function public.sync_own_account()
  from public, anon;
revoke all on function public.delete_own_account()
  from public, anon;
revoke all on function public.leave_room()
  from public, anon;
revoke all on function public.remove_room_member(uuid, uuid)
  from public, anon;
revoke all on function public.update_empresa_info(uuid, text, text, text, text)
  from public, anon;

grant execute on function public.update_own_contact(text, text)
  to authenticated;
grant execute on function public.sync_own_account()
  to authenticated;
grant execute on function public.delete_own_account()
  to authenticated;
grant execute on function public.leave_room()
  to authenticated;
grant execute on function public.remove_room_member(uuid, uuid)
  to authenticated;
grant execute on function public.update_empresa_info(uuid, text, text, text, text)
  to authenticated;

-- ----------------------------------------------------------------------------
-- 10. VERIFICACIÓN RÁPIDA
-- ----------------------------------------------------------------------------

select
  table_name,
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'asistencias'
  and column_name in ('empleado_nombre', 'empleado_id_personal')
order by column_name;

select
  n.nspname as schema_name,
  p.proname as function_name,
  p.prosecdef as security_definer
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'update_own_contact',
    'sync_own_account',
    'delete_own_account',
    'leave_room',
    'remove_room_member',
    'update_empresa_info'
  )
order by p.proname;
