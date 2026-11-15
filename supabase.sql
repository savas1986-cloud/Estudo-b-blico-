-- =====================================================================
--  Raízes & Graça — banco da Comunidade (Supabase / PostgreSQL)
--  Como usar: Supabase → SQL Editor → New query → cole tudo → Run.
--  Pode rodar de novo sem problema (é idempotente).
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- Tabelas ----------
create table if not exists public.groups (
  id           uuid primary key default gen_random_uuid(),
  name         text not null check (char_length(name) between 1 and 80),
  description  text default '' check (char_length(description) <= 200),
  code         text not null unique,
  created_by   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  goal_title   text not null default 'Ler o Evangelho de Marcos juntas' check (char_length(goal_title) <= 120),
  goal_target  int  not null default 16 check (goal_target between 1 and 1189),
  goal_start   date not null default current_date
);

create table if not exists public.members (
  group_id     uuid not null references public.groups(id) on delete cascade,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  progress     int  not null default 0 check (progress >= 0),
  joined_at    timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.prayers (
  id          uuid primary key default gen_random_uuid(),
  group_id    uuid not null references public.groups(id) on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  author      text not null check (char_length(author) between 1 and 40),
  body        text not null check (char_length(body) between 1 and 1000),
  created_at  timestamptz not null default now()
);

create table if not exists public.intercessions (
  prayer_id   uuid not null references public.prayers(id) on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (prayer_id, user_id)
);

create table if not exists public.posts (
  id          uuid primary key default gen_random_uuid(),
  group_id    uuid not null references public.groups(id) on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  author      text not null check (char_length(author) between 1 and 40),
  kind        text not null default 'verse' check (kind in ('verse','note')),
  ref         text not null check (char_length(ref) <= 80),
  body        text not null check (char_length(body) <= 2000),
  note        text default '' check (char_length(note) <= 1000),
  created_at  timestamptz not null default now()
);

create index if not exists prayers_group_idx on public.prayers(group_id, created_at desc);
create index if not exists posts_group_idx   on public.posts(group_id, created_at desc);
create index if not exists members_user_idx  on public.members(user_id);

-- ---------- Funções auxiliares ----------
create or replace function public.is_member(gid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members where group_id = gid and user_id = auth.uid());
$$;

create or replace function public.is_group_owner(gid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.groups where id = gid and created_by = auth.uid());
$$;

-- Criar grupo (gera o código de convite e já inclui quem criou)
create or replace function public.create_group(p_name text, p_description text, p_display_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare gid uuid; c text; tries int := 0;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  loop
    c := upper(substr(regexp_replace(translate(coalesce(p_name,''),
           'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'),
           '[^A-Za-z]', '', 'g') || 'GRUPO', 1, 5)) || lpad((floor(random()*10000))::int::text, 4, '0');
    exit when not exists (select 1 from public.groups where code = c);
    tries := tries + 1; if tries > 20 then raise exception 'code_generation_failed'; end if;
  end loop;
  insert into public.groups(name, description, code, created_by)
    values (trim(p_name), coalesce(trim(p_description), ''), c, auth.uid()) returning id into gid;
  insert into public.members(group_id, user_id, display_name) values (gid, auth.uid(), trim(p_display_name));
  return gid;
end $$;

-- Entrar com código (quem não é membro não consegue listar grupos; só entra com o código)
create or replace function public.join_group(p_code text, p_display_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare gid uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  select id into gid from public.groups where code = upper(trim(p_code));
  if gid is null then raise exception 'invalid_code'; end if;
  insert into public.members(group_id, user_id, display_name) values (gid, auth.uid(), trim(p_display_name))
    on conflict (group_id, user_id) do update set display_name = excluded.display_name;
  return gid;
end $$;

-- Nome do grupo a partir do código (tela "Você foi convidada!"). Só revela o nome e o nº de participantes.
create or replace function public.group_preview(p_code text)
returns table(name text, member_count int) language sql stable security definer set search_path = public as $$
  select g.name, (select count(*)::int from public.members m where m.group_id = g.id)
  from public.groups g where g.code = upper(trim(p_code));
$$;
revoke all on function public.group_preview(text) from public, anon;
grant execute on function public.group_preview(text) to authenticated;

revoke all on function public.create_group(text, text, text) from public, anon;
revoke all on function public.join_group(text, text) from public, anon;
grant execute on function public.create_group(text, text, text) to authenticated;
grant execute on function public.join_group(text, text) to authenticated;

-- ---------- Segurança (Row Level Security) ----------
alter table public.groups        enable row level security;
alter table public.members       enable row level security;
alter table public.prayers       enable row level security;
alter table public.intercessions enable row level security;
alter table public.posts         enable row level security;

-- groups: só membros veem; membros podem editar a meta; só a criadora apaga
drop policy if exists g_select on public.groups;
create policy g_select on public.groups for select to authenticated using (public.is_member(id));
drop policy if exists g_update on public.groups;
create policy g_update on public.groups for update to authenticated using (public.is_member(id)) with check (public.is_member(id));
drop policy if exists g_delete on public.groups;
create policy g_delete on public.groups for delete to authenticated using (created_by = auth.uid());

-- members: membros veem as colegas; cada uma edita/sai só do próprio registro; a criadora pode remover alguém
drop policy if exists m_select on public.members;
create policy m_select on public.members for select to authenticated using (public.is_member(group_id));
drop policy if exists m_update on public.members;
create policy m_update on public.members for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists m_delete on public.members;
create policy m_delete on public.members for delete to authenticated using (user_id = auth.uid() or public.is_group_owner(group_id));

-- prayers: membros leem e publicam; apaga quem escreveu ou a criadora do grupo
drop policy if exists p_select on public.prayers;
create policy p_select on public.prayers for select to authenticated using (public.is_member(group_id));
drop policy if exists p_insert on public.prayers;
create policy p_insert on public.prayers for insert to authenticated with check (public.is_member(group_id) and user_id = auth.uid());
drop policy if exists p_delete on public.prayers;
create policy p_delete on public.prayers for delete to authenticated using (user_id = auth.uid() or public.is_group_owner(group_id));

-- intercessions ("Estou orando por você")
drop policy if exists i_select on public.intercessions;
create policy i_select on public.intercessions for select to authenticated
  using (exists (select 1 from public.prayers p where p.id = prayer_id and public.is_member(p.group_id)));
drop policy if exists i_insert on public.intercessions;
create policy i_insert on public.intercessions for insert to authenticated
  with check (user_id = auth.uid() and exists (select 1 from public.prayers p where p.id = prayer_id and public.is_member(p.group_id)));
drop policy if exists i_delete on public.intercessions;
create policy i_delete on public.intercessions for delete to authenticated using (user_id = auth.uid());

-- posts (partilhas de versículos e anotações)
drop policy if exists s_select on public.posts;
create policy s_select on public.posts for select to authenticated using (public.is_member(group_id));
drop policy if exists s_insert on public.posts;
create policy s_insert on public.posts for insert to authenticated with check (public.is_member(group_id) and user_id = auth.uid());
drop policy if exists s_delete on public.posts;
create policy s_delete on public.posts for delete to authenticated using (user_id = auth.uid() or public.is_group_owner(group_id));

-- privilégios por coluna: ninguém altera código, dona ou datas; grupos e membros só são criados pelas funções acima
revoke all on public.groups, public.members, public.prayers, public.intercessions, public.posts from anon, authenticated;
grant select, delete on public.groups to authenticated;
grant update (name, description, goal_title, goal_target, goal_start) on public.groups to authenticated;
grant select, delete on public.members to authenticated;
grant update (display_name, progress) on public.members to authenticated;
grant select, insert, delete on public.prayers, public.intercessions, public.posts to authenticated;
