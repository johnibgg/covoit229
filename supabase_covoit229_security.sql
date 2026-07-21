-- ============================================================
-- Covoit229 — DURCISSEMENT SÉCURITÉ (à exécuter dans le SQL Editor)
-- À lancer UNE fois, après le schéma de base. Idempotent (ré-exécutable).
-- ------------------------------------------------------------
-- Objectif : les numéros de téléphone ne sont PLUS visibles par tous.
-- Ils sortent de cv_profiles vers cv_contacts (lisible par soi seul),
-- et ne sont révélés à un partenaire QUE si une réservation est acceptée.
-- + règles RLS resserrées (messages, notes, updates) + signalements.
-- ============================================================

-- 1) NUMÉROS PRIVÉS ------------------------------------------------------
create table if not exists cv_contacts (
  id uuid primary key references cv_profiles(id) on delete cascade,
  phone text not null,
  updated_at timestamptz not null default now()
);

-- Migre les numéros déjà présents dans cv_profiles (si la colonne existe encore).
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'cv_profiles' and column_name = 'phone'
  ) then
    insert into cv_contacts (id, phone)
      select id, phone from cv_profiles where phone is not null
      on conflict (id) do nothing;
    -- Le numéro ne doit plus vivre dans un profil lisible par tous.
    alter table cv_profiles drop column phone;
  end if;
end$$;

alter table cv_contacts enable row level security;
drop policy if exists cv_contacts_select on cv_contacts;
create policy cv_contacts_select on cv_contacts for select to authenticated
  using (id = auth.uid());
drop policy if exists cv_contacts_insert on cv_contacts;
create policy cv_contacts_insert on cv_contacts for insert to authenticated
  with check (id = auth.uid());
drop policy if exists cv_contacts_update on cv_contacts;
create policy cv_contacts_update on cv_contacts for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- 2) RÉVÉLATION DU CONTACT D'UN PARTENAIRE (réservation acceptée seulement)
-- Renvoie le numéro de p_other pour le trajet p_trip UNIQUEMENT si le
-- demandeur et p_other sont conducteur/passager avec une réservation acceptée.
create or replace function cv_partner_phone(p_trip uuid, p_other uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ok boolean;
  v_phone text;
begin
  select exists(
    select 1
    from cv_trips t
    join cv_bookings b on b.trip_id = t.id and b.status in ('accepted','done')
    where t.id = p_trip
      and (
        (t.driver_id = auth.uid()   and b.passenger_id = p_other)
        or (b.passenger_id = auth.uid() and t.driver_id   = p_other)
      )
  ) into v_ok;

  if not v_ok then
    return null;
  end if;

  select phone into v_phone from cv_contacts where id = p_other;
  return v_phone;
end;
$$;
revoke all on function cv_partner_phone(uuid, uuid) from public;
grant execute on function cv_partner_phone(uuid, uuid) to authenticated;

-- 3) UPDATES DURCIS (ajout de WITH CHECK — empêche de « donner » sa ligne) --
drop policy if exists cv_profiles_update on cv_profiles;
create policy cv_profiles_update on cv_profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists cv_trips_update on cv_trips;
create policy cv_trips_update on cv_trips for update to authenticated
  using (driver_id = auth.uid()) with check (driver_id = auth.uid());

drop policy if exists cv_ratings_update on cv_ratings;
create policy cv_ratings_update on cv_ratings for update to authenticated
  using (rater_id = auth.uid()) with check (rater_id = auth.uid());

-- 4) MESSAGES : conversation 1:1 avec le CONDUCTEUR, liée au trajet --------
-- Autorise un passager (même avant réservation) à écrire au conducteur, et
-- le conducteur à répondre. Bloque le spam passager↔passager (hors trajet).
drop policy if exists cv_messages_insert on cv_messages;
create policy cv_messages_insert on cv_messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from cv_trips t
      where t.id = trip_id
        and (t.driver_id = auth.uid() or t.driver_id = receiver_id)
    )
  );

-- 5) RÉSERVATIONS : on ne réserve pas son propre trajet -------------------
drop policy if exists cv_bookings_insert on cv_bookings;
create policy cv_bookings_insert on cv_bookings for insert to authenticated
  with check (
    passenger_id = auth.uid()
    and not exists (
      select 1 from cv_trips t where t.id = trip_id and t.driver_id = auth.uid()
    )
  );

-- 6) NOTES : seulement une personne avec qui on a réellement partagé un trajet
drop policy if exists cv_ratings_insert on cv_ratings;
create policy cv_ratings_insert on cv_ratings for insert to authenticated
  with check (
    rater_id = auth.uid()
    and exists (
      select 1 from cv_trips t
      join cv_bookings b on b.trip_id = t.id and b.status in ('accepted','done')
      where t.id = trip_id
        and (
          (t.driver_id = auth.uid()   and b.passenger_id = rated_id)
          or (b.passenger_id = auth.uid() and t.driver_id   = rated_id)
        )
    )
  );

-- 7) SIGNALEMENTS ---------------------------------------------------------
create table if not exists cv_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references cv_profiles(id) on delete cascade,
  reported_id uuid references cv_profiles(id) on delete set null,
  trip_id uuid references cv_trips(id) on delete set null,
  reason text not null check (length(reason) between 1 and 1000),
  created_at timestamptz not null default now()
);
alter table cv_reports enable row level security;
drop policy if exists cv_reports_insert on cv_reports;
create policy cv_reports_insert on cv_reports for insert to authenticated
  with check (reporter_id = auth.uid());
drop policy if exists cv_reports_select on cv_reports;
create policy cv_reports_select on cv_reports for select to authenticated
  using (reporter_id = auth.uid());

-- Fin. Résultat attendu : « Success. No rows returned ».

-- 8) PHOTOS DE PROFIL (bucket public cv-avatars) --------------------------
insert into storage.buckets (id, name, public)
  values ('cv-avatars','cv-avatars', true)
  on conflict (id) do update set public = true;
drop policy if exists cv_avatars_read on storage.objects;
create policy cv_avatars_read on storage.objects for select using (bucket_id = 'cv-avatars');
drop policy if exists cv_avatars_insert on storage.objects;
create policy cv_avatars_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'cv-avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists cv_avatars_update on storage.objects;
create policy cv_avatars_update on storage.objects for update to authenticated
  using (bucket_id = 'cv-avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists cv_avatars_delete on storage.objects;
create policy cv_avatars_delete on storage.objects for delete to authenticated
  using (bucket_id = 'cv-avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- 9) CNI privée (dans cv_contacts) + révélation aux partenaires confirmés --
alter table cv_contacts add column if not exists cni text;
create or replace function cv_partner_cni(p_trip uuid, p_other uuid)
returns text language plpgsql security definer set search_path = public as $FN2$
declare v_ok boolean; v_cni text;
begin
  select exists(
    select 1 from cv_trips t
    join cv_bookings b on b.trip_id = t.id and b.status in ('accepted','done')
    where t.id = p_trip
      and ((t.driver_id = auth.uid() and b.passenger_id = p_other)
        or (b.passenger_id = auth.uid() and t.driver_id = p_other))
  ) into v_ok;
  if not v_ok then return null; end if;
  select cni into v_cni from cv_contacts where id = p_other;
  return v_cni;
end; $FN2$;
revoke all on function cv_partner_cni(uuid, uuid) from public;
grant execute on function cv_partner_cni(uuid, uuid) to authenticated;
