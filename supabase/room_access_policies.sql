-- Policies needed for room restoration and employee access requests.
-- Run after the tables and auth_registration.sql have been applied.

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

alter table public.empresas
  add column if not exists created_by uuid references auth.users(id) on delete set null;

create or replace function private.set_room_creator()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is null
     or not exists (
       select 1
       from public.perfiles profile
       where profile.id = (select auth.uid())
         and profile.tipo_usuario in ('admin_principal', 'admin_secundario')
     ) then
    raise exception 'Solo un administrador autenticado puede crear una sala'
      using errcode = '42501';
  end if;

  new.created_by := (select auth.uid());
  return new;
end;
$function$;

create or replace function private.attach_room_creator_to_company()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is null then
    raise exception 'Se requiere una sesión para crear una sala'
      using errcode = '42501';
  end if;

  update public.perfiles
  set empresa_id = new.id
  where id = (select auth.uid())
    and new.created_by = (select auth.uid())
    and tipo_usuario in ('admin_principal', 'admin_secundario');

  if not found then
    raise exception 'Solo un administrador puede crear una sala'
      using errcode = '42501';
  end if;

  return new;
end;
$function$;

create or replace function private.is_current_user_admin_for_company(
  target_company_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.perfiles admin_profile
      where admin_profile.id = (select auth.uid())
        and admin_profile.empresa_id = target_company_id
        and admin_profile.tipo_usuario in ('admin_principal', 'admin_secundario')
    );
$function$;

create or replace function private.can_view_company_profile(
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select (select auth.uid()) is not null
    and (
      exists (
        select 1
        from public.perfiles target_profile
        join public.perfiles admin_profile
          on admin_profile.id = (select auth.uid())
         and admin_profile.empresa_id = target_profile.empresa_id
         and admin_profile.tipo_usuario in ('admin_principal', 'admin_secundario')
        where target_profile.id = target_user_id
      )
      or exists (
        select 1
        from public.solicitudes_sala request
        join public.perfiles admin_profile
          on admin_profile.id = (select auth.uid())
         and admin_profile.empresa_id = request.empresa_id
         and admin_profile.tipo_usuario in ('admin_principal', 'admin_secundario')
        where request.usuario_id = target_user_id
          and request.estado in ('pendiente', 'aceptada', 'rechazada')
      )
    );
$function$;

create or replace function private.can_manage_company_profile(
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select (select auth.uid()) is not null
    and (
      exists (
        select 1
        from public.perfiles target_profile
        join public.perfiles admin_profile
          on admin_profile.id = (select auth.uid())
         and admin_profile.empresa_id = target_profile.empresa_id
         and admin_profile.tipo_usuario in ('admin_principal', 'admin_secundario')
        where target_profile.id = target_user_id
      )
      or exists (
        select 1
        from public.solicitudes_sala request
        join public.perfiles admin_profile
          on admin_profile.id = (select auth.uid())
         and admin_profile.empresa_id = request.empresa_id
         and admin_profile.tipo_usuario in ('admin_principal', 'admin_secundario')
        where request.usuario_id = target_user_id
          and request.estado = 'pendiente'
      )
    );
$function$;

create or replace function private.can_request_company(
  target_user_id uuid,
  target_company_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select (select auth.uid()) = target_user_id
    and exists (
      select 1
      from public.empresas company
      where company.id = target_company_id
    );
$function$;

revoke all on function private.is_current_user_admin_for_company(uuid)
  from public, anon;
revoke all on function private.can_view_company_profile(uuid)
  from public, anon;
revoke all on function private.can_manage_company_profile(uuid)
  from public, anon;
revoke all on function private.can_request_company(uuid, uuid)
  from public, anon;
revoke all on function private.set_room_creator()
  from public, anon, authenticated;
revoke all on function private.attach_room_creator_to_company()
  from public, anon, authenticated;
grant execute on function private.is_current_user_admin_for_company(uuid)
  to authenticated;
grant execute on function private.can_view_company_profile(uuid)
  to authenticated;
grant execute on function private.can_manage_company_profile(uuid)
  to authenticated;
grant execute on function private.can_request_company(uuid, uuid)
  to authenticated;

revoke update on public.perfiles from public, anon, authenticated;
grant select on public.perfiles to authenticated;
grant update (empresa_id, foto_url, cedula_url)
  on public.perfiles to authenticated;

revoke update on public.empresas from public, anon, authenticated;
grant select, insert on public.empresas to authenticated;

revoke update on public.solicitudes_sala from public, anon, authenticated;
grant select, insert on public.solicitudes_sala to authenticated;
grant update (estado) on public.solicitudes_sala to authenticated;

drop trigger if exists attach_room_creator_to_company on public.empresas;
drop trigger if exists set_room_creator on public.empresas;
create trigger set_room_creator
before insert on public.empresas
for each row execute function private.set_room_creator();

create trigger attach_room_creator_to_company
after insert on public.empresas
for each row execute function private.attach_room_creator_to_company();

drop policy if exists "WoJob users can read their own profile" on public.perfiles;
drop policy if exists "WoJob users can update their own profile" on public.perfiles;
drop policy if exists "WoJob admins can read room profiles" on public.perfiles;
drop policy if exists "WoJob admins can update room membership" on public.perfiles;
drop policy if exists "WoJob users and room admins can read profiles"
  on public.perfiles;
drop policy if exists "WoJob users and room admins can update profiles"
  on public.perfiles;

create policy "WoJob users and room admins can read profiles"
on public.perfiles
for select
to authenticated
using (
  id = (select auth.uid())
  or private.can_view_company_profile(id)
);

create policy "WoJob users and room admins can update profiles"
on public.perfiles
for update
to authenticated
using (
  id = (select auth.uid())
  or private.can_manage_company_profile(id)
)
with check (
  id = (select auth.uid())
  or (
    private.can_manage_company_profile(id)
    and private.is_current_user_admin_for_company(empresa_id)
  )
);

create or replace function private.prevent_room_membership_self_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
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

drop policy if exists "Administrador ve solicitudes de su sala"
  on public.solicitudes_sala;
drop policy if exists "Permitir inserción de solicitudes"
  on public.solicitudes_sala;
drop policy if exists "Permitir insertar solicitudes"
  on public.solicitudes_sala;
drop policy if exists "Permitir leer solicitudes"
  on public.solicitudes_sala;
drop policy if exists "WoJob users read own or room requests"
  on public.solicitudes_sala;
drop policy if exists "WoJob users create own pending requests"
  on public.solicitudes_sala;
drop policy if exists "WoJob admins update room requests"
  on public.solicitudes_sala;

create policy "WoJob users read own or room requests"
on public.solicitudes_sala
for select
to authenticated
using (
  usuario_id = (select auth.uid())
  or private.is_current_user_admin_for_company(empresa_id)
);

create policy "WoJob users create own pending requests"
on public.solicitudes_sala
for insert
to authenticated
with check (
  estado = 'pendiente'
  and private.can_request_company(usuario_id, empresa_id)
);

create policy "WoJob admins update room requests"
on public.solicitudes_sala
for update
to authenticated
using (private.is_current_user_admin_for_company(empresa_id))
with check (private.is_current_user_admin_for_company(empresa_id));

create index if not exists solicitudes_sala_empresa_usuario_estado_idx
on public.solicitudes_sala (empresa_id, usuario_id, estado);

select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
from pg_catalog.pg_policies
where schemaname = 'public'
  and tablename in ('perfiles', 'solicitudes_sala')
order by tablename, policyname;

select
  n.nspname as schema_name,
  p.proname as function_name,
  p.prosecdef as security_definer,
  p.proconfig as function_settings
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'private'
  and p.proname in (
    'set_room_creator',
    'attach_room_creator_to_company',
    'is_current_user_admin_for_company',
    'can_view_company_profile',
    'can_manage_company_profile',
    'can_request_company',
    'prevent_room_membership_self_assignment'
  )
order by p.proname;

select
  profile.id as admin_user_id,
  profile.correo as admin_email,
  profile.empresa_id,
  company.id_sala,
  company.nombre_empresa
from public.perfiles profile
left join public.empresas company on company.id = profile.empresa_id
where profile.tipo_usuario in ('admin_principal', 'admin_secundario')
order by profile.correo;
