-- Harden the learner progress boundary without rewriting applied migrations.
--
-- The mobile client must request server-authoritative mutations through
-- authenticated RPCs. It may read only its RLS-filtered progress data. In
-- particular, a daily-goal change must not be able to alter XP or streak
-- aggregates through a table update.

revoke all on table public.lesson_progress,
    public.xp_events,
    public.user_retention_stats from anon, authenticated;

grant select on table public.lesson_progress,
    public.xp_events,
    public.user_retention_stats to authenticated;

revoke all on function public.complete_lesson(text, text)
    from public, anon, service_role;
grant execute on function public.complete_lesson(text, text) to authenticated;

revoke all on function public.award_xp(text, integer, text, date)
    from public, anon, service_role;
grant execute on function public.award_xp(text, integer, text, date) to authenticated;

revoke all on function public.xp_today(date)
    from public, anon, service_role;
grant execute on function public.xp_today(date) to authenticated;

create or replace function public.set_daily_goal(p_daily_goal_xp integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user uuid := auth.uid();
begin
    if v_user is null then
        raise exception 'Authentication required' using errcode = '28000';
    end if;

    if p_daily_goal_xp is null
        or p_daily_goal_xp < 10
        or p_daily_goal_xp > 500 then
        raise exception 'Invalid daily XP goal' using errcode = '22023';
    end if;

    insert into public.user_retention_stats (user_id, daily_goal_xp)
    values (v_user, p_daily_goal_xp)
    on conflict (user_id) do update
    set daily_goal_xp = excluded.daily_goal_xp,
        updated_at = now();
end;
$$;

revoke all on function public.set_daily_goal(integer)
    from public, anon, service_role;
grant execute on function public.set_daily_goal(integer) to authenticated;
