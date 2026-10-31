-- Keeps public.perfiles synchronized with the authoritative Auth email.
-- Run once in the hosted project's Supabase SQL Editor.

begin;

create schema if not exists private;

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

  -- Keep the existing RPC argument for compatibility; Auth owns the email value.
  select usuario.email, usuario.email_confirmed_at
  into auth_email, auth_confirmed_at
  from auth.users usuario
  where usuario.id = (select auth.uid());

  if auth_email is null then
    raise exception 'No se encontró el correo de autenticación'
      using errcode = 'P0002';
  end if;

  perform pg_catalog.set_config('wojob.system_update', 'on', true);

  update public.perfiles
  set correo = auth_email,
      telefono = pg_catalog.btrim(p_telefono),
      verificado = (auth_confirmed_at is not null)
  where id = (select auth.uid())
  returning * into perfil;

  if perfil.id is null then
    raise exception 'No se encontró tu perfil' using errcode = 'P0002';
  end if;

  return perfil;
end;
$function$;

create or replace function private.sync_profile_email_after_auth_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  perform pg_catalog.set_config('wojob.system_update', 'on', true);

  update public.perfiles
  set correo = new.email,
      verificado = (new.email_confirmed_at is not null)
  where id = new.id;

  return new;
end;
$function$;

revoke all on function private.sync_profile_email_after_auth_update()
  from public, anon, authenticated;

drop trigger if exists sync_profile_email_after_auth_update on auth.users;
create trigger sync_profile_email_after_auth_update
after update of email on auth.users
for each row
when (old.email is distinct from new.email)
execute function private.sync_profile_email_after_auth_update();

select pg_catalog.set_config('wojob.system_update', 'on', true);

update public.perfiles perfil
set correo = usuario.email,
    verificado = (usuario.email_confirmed_at is not null)
from auth.users usuario
where usuario.id = perfil.id
  and (
    perfil.correo is distinct from usuario.email
    or perfil.verificado is distinct from (usuario.email_confirmed_at is not null)
  );

commit;

select count(*) as perfiles_con_correo_desincronizado
from public.perfiles perfil
join auth.users usuario on usuario.id = perfil.id
where perfil.correo is distinct from usuario.email
   or perfil.verificado is distinct from (usuario.email_confirmed_at is not null);
