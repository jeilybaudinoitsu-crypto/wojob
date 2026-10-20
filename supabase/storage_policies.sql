create policy "Authenticated users can read profile photos"
on storage.objects
for select
to authenticated
using (bucket_id = 'avatares');

create policy "Users can upload their own profile photo"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users can read their own identity documents"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'documentos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users can upload their own identity documents"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'documentos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Employees and company admins can read attendance photos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'asistencias'
  and (
    (storage.foldername(name))[2] = (select auth.uid())::text
    or exists (
      select 1
      from public.perfiles p
      where p.id = (select auth.uid())
        and p.empresa_id::text = (storage.foldername(name))[1]
        and p.tipo_usuario in ('admin_principal', 'admin_secundario')
    )
  )
);

create policy "Employees can upload their own attendance photos"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'asistencias'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and exists (
    select 1
    from public.perfiles p
    where p.id = (select auth.uid())
      and p.empresa_id::text = (storage.foldername(name))[1]
  )
);
