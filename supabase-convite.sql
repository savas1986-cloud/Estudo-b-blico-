-- Raízes & Graça — atualização: link de convite
-- Supabase → SQL Editor → New query → cole e clique em Run.

-- Nome do grupo a partir do código (tela "Você foi convidada!"). Só revela o nome e o nº de participantes.
create or replace function public.group_preview(p_code text)
returns table(name text, member_count int) language sql stable security definer set search_path = public as $$
  select g.name, (select count(*)::int from public.members m where m.group_id = g.id)
  from public.groups g where g.code = upper(trim(p_code));
$$;
revoke all on function public.group_preview(text) from public, anon;
grant execute on function public.group_preview(text) to authenticated;
