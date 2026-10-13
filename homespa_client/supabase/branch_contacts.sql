-- Contact Us page: WhatsApp number + opening hours per branch.
-- Run once in the Supabase SQL editor. Safe to re-run.
--
-- The admin dashboard (Branches page) edits these two columns, and the client
-- app's Contact Us page reads them.

alter table public.branches add column if not exists phone text;
alter table public.branches add column if not exists operating_hours text;

-- Let the app (anon + signed-in clients) read branches. Only created when the
-- table has no SELECT policy yet, and row level security is left as it is.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'branches'
      and cmd in ('SELECT', 'ALL')
  ) then
    create policy branches_public_read
      on public.branches
      for select
      to anon, authenticated
      using (true);
  end if;
end $$;

-- Example (replace with the real numbers, or just fill them in the dashboard):
-- update public.branches set phone = '0812-3456-7890', operating_hours = 'Daily, 09:00 – 21:00'
--   where name = 'Kaizen Home Spa Jakarta';
