-- Keep the historically deployed Tournament registration RPC type-correct.
-- The signature is intentionally unchanged so CREATE OR REPLACE preserves ACLs.
create or replace function public.review_tournament_registration(
  p_registration_id uuid,
  p_approve boolean
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  registration public.tournament_registrations%rowtype;
  target public.tournaments%rowtype;
  team_id uuid;
  player_value jsonb;
begin
  caller := public.require_active_user();
  select registration_row.* into registration
  from public.tournament_registrations registration_row
  join public.tournaments tournament on tournament.id = registration_row.tournament_id
  where registration_row.id = p_registration_id and tournament.organizer_id = caller.id
  for update of registration_row;
  if not found then raise exception using errcode = '42501', message = 'Registration not owned'; end if;
  select * into target from public.tournaments where id = registration.tournament_id for update;
  if target.status <> 'registration' then raise exception using errcode = '55000', message = 'Registration is closed'; end if;
  if p_approve and (select count(*) from public.tournament_teams where tournament_id = target.id and status = 'approved') >= target.capacity then
    raise exception using errcode = '22023', message = 'Tournament capacity reached';
  end if;
  update public.tournament_registrations
  set status = case
        when p_approve then 'approved'::public.tournament_team_status
        else 'rejected'::public.tournament_team_status
      end,
      reviewed_by = caller.id, reviewed_at = clock_timestamp()
  where id = registration.id;
  if not p_approve then return null; end if;
  insert into public.tournament_teams(tournament_id, owner_user_id, name, status)
  values (target.id, registration.requested_by, registration.team_name, 'approved')
  returning id into team_id;
  for player_value in select value from jsonb_array_elements(registration.roster) loop
    insert into public.tournament_players(tournament_id, team_id, user_id, display_name, is_captain)
    values (
      target.id, team_id, (player_value ->> 'user_id')::uuid,
      trim(player_value ->> 'display_name'),
      coalesce((player_value ->> 'is_captain')::boolean, false)
    );
  end loop;
  return team_id;
end;
$$;

