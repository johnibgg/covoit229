-- ============================================================
-- Covoit229 — schéma backend (à exécuter dans le SQL Editor)
-- Tables préfixées cv_ pour cohabiter avec ClipForge sans conflit.
-- ============================================================

create table if not exists cv_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text not null,
  photo_url text,
  is_driver boolean default false,
  vehicle text,
  created_at timestamptz not null default now()
);

create table if not exists cv_trips (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references cv_profiles(id) on delete cascade,
  from_city text not null,
  from_detail text,
  to_city text not null,
  to_detail text,
  depart_at timestamptz not null,
  seats_total int not null default 3 check (seats_total between 1 and 8),
  seats_taken int not null default 0,
  contrib_type text not null default 'discuss'
    check (contrib_type in ('free','fuel','fixed','discuss')),
  contrib_amount int,
  note text,
  recurring_days int[] not null default '{}',
  status text not null default 'open'
    check (status in ('open','full','done','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists cv_bookings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references cv_trips(id) on delete cascade,
  passenger_id uuid not null references cv_profiles(id) on delete cascade,
  seats int not null default 1 check (seats between 1 and 8),
  status text not null default 'pending'
    check (status in ('pending','accepted','rejected','cancelled','done')),
  created_at timestamptz not null default now(),
  unique (trip_id, passenger_id)
);

create table if not exists cv_messages (
  id bigint generated always as identity primary key,
  trip_id uuid not null references cv_trips(id) on delete cascade,
  sender_id uuid not null references cv_profiles(id) on delete cascade,
  receiver_id uuid not null references cv_profiles(id) on delete cascade,
  body text not null check (length(body) <= 2000),
  created_at timestamptz not null default now()
);

create table if not exists cv_ratings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references cv_trips(id) on delete cascade,
  rater_id uuid not null references cv_profiles(id) on delete cascade,
  rated_id uuid not null references cv_profiles(id) on delete cascade,
  stars int not null check (stars between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (trip_id, rater_id, rated_id)
);

create index if not exists cv_trips_search_idx on cv_trips (status, from_city, to_city, depart_at);
create index if not exists cv_msgs_trip_idx on cv_messages (trip_id, created_at);

-- ---------- Sécurité (RLS) : l'appli utilise la clé anon ----------
alter table cv_profiles enable row level security;
alter table cv_trips    enable row level security;
alter table cv_bookings enable row level security;
alter table cv_messages enable row level security;
alter table cv_ratings  enable row level security;

-- Profils : visibles par les connectés ; chacun crée/modifie le sien.
create policy cv_profiles_select on cv_profiles for select to authenticated using (true);
create policy cv_profiles_insert on cv_profiles for insert to authenticated with check (id = auth.uid());
create policy cv_profiles_update on cv_profiles for update to authenticated using (id = auth.uid());

-- Trajets : visibles par tous les connectés ; gérés par leur conducteur.
create policy cv_trips_select on cv_trips for select to authenticated using (true);
create policy cv_trips_insert on cv_trips for insert to authenticated with check (driver_id = auth.uid());
create policy cv_trips_update on cv_trips for update to authenticated using (driver_id = auth.uid());

-- Réservations : visibles par le passager et le conducteur du trajet.
create policy cv_bookings_select on cv_bookings for select to authenticated
  using (passenger_id = auth.uid()
         or exists (select 1 from cv_trips t where t.id = trip_id and t.driver_id = auth.uid()));
create policy cv_bookings_insert on cv_bookings for insert to authenticated
  with check (passenger_id = auth.uid());
create policy cv_bookings_update on cv_bookings for update to authenticated
  using (passenger_id = auth.uid()
         or exists (select 1 from cv_trips t where t.id = trip_id and t.driver_id = auth.uid()));

-- Le conducteur doit pouvoir mettre à jour seats_taken de SON trajet (déjà couvert),
-- et accepter/refuser les réservations de son trajet (couvert ci-dessus).

-- Messages : seuls l'expéditeur et le destinataire les voient.
create policy cv_messages_select on cv_messages for select to authenticated
  using (sender_id = auth.uid() or receiver_id = auth.uid());
create policy cv_messages_insert on cv_messages for insert to authenticated
  with check (sender_id = auth.uid());

-- Avis : visibles par tous les connectés ; on ne note qu'en son nom.
create policy cv_ratings_select on cv_ratings for select to authenticated using (true);
create policy cv_ratings_insert on cv_ratings for insert to authenticated with check (rater_id = auth.uid());
create policy cv_ratings_update on cv_ratings for update to authenticated using (rater_id = auth.uid());

-- Chat temps réel
alter publication supabase_realtime add table cv_messages;
