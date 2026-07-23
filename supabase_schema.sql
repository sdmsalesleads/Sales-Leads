-- ============================================================================
-- ELSEWEDY SALES CRM — COMPLETE SUPABASE DATABASE (ALL-IN-ONE)
-- This single file contains the ENTIRE database: tables, relationships, security
-- policies, authority matrix, activity logs, duplicate detection, fair rotation,
-- qualification/lost-reason/SLA fields, and automation settings.
-- Paste this ENTIRE file into: Supabase Dashboard → SQL Editor → New query → Run
-- SAFE TO RE-RUN: works on a fresh project AND on an existing one (it only
-- creates what is missing and updates the rules — your data is never touched).
-- No other SQL file is needed.
--
-- ⚠ NOTE: Supabase's editor may show a "destructive operation detected"
-- confirmation before running. That warning is triggered by the DROP POLICY /
-- DROP TRIGGER lines below, which only refresh the security rules by removing
-- the OLD rule an instant before recreating the NEW one. NO table, NO column,
-- and NO data is ever dropped by this file. Click "Run this query" / Confirm
-- to proceed — it is expected and safe.
-- ============================================================================

-- ---------- 1. ROLES ----------
do $do$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid=t.typnamespace
                 where t.typname='user_role' and n.nspname='public') then
create type public.user_role as enum (
  'pending',      -- signed up, waiting for admin (HR) approval
  'sales',        -- own leads only; updates status/follow-ups/offers/value
  'manager',      -- sees their team (reports-to tree)
  'director',     -- sales director: full view
  'salesops',     -- distributes leads; full view
  'marketing',    -- adds/edits/deletes leads; full view
  'marketingmgr', -- marketing manager: marketing powers + executive view
  'finance',      -- AR: won deals only; confirms cash
  'ceo','cfo','hrdirector', -- executive tier: full view (cfo also confirms cash)
  'admin',        -- HR administrator: approves people; views all; no lead edits
  'disabled'      -- access revoked
);
  end if;
end $do$;

-- ---------- 2. TABLES ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  name text not null default '',
  role public.user_role not null default 'pending',
  title text not null default '',
  department text not null default '',
  annual_target numeric not null default 0,
  manager_id uuid references public.profiles(id) on delete set null,
  phone text not null default '',
  last_login timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.leads (
  id text primary key,                    -- client-generated LD-xxxx ids
  name text not null,
  company text not null default '',
  custno text not null default '',
  phone text not null default '',
  phone2 text not null default '',
  email text not null default '',
  source text not null default '',
  project text not null default '',
  land numeric,
  industry text not null default '',
  priority text not null default '',
  status text not null default 'New',
  owner uuid references public.profiles(id) on delete set null,
  next_followup date,
  next_time text not null default '',
  meeting_date date,
  meeting_time text not null default '',
  offer_sent boolean not null default false,
  offer_date date,
  value numeric,
  cash_status text not null default '',   -- '' | 'pending' | 'confirmed'
  cash_by text not null default '',
  cash_date date,
  won_date date,
  qual_status text not null default '',
  temperature text not null default '',
  qual_notes text not null default '',
  lost_cat text not null default '',
  lost_reason text not null default '',
  sold_area numeric,
  plot_no text not null default '',
  assigned_at timestamptz,
  first_contact_at timestamptz,
  reassign_count int not null default 0,
  eoi_applicable boolean,
  eoi_date date,
  reservation_date date,
  contract_date date,
  total_sold_value numeric,
  stage_meta jsonb not null default '{}'::jsonb,
  contract_reminded_at date,
  lead_date date not null default current_date,
  last_contact date,
  notes text not null default '',
  log jsonb not null default '[]'::jsonb,
  dup jsonb not null default '[]'::jsonb,
  dup_cleared boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists leads_owner_idx   on public.leads(owner);
create index if not exists leads_status_idx  on public.leads(status);
create index if not exists leads_phone_idx   on public.leads(phone);
create index if not exists leads_email_idx   on public.leads(lower(email));
create index if not exists leads_company_idx on public.leads(lower(company));

create table if not exists public.lead_activity (        -- server-side audit trail
  id bigint generated always as identity primary key,
  lead_id text references public.leads(id) on delete cascade,
  actor uuid,
  actor_name text not null default '',
  action text not null default '',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists lead_activity_lead_idx on public.lead_activity(lead_id);

create table if not exists public.external_sales (       -- deals closed outside the system
  id text primary key,
  member_id uuid not null references public.profiles(id) on delete cascade,
  sale_date date not null default current_date,
  amount numeric not null,
  project text not null default '',
  description text not null default '',
  status text not null default 'pending',  -- pending | confirmed | rejected
  confirmed_by text not null default '',
  confirmed_date date,
  created_at timestamptz not null default now()
);

create table if not exists public.import_log (
  id bigint generated always as identity primary key,
  method text not null default '',
  added int not null default 0,
  updated int not null default 0,
  dupes int not null default 0,
  failed int not null default 0,
  assigned int not null default 0,
  actor uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb
);
insert into public.app_settings(key, value) values ('team_target', '0'::jsonb)
on conflict (key) do nothing;
insert into public.app_settings(key, value)
values ('crm_settings', '{"autoAssign":false,"autoReassign":false,"vipHours":4,"neglectHours":48,"notifyDirector":true,"siteMgrEmail":"","adminCal":false,"workloadCap":140}'::jsonb)
on conflict (key) do nothing;


-- back-fill columns for projects created from earlier schema versions (no-ops on fresh installs)
alter table public.profiles add column if not exists phone text not null default '';
alter table public.leads
  add column if not exists next_time text not null default '',
  add column if not exists meeting_date date,
  add column if not exists meeting_time text not null default '',
  add column if not exists qual_status text not null default '',
  add column if not exists temperature text not null default '',
  add column if not exists qual_notes text not null default '',
  add column if not exists lost_cat text not null default '',
  add column if not exists lost_reason text not null default '',
  add column if not exists sold_area numeric,
  add column if not exists plot_no text not null default '',
  add column if not exists assigned_at timestamptz,
  add column if not exists first_contact_at timestamptz,
  add column if not exists reassign_count int not null default 0,
  add column if not exists phone2 text not null default '',
  add column if not exists eoi_applicable boolean,
  add column if not exists eoi_date date,
  add column if not exists reservation_date date,
  add column if not exists contract_date date,
  add column if not exists total_sold_value numeric,
  add column if not exists stage_meta jsonb not null default '{}'::jsonb,
  add column if not exists contract_reminded_at date;

-- ---------- 3. HELPER FUNCTIONS ----------
create or replace function public.app_role() returns public.user_role
language sql stable security definer set search_path = public as
$$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select public.app_role() = 'admin' $$;

create or replace function public.is_active() returns boolean
language sql stable security definer set search_path = public as
$$ select auth.uid() is not null and public.app_role() not in ('pending','disabled') $$;

create or replace function public.can_view_all() returns boolean
language sql stable security definer set search_path = public as
$$ select public.app_role() in
   ('admin','director','salesops','marketing','marketingmgr','ceo','cfo','hrdirector') $$;

-- everyone in the reports-to tree under a root user (including the root)
create or replace function public.team_ids(root uuid) returns setof uuid
language sql stable security definer set search_path = public as $$
  with recursive t as (
    select id from public.profiles where id = root
    union all
    select p.id from public.profiles p join t on p.manager_id = t.id
  ) select id from t
$$;

create or replace function public.can_see_lead(l_owner uuid, l_status text) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_active() and (
    public.can_view_all()
    or l_owner = auth.uid()
    or (public.app_role() in ('manager','director')
        and l_owner in (select public.team_ids(auth.uid())))
    or (public.app_role() = 'finance' and l_status = 'Won')
  )
$$;

-- ---------- 4. AUTH: auto-create profile on signup; FIRST user becomes ADMIN ----------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'name', split_part(coalesce(new.email,''), '@', 1)),
    case when not exists (select 1 from public.profiles) then 'admin'::public.user_role
         else 'pending'::public.user_role end
  );
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users for each row execute function public.handle_new_user();

-- ---------- 5. PERMISSION ENFORCEMENT (the authority matrix, server-side) ----------
-- Marketing edits lead data · Sales Ops distributes · owner/manager updates progress
-- · Finance/CFO edits cash · everyone else read-only. Enforced per column change.
create or replace function public.enforce_lead_permissions() returns trigger
language plpgsql security definer set search_path = public as $$
declare r public.user_role := public.app_role();
        is_mkt boolean := r in ('marketing','marketingmgr');
        is_owner boolean := old.owner = auth.uid();
        is_team_mgr boolean := r in ('manager','director')
                               and old.owner in (select public.team_ids(auth.uid()));
begin
  -- strictly-marketing lead data (identity & origin)
  if (new.custno, new.phone, new.email, new.source, new.priority, new.lead_date)
     is distinct from
     (old.custno, old.phone, old.email, old.source, old.priority, old.lead_date)
     and not is_mkt then
    raise exception 'Only the Marketing team can edit this lead data';
  end if;
  -- shared lead data: marketing OR the assigned salesperson / their manager
  if (new.name, new.company, new.phone2, new.project, new.land)
     is distinct from
     (old.name, old.company, old.phone2, old.project, old.land)
     and not (is_mkt or is_owner or is_team_mgr) then
    raise exception 'Only marketing or the assigned salesperson can edit these fields';
  end if;
  -- distribution
  if new.owner is distinct from old.owner then
    if not ( r in ('salesops','admin','director')
             or (r = 'manager' and (old.owner is null
                 or old.owner in (select public.team_ids(auth.uid()))))
             or (is_mkt and old.owner is null) ) then
      raise exception 'You are not allowed to reassign this lead';
    end if;
  end if;
  -- progress fields
  if (new.status, new.next_followup, new.next_time, new.meeting_date, new.meeting_time, new.offer_sent, new.offer_date,
      new.notes, new.last_contact, new.won_date, new.dup, new.dup_cleared,
      new.industry, new.qual_status, new.temperature, new.qual_notes,
      new.lost_cat, new.lost_reason, new.assigned_at, new.first_contact_at,
      new.reassign_count)
     is distinct from
     (old.status, old.next_followup, old.next_time, old.meeting_date, old.meeting_time, old.offer_sent, old.offer_date,
      old.notes, old.last_contact, old.won_date, old.dup, old.dup_cleared,
      old.industry, old.qual_status, old.temperature, old.qual_notes,
      old.lost_cat, old.lost_reason, old.assigned_at, old.first_contact_at,
      old.reassign_count)
     and not (is_mkt or is_owner or is_team_mgr or r in ('salesops','admin')) then
    raise exception 'You can only update leads assigned to you';
  end if;
  -- transaction stages & commercial values: owner / manager / Sales Ops
  if (new.eoi_applicable, new.eoi_date, new.reservation_date, new.contract_date,
      new.total_sold_value, new.stage_meta, new.contract_reminded_at,
      new.value, new.sold_area, new.plot_no)
     is distinct from
     (old.eoi_applicable, old.eoi_date, old.reservation_date, old.contract_date,
      old.total_sold_value, old.stage_meta, old.contract_reminded_at,
      old.value, old.sold_area, old.plot_no)
     and not (is_owner or is_team_mgr or r in ('salesops','admin')
              or (r in ('finance','cfo') and old.status = 'Won')) then
    raise exception 'Not allowed to edit transaction or commercial fields';
  end if;
  -- cash confirmation lifecycle (THE v4 FIX):
  --   marking the cash "pending" during the won transition → anyone allowed to
  --   progress the deal;  confirming / reopening → Finance & CFO only
  if (new.cash_status, new.cash_by, new.cash_date)
     is distinct from (old.cash_status, old.cash_by, old.cash_date) then
    if r in ('finance','cfo') then
      null; -- AR team: confirm, edit, reopen — all allowed
    elsif new.cash_status = 'pending'
          and coalesce(new.cash_by,'') = '' and new.cash_date is null
          and (is_owner or is_team_mgr or is_mkt or r in ('salesops','admin')) then
      null; -- won transition marks the deal as awaiting AR — allowed
    else
      raise exception 'Only Accounts Receivable confirms cash values';
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists leads_enforce on public.leads;
create trigger leads_enforce before update on public.leads
for each row execute function public.enforce_lead_permissions();

-- profiles: admin edits anyone; you may edit your own name/title;
-- managers/directors/executives may claim unplaced members or release their own
create or replace function public.enforce_profile_permissions() returns trigger
language plpgsql security definer set search_path = public as $$
declare r public.user_role := public.app_role();
begin
  if public.is_admin() then new.email := old.email; return new; end if;
  if new.id = auth.uid() then
    if (new.role, new.annual_target, new.manager_id, new.email)
       is distinct from (old.role, old.annual_target, old.manager_id, old.email) then
      raise exception 'Only the administrator can change roles, targets or hierarchy for yourself';
    end if;
    if new.last_login is distinct from old.last_login then return new; end if;
    return new; -- own name/title/department edits are fine
  end if;
  -- claiming / releasing team members
  if (new.name, new.email, new.role, new.title, new.department, new.annual_target)
     is distinct from
     (old.name, old.email, old.role, old.title, old.department, old.annual_target) then
    raise exception 'Only the administrator can edit other members';
  end if;
  if new.manager_id is distinct from old.manager_id then
    if r in ('manager','director','ceo','cfo','hrdirector','marketingmgr')
       and ( (new.manager_id = auth.uid() and old.manager_id is null)      -- claim
          or (old.manager_id = auth.uid() and new.manager_id is null) )    -- release
    then return new;
    else raise exception 'Only the administrator can move placed members'; end if;
  end if;
  return new;
end $$;
drop trigger if exists profiles_enforce on public.profiles;
create trigger profiles_enforce before update on public.profiles
for each row execute function public.enforce_profile_permissions();

-- ---------- 6. ACTIVITY LOG (automatic audit trail) ----------
create or replace function public.log_lead_activity() returns trigger
language plpgsql security definer set search_path = public as $$
declare a_name text := coalesce((select name from public.profiles where id = auth.uid()), 'system');
begin
  if tg_op = 'INSERT' then
    insert into public.lead_activity(lead_id, actor, actor_name, action, details)
    values (new.id, auth.uid(), a_name, 'created', jsonb_build_object('source', new.source));
  elsif tg_op = 'UPDATE' then
    insert into public.lead_activity(lead_id, actor, actor_name, action, details)
    values (new.id, auth.uid(), a_name, 'updated', jsonb_build_object(
      'status', case when new.status is distinct from old.status
                     then old.status || ' → ' || new.status end,
      'owner_changed', new.owner is distinct from old.owner,
      'cash', case when new.cash_status is distinct from old.cash_status
                   then new.cash_status end));
  elsif tg_op = 'DELETE' then
    insert into public.lead_activity(lead_id, actor, actor_name, action)
    values (old.id, auth.uid(), a_name, 'deleted');
    return old;
  end if;
  return new;
end $$;
drop trigger if exists leads_activity_ins on public.leads;
create trigger leads_activity_ins after insert on public.leads
for each row execute function public.log_lead_activity();
drop trigger if exists leads_activity_upd on public.leads;
create trigger leads_activity_upd after update on public.leads
for each row execute function public.log_lead_activity();

-- ---------- 7. DUPLICATE DETECTION (server-side) ----------
-- STRICT: same full phone number, same email, or (client-side) name AND company
-- both identical. norm_phone below is a shared utility for phone normalization.
create or replace function public.norm_phone(p text) returns text
language plpgsql immutable as $$
declare d text := regexp_replace(coalesce(p,''), '[^0-9]', '', 'g');
begin
  while left(d,2) = '00' loop d := substr(d,3); end loop;
  if d ~ '^20[0-9]{10}$'  then return d; end if;
  if d ~ '^966[0-9]{9}$'  then return d; end if;
  if d ~ '^971[0-9]{9}$'  then return d; end if;
  if d ~ '^01[0-9]{9}$'   then return '20'||substr(d,2); end if;
  if d ~ '^1[0-9]{9}$'    then return '20'||d; end if;
  if d ~ '^05[0-9]{8}$'   then return '966'||substr(d,2); end if;
  if d ~ '^5[0-9]{8}$'    then return '966'||d; end if;
  if length(d) between 11 and 15 then return d; end if;
  return '';  -- fragments never match anything
end $$;

create or replace function public.find_duplicate_leads(
  p_phone text, p_email text, p_company text, p_exclude text default null)
returns setof text language sql stable security definer set search_path = public as $$
  -- STRICT: same full phone number (compared on the last 10 digits of FULL
  -- numbers only, so different countries can never collide) or same email.
  -- Company-alone / name-alone are NOT duplicates (p_company kept for
  -- signature compatibility but intentionally unused).
  with me as (select regexp_replace(coalesce(p_phone,''),'\D','','g') as ph)
  select l.id from public.leads l, me
  where (p_exclude is null or l.id <> p_exclude) and (
    (length(me.ph) >= 10 and (
      (length(regexp_replace(l.phone,'\D','','g'))  >= 10 and right(regexp_replace(l.phone,'\D','','g'),10)  = right(me.ph,10))
      or
      (length(regexp_replace(l.phone2,'\D','','g')) >= 10 and right(regexp_replace(l.phone2,'\D','','g'),10) = right(me.ph,10))
    ))
    or (nullif(lower(trim(coalesce(p_email,''))),'') is not null
        and lower(trim(l.email)) = lower(trim(p_email)))
  )
$$;

-- ---------- 8. FAIR ROTATION (server-side option) ----------
-- Balances open-lead count + land area (every 10,000 sqm ≈ one lead),
-- placing the largest opportunities first.
create or replace function public.assign_leads_fair(p_lead_ids text[])
returns int language plpgsql security definer set search_path = public as $$
declare rep record; l record; assigned int := 0;
begin
  if public.app_role() not in ('salesops','marketing','marketingmgr','admin') then
    raise exception 'Not allowed to distribute leads';
  end if;
  create temp table _load on commit drop as
    select p.id, p.name,
      count(ld.id) filter (where ld.status not in ('Won','Lost'))
      + coalesce(sum(ld.land) filter (where ld.status not in ('Won','Lost')),0)/10000
      as load
    from public.profiles p
    left join public.leads ld on ld.owner = p.id
    where p.role in ('sales','manager')
    group by p.id, p.name;
  if not exists (select 1 from _load) then return 0; end if;
  for l in select * from public.leads
           where id = any(p_lead_ids) and owner is null
           order by coalesce(land,0) desc loop
    select * into rep from _load order by load asc limit 1;
    update public.leads set owner = rep.id,
      next_followup = coalesce(next_followup, current_date + 2),
      log = jsonb_build_array(jsonb_build_object(
        'd', to_char(current_date,'YYYY-MM-DD'), 'by', 'system',
        't', 'Auto-assigned to ' || rep.name || ' via fair rotation')) || log
      where id = l.id;
    update _load set load = load + 1 + coalesce(l.land,0)/10000 where id = rep.id;
    assigned := assigned + 1;
  end loop;
  return assigned;
end $$;

-- ---------- 9. ROW LEVEL SECURITY ----------
alter table public.profiles       enable row level security;
alter table public.leads          enable row level security;
alter table public.lead_activity  enable row level security;
alter table public.external_sales enable row level security;
alter table public.import_log     enable row level security;
alter table public.app_settings   enable row level security;

-- profiles
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select
  using (public.is_active() or id = auth.uid());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update
  using (public.is_admin() or id = auth.uid()
         or public.app_role() in ('manager','director','ceo','cfo','hrdirector','marketingmgr'))
  with check (true);  -- column rules enforced by the profiles_enforce trigger

-- leads
drop policy if exists leads_select on public.leads;
create policy leads_select on public.leads for select
  using (public.can_see_lead(owner, status));
drop policy if exists leads_insert on public.leads;
create policy leads_insert on public.leads for insert
  with check (
    public.app_role() in ('marketing','marketingmgr')
    -- salespeople and managers may add their OWN leads, but only from the
    -- self-generated channels; sales operations may add the same channels
    -- for anyone (they distribute afterwards)
    or (public.app_role() in ('sales','manager')
        and owner = auth.uid()
        and source in ('Personal','Management'))
    or (public.app_role() = 'salesops'
        and source in ('Personal','Management'))
  );
drop policy if exists leads_update on public.leads;
create policy leads_update on public.leads for update
  using (public.can_see_lead(owner, status))
  with check (true);  -- column rules enforced by the leads_enforce trigger
drop policy if exists leads_delete on public.leads;
create policy leads_delete on public.leads for delete
  using (public.app_role() in ('marketing','marketingmgr'));

-- lead_activity (read-only audit; written by triggers)
drop policy if exists activity_select on public.lead_activity;
create policy activity_select on public.lead_activity for select
  using (exists (select 1 from public.leads l
                 where l.id = lead_id and public.can_see_lead(l.owner, l.status)));

-- external_sales
drop policy if exists ext_select on public.external_sales;
create policy ext_select on public.external_sales for select
  using (public.is_active() and (
    public.can_view_all() or member_id = auth.uid()
    or (public.app_role() in ('manager','director')
        and member_id in (select public.team_ids(auth.uid())))));
drop policy if exists ext_insert on public.external_sales;
create policy ext_insert on public.external_sales for insert
  with check (public.is_active() and member_id = auth.uid());
drop policy if exists ext_update on public.external_sales;
create policy ext_update on public.external_sales for update
  using (public.app_role() in ('admin','director','manager','ceo','cfo','hrdirector','marketingmgr')
         and (member_id <> auth.uid() or public.is_admin())
         and (public.can_view_all()
              or member_id in (select public.team_ids(auth.uid()))))
  with check (true);

-- import_log
drop policy if exists implog_select on public.import_log;
create policy implog_select on public.import_log for select using (public.can_view_all());
drop policy if exists implog_insert on public.import_log;
create policy implog_insert on public.import_log for insert
  with check (public.app_role() in ('marketing','marketingmgr','admin'));

-- app_settings
drop policy if exists settings_select on public.app_settings;
create policy settings_select on public.app_settings for select using (public.is_active());
drop policy if exists settings_write on public.app_settings;
create policy settings_write  on public.app_settings for all
  using (public.is_admin()
         or (key = 'crm_settings' and public.app_role() in
             ('director','marketing','marketingmgr','salesops')))
  with check (public.is_admin()
         or (key = 'crm_settings' and public.app_role() in
             ('director','marketing','marketingmgr','salesops')));

-- ---------- 10. REALTIME ----------
do $do$ begin
  begin alter publication supabase_realtime add table public.leads; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.profiles; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.external_sales; exception when duplicate_object then null; end;
end $do$;

-- ============================================================================
-- STORAGE — stage documents (EOI / Reservation / Contract attachments)
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('deal-docs', 'deal-docs', false)
on conflict (id) do nothing;

drop policy if exists deal_docs_read on storage.objects;
create policy deal_docs_read on storage.objects for select
  using (bucket_id = 'deal-docs' and public.is_active());
drop policy if exists deal_docs_insert on storage.objects;
create policy deal_docs_insert on storage.objects for insert
  with check (bucket_id = 'deal-docs' and public.is_active()
              and public.app_role() not in ('marketing','marketingmgr'));
drop policy if exists deal_docs_delete on storage.objects;
create policy deal_docs_delete on storage.objects for delete
  using (bucket_id = 'deal-docs'
         and public.app_role() in ('salesops','admin','director'));

-- ============ per-user gamification record (streaks sync across devices) ============
create table if not exists public.user_gam (
  id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.user_gam enable row level security;
drop policy if exists gam_select on public.user_gam;
create policy gam_select on public.user_gam for select using (id = auth.uid());
drop policy if exists gam_insert on public.user_gam;
create policy gam_insert on public.user_gam for insert with check (id = auth.uid());
drop policy if exists gam_update on public.user_gam;
create policy gam_update on public.user_gam for update using (id = auth.uid()) with check (id = auth.uid());
