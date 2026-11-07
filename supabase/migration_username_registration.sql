<<<<<<< HEAD
-- HADIR: username peserta, tanpa NIM/email/nomor identitas di formulir peserta.
-- Jalankan satu kali setelah schema.sql dan migration_one_qr.sql.
=======
-- HADIR: pendaftaran mandiri dengan username + password, serta daftar hadir teman sekelas.
-- Jalankan SATU KALI setelah schema.sql dan migration_one_qr.sql.
>>>>>>> faff4a2915a67fdd9bd797423990adc043e4610c

alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists class_name text not null default '';
create unique index if not exists profiles_username_lower_uidx
  on public.profiles (lower(username)) where username is not null;

<<<<<<< HEAD
-- Profil baru dibuat oleh trigger Auth. Email internal hanya dipakai sebagai identitas teknis Auth;
-- peserta tidak diminta memasukkan atau melihat alamat email. Admin tetap memakai email asli.
=======
-- Sertakan ID sesi pada preview QR agar halaman peserta tidak perlu membaca tabel token QR.
create or replace function public.preview_session_qr(p_token text)
returns jsonb language plpgsql security definer set search_path = public, auth, pg_temp
as $$
declare s public.attendance_sessions%rowtype;
begin
  if auth.uid() is null then return jsonb_build_object('ok',false,'message','Silakan login dahulu.'); end if;
  select a.* into s from public.attendance_sessions a
  join public.session_qr_tokens q on q.session_id=a.id
  where q.token=p_token and a.is_open=true;
  if not found then return jsonb_build_object('ok',false,'message','QR tidak valid atau sesi sudah ditutup.'); end if;
  return jsonb_build_object('ok',true,'session_id',s.id,'title',s.title,'session_date',s.session_date);
end;
$$;
revoke all on function public.preview_session_qr(text) from public;
grant execute on function public.preview_session_qr(text) to authenticated;

-- Profil peserta baru dibuat otomatis oleh trigger Supabase Auth.
>>>>>>> faff4a2915a67fdd9bd797423990adc043e4610c
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public, auth, pg_temp
as $$
begin
<<<<<<< HEAD
  insert into public.profiles(id,email,full_name,role,username,class_name)
  values (new.id, coalesce(new.email,''),
    coalesce(new.raw_user_meta_data->>'full_name',''), 'participant',
    nullif(lower(new.raw_user_meta_data->>'username'),''),
    coalesce(new.raw_user_meta_data->>'class_name',''))
  on conflict (id) do update set
    full_name=excluded.full_name,
    username=coalesce(excluded.username,public.profiles.username),
    class_name=excluded.class_name;
=======
  insert into public.profiles(id,email,full_name,student_number,role,username,class_name)
  values (
    new.id,
    coalesce(new.email,''),
    coalesce(new.raw_user_meta_data->>'full_name',''),
    nullif(new.raw_user_meta_data->>'student_number',''),
    'participant',
    nullif(lower(new.raw_user_meta_data->>'username'),''),
    coalesce(new.raw_user_meta_data->>'class_name','')
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    student_number = excluded.student_number,
    username = coalesce(excluded.username, public.profiles.username),
    class_name = excluded.class_name;
>>>>>>> faff4a2915a67fdd9bd797423990adc043e4610c
  return new;
end;
$$;

<<<<<<< HEAD
-- Daftar teman hanya berisi nama, kelas tidak perlu ditampilkan berulang, waktu, dan status.
create or replace function public.class_attendance(p_session_id uuid)
returns table(full_name text, checked_at timestamptz, status text)
language plpgsql stable security definer set search_path = public, auth, pg_temp
as $$
begin
  if auth.uid() is null or not exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='participant') then
    raise exception 'Akses hanya untuk peserta yang login.';
  end if;
  if not exists (select 1 from public.attendance a where a.session_id=p_session_id and a.participant_id=auth.uid()) then
    raise exception 'Kamu harus tercatat hadir pada sesi ini untuk melihat daftar kehadiran kelas.';
  end if;
  return query
    select p.full_name, a.checked_at, a.status
    from public.attendance a join public.profiles p on p.id=a.participant_id
=======
-- Hanya peserta yang sudah tercatat hadir pada sesi yang sama yang dapat melihat
-- daftar nama peserta lain yang hadir pada sesi tersebut.
create or replace function public.class_attendance(p_session_id uuid)
returns table(full_name text, student_number text, checked_at timestamptz, status text)
language plpgsql stable security definer set search_path = public, auth, pg_temp
as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles p where p.id=auth.uid() and p.role='participant'
  ) then
    raise exception 'Akses hanya untuk peserta yang login.';
  end if;
  if not exists (
    select 1 from public.attendance a
    where a.session_id=p_session_id and a.participant_id=auth.uid()
  ) then
    raise exception 'Kamu harus tercatat hadir pada sesi ini untuk melihat daftar kehadiran kelas.';
  end if;
  return query
    select p.full_name, p.student_number, a.checked_at, a.status
    from public.attendance a
    join public.profiles p on p.id=a.participant_id
>>>>>>> faff4a2915a67fdd9bd797423990adc043e4610c
    where a.session_id=p_session_id
    order by p.full_name;
end;
$$;
revoke all on function public.class_attendance(uuid) from public;
grant execute on function public.class_attendance(uuid) to authenticated;

<<<<<<< HEAD
=======
-- Memastikan peserta hanya membaca profil sendiri (daftar teman disediakan RPC terbatas di atas).
>>>>>>> faff4a2915a67fdd9bd797423990adc043e4610c
notify pgrst, 'reload schema';
