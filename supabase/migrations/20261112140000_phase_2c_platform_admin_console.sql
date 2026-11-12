-- Phase 2C: database-enforced platform-admin publication workflow.
-- No administrator is seeded by this migration. A trusted operator must add an
-- approved Auth user UUID to app_private.platform_admins after separate approval.

create table app_private.platform_admins (
  user_id uuid primary key references auth.users(id) on delete restrict,
  granted_by uuid references auth.users(id) on delete set null,
  granted_at timestamptz not null default pg_catalog.now(),
  note text
);

create table app_private.publication_audit_events (
  id bigint generated always as identity primary key,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  entity_type text not null check (entity_type in ('business','category','listing')),
  entity_id uuid not null,
  action text not null check (action in ('publish','unpublish')),
  old_status text not null,
  new_status text not null,
  reason text,
  created_at timestamptz not null default pg_catalog.now()
);
create index publication_audit_events_entity_idx
  on app_private.publication_audit_events(entity_type, entity_id, created_at desc);
create index publication_audit_events_actor_idx
  on app_private.publication_audit_events(actor_user_id, created_at desc);

alter table app_private.platform_admins enable row level security;
alter table app_private.publication_audit_events enable row level security;
revoke all on app_private.platform_admins, app_private.publication_audit_events from public, anon, authenticated;
revoke all on sequence app_private.publication_audit_events_id_seq from public, anon, authenticated;

create or replace function app_private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from app_private.platform_admins a where a.user_id = auth.uid()
  );
$$;
revoke all on function app_private.is_platform_admin() from public, anon, authenticated;
grant execute on function app_private.is_platform_admin() to authenticated;

create or replace function app_private.platform_admin_queue()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare result jsonb;
begin
  if not app_private.is_platform_admin() then
    raise exception 'Platform administrator access required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(q.item order by q.created_at desc), '[]'::jsonb)
  into result
  from (
    select b.created_at, jsonb_build_object(
      'entity_type','business','id',b.id,'business_id',b.business_id,
      'name',b.name,'status',b.publication_status,'created_at',b.created_at,
      'owner_count',(select count(*) from app_private.business_memberships m
        where m.business_id=b.id and m.role='owner' and m.status='active')
    ) as item
    from app_private.businesses b
    where b.publication_status in ('draft','published','suspended')
    union all
    select c.created_at, jsonb_build_object(
      'entity_type','category','id',c.id,'business_id',b.business_id,
      'business_name',b.name,'name',c.name,'status',c.publication_status,
      'created_at',c.created_at
    )
    from app_private.categories c
    join app_private.businesses b on b.id=c.business_id
    where c.publication_status in ('draft','published')
    union all
    select l.created_at, jsonb_build_object(
      'entity_type','listing','id',l.id,'business_id',b.business_id,
      'business_name',b.name,'name',l.name,'kind',l.kind,
      'status',l.publication_status,'created_at',l.created_at
    )
    from app_private.listings l
    join app_private.businesses b on b.id=l.business_id
    where l.publication_status in ('draft','published')
  ) q;
  return result;
end;
$$;
revoke all on function app_private.platform_admin_queue() from public, anon, authenticated;
grant execute on function app_private.platform_admin_queue() to authenticated;

create or replace function app_private.set_publication_status(
  p_entity_type text,
  p_entity_id uuid,
  p_new_status text,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
  old_value text;
  action_value text;
  parent_status text;
begin
  if actor is null or not app_private.is_platform_admin() then
    raise exception 'Platform administrator access required' using errcode = '42501';
  end if;
  if p_entity_type not in ('business','category','listing') then
    raise exception 'Unsupported publication entity' using errcode = '22023';
  end if;
  if p_reason is not null and char_length(p_reason) > 500 then
    raise exception 'Reason must be 500 characters or fewer' using errcode = '22023';
  end if;

  if p_entity_type = 'business' then
    if p_new_status not in ('published','suspended') then
      raise exception 'Business status must be published or suspended' using errcode = '22023';
    end if;
    select publication_status into old_value from app_private.businesses where id=p_entity_id for update;
    if not found then raise exception 'Business not found' using errcode = 'P0002'; end if;
    if old_value = 'suspended' and p_new_status = 'published' then
      raise exception 'Suspended businesses require a separate reinstatement review' using errcode = '42501';
    end if;
    update app_private.businesses set publication_status=p_new_status where id=p_entity_id;
  elsif p_entity_type = 'category' then
    if p_new_status not in ('published','draft') then
      raise exception 'Category status must be published or draft' using errcode = '22023';
    end if;
    select c.publication_status,b.publication_status into old_value,parent_status
      from app_private.categories c join app_private.businesses b on b.id=c.business_id
      where c.id=p_entity_id for update of c;
    if not found then raise exception 'Category not found' using errcode = 'P0002'; end if;
    if old_value = 'archived' then raise exception 'Archived categories cannot be restored here' using errcode = '42501'; end if;
    if p_new_status='published' and parent_status <> 'published' then
      raise exception 'Publish the parent business before its category' using errcode = '23514';
    end if;
    update app_private.categories set publication_status=p_new_status where id=p_entity_id;
  else
    if p_new_status not in ('published','draft') then
      raise exception 'Listing status must be published or draft' using errcode = '22023';
    end if;
    select l.publication_status,b.publication_status into old_value,parent_status
      from app_private.listings l join app_private.businesses b on b.id=l.business_id
      where l.id=p_entity_id for update of l;
    if not found then raise exception 'Listing not found' using errcode = 'P0002'; end if;
    if old_value = 'archived' then raise exception 'Archived listings cannot be restored here' using errcode = '42501'; end if;
    if p_new_status='published' and parent_status <> 'published' then
      raise exception 'Publish the parent business before its listing' using errcode = '23514';
    end if;
    update app_private.listings set publication_status=p_new_status where id=p_entity_id;
  end if;

  if old_value is distinct from p_new_status then
    action_value := case when p_new_status='published' then 'publish' else 'unpublish' end;
    insert into app_private.publication_audit_events(
      actor_user_id,entity_type,entity_id,action,old_status,new_status,reason
    ) values (actor,p_entity_type,p_entity_id,action_value,old_value,p_new_status,nullif(pg_catalog.btrim(p_reason),''));
  end if;
end;
$$;
revoke all on function app_private.set_publication_status(text,uuid,text,text) from public, anon, authenticated;
grant execute on function app_private.set_publication_status(text,uuid,text,text) to authenticated;

-- Only invoker-rights wrappers are exposed through the Data API.
create or replace function admin_api.platform_admin_queue()
returns jsonb
language sql
security invoker
set search_path = ''
as $$ select app_private.platform_admin_queue(); $$;

create or replace function admin_api.set_publication_status(
  p_entity_type text, p_entity_id uuid, p_new_status text, p_reason text default null
)
returns void
language sql
security invoker
set search_path = ''
as $$ select app_private.set_publication_status(p_entity_type,p_entity_id,p_new_status,p_reason); $$;

revoke all on function admin_api.platform_admin_queue() from public, anon, authenticated;
revoke all on function admin_api.set_publication_status(text,uuid,text,text) from public, anon, authenticated;
grant execute on function admin_api.platform_admin_queue() to authenticated;
grant execute on function admin_api.set_publication_status(text,uuid,text,text) to authenticated;

comment on table app_private.platform_admins is
  'Trusted platform administrator allowlist. Provision by controlled SQL only; never from browser or owner APIs.';
comment on table app_private.publication_audit_events is
  'Append-only audit record of platform-admin publication decisions.';
