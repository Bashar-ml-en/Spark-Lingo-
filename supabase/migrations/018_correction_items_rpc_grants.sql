-- Complete the service-role-only correction-report boundary introduced in
-- 016_correction_items.sql. These RPCs are called only by sparky-ai after it
-- has authenticated the learner and created its server quota client.

revoke all on table public.learner_correction_items from anon, authenticated;

revoke all on function public.record_learner_correction_item(
    uuid, text, text, text, text, text
) from public, anon, authenticated;
grant execute on function public.record_learner_correction_item(
    uuid, text, text, text, text, text
) to service_role;

revoke all on function public.recent_learner_correction_items(
    uuid, text, integer
) from public, anon, authenticated;
grant execute on function public.recent_learner_correction_items(
    uuid, text, integer
) to service_role;
