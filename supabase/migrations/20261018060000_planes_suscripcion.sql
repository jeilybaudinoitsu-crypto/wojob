alter table public.empresas
  add column plan_suscripcion text not null default 'FREE',
  add column limite_empleados integer default 10,
  add constraint empresas_plan_suscripcion_check
    check (plan_suscripcion in ('FREE', 'BUSINESS_GOLD', 'CEO_DIAMOND')),
  add constraint empresas_limite_empleados_check
    check (
      (plan_suscripcion = 'FREE' and limite_empleados = 10)
      or (plan_suscripcion = 'BUSINESS_GOLD' and limite_empleados = 250)
      or (plan_suscripcion = 'CEO_DIAMOND' and limite_empleados is null)
    );

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

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

revoke all on function private.is_current_user_admin_for_company(uuid)
  from public, anon;
grant execute on function private.is_current_user_admin_for_company(uuid)
  to authenticated;

grant update (plan_suscripcion, limite_empleados)
  on public.empresas to authenticated;

drop policy if exists "WoJob admins update company subscription"
  on public.empresas;
create policy "WoJob admins update company subscription"
on public.empresas
for update
to authenticated
using (private.is_current_user_admin_for_company(id))
with check (private.is_current_user_admin_for_company(id));

create or replace function private.guard_company_subscription_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  active_employee_count bigint;
begin
  if ((select auth.uid()) is not null)
     and (
       new.plan_suscripcion is distinct from old.plan_suscripcion
       or new.limite_empleados is distinct from old.limite_empleados
     )
     and not private.is_current_user_admin_for_company(old.id) then
    raise exception 'Solo un administrador de la sala puede actualizar su plan'
      using errcode = '42501';
  end if;

  if new.limite_empleados is not null then
    select count(*)
    into active_employee_count
    from public.perfiles profile
    where profile.empresa_id = old.id
      and profile.tipo_usuario = 'empleado'
      and profile.estado_activo;

    if active_employee_count > new.limite_empleados then
      raise exception 'La sala supera el límite de empleados del nuevo plan'
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$function$;

revoke all on function private.guard_company_subscription_update()
  from public, anon, authenticated;

drop trigger if exists guard_company_subscription_update
  on public.empresas;
create trigger guard_company_subscription_update
before update of plan_suscripcion, limite_empleados
on public.empresas
for each row execute function private.guard_company_subscription_update();

create or replace function private.enforce_empresa_employee_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  room_limit integer;
  employee_count bigint;
begin
  if new.empresa_id is null
     or new.tipo_usuario <> 'empleado'
     or not new.estado_activo then
    return new;
  end if;

  if tg_op = 'UPDATE'
     and old.empresa_id is not distinct from new.empresa_id
     and old.tipo_usuario = new.tipo_usuario
     and old.estado_activo then
    return new;
  end if;

  select company.limite_empleados
  into room_limit
  from public.empresas company
  where company.id = new.empresa_id
  for update;

  if not found then
    raise exception 'No se encontró el límite de empleados de la sala'
      using errcode = '23503';
  end if;
  if room_limit is null then
    return new;
  end if;

  select count(*)
  into employee_count
  from public.perfiles profile
  where profile.empresa_id = new.empresa_id
    and profile.tipo_usuario = 'empleado'
    and profile.estado_activo;

  if employee_count >= room_limit then
    raise exception 'La sala alcanzó el límite de empleados de su plan'
      using errcode = '23514';
  end if;

  return new;
end;
$function$;

revoke all on function private.enforce_empresa_employee_limit()
  from public, anon, authenticated;

drop trigger if exists enforce_empresa_employee_limit_insert
  on public.perfiles;
drop trigger if exists enforce_empresa_employee_limit_update
  on public.perfiles;
create trigger enforce_empresa_employee_limit_insert
before insert on public.perfiles
for each row execute function private.enforce_empresa_employee_limit();
create trigger enforce_empresa_employee_limit_update
before update of empresa_id, tipo_usuario, estado_activo
on public.perfiles
for each row execute function private.enforce_empresa_employee_limit();
