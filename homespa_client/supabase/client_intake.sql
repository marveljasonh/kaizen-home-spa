-- Client Intake Form answers (homespa_client: /intake, /intake/edit).
-- Run once in the Supabase SQL editor.

create table if not exists public.client_intake (
  client_id uuid primary key references auth.users (id) on delete cascade,
  health_conditions text[] not null default '{}',
  focus_areas text[] not null default '{}',
  pressure text not null default 'medium'
    check (pressure in ('light', 'medium', 'firm')),
  avoid_areas text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.client_intake enable row level security;

drop policy if exists "Clients read own intake" on public.client_intake;
create policy "Clients read own intake"
  on public.client_intake for select
  using (auth.uid() = client_id);

drop policy if exists "Clients insert own intake" on public.client_intake;
create policy "Clients insert own intake"
  on public.client_intake for insert
  with check (auth.uid() = client_id);

drop policy if exists "Clients update own intake" on public.client_intake;
create policy "Clients update own intake"
  on public.client_intake for update
  using (auth.uid() = client_id)
  with check (auth.uid() = client_id);
