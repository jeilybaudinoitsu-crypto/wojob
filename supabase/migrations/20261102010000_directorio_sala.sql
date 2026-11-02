-- WHY: Exponer solo nombre/cargo/rol de la propia sala sin ampliar SELECT RLS de perfiles.
create or replace function public.room_member_directory()
returns table (
  nombre_completo text,
  cargo text,
  tipo_usuario text
)
language sql
stable
security definer
set search_path = ''
as $function$
  select miembro.nombre_completo, miembro.cargo, miembro.tipo_usuario::text
  from public.perfiles miembro
  where miembro.empresa_id = (
    select propio.empresa_id
    from public.perfiles propio
    where propio.id = (select auth.uid())
      and propio.empresa_id is not null
      and propio.estado_activo = true
  )
    and miembro.estado_activo = true
  order by miembro.nombre_completo;
$function$;

revoke execute on function public.room_member_directory() from public, anon;
grant execute on function public.room_member_directory() to authenticated;
