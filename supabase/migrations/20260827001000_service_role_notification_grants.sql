-- Server-side notification dispatcher permissions.
-- service_role bypasses RLS, but still requires explicit table privileges
-- on new Supabase projects.

grant usage on schema public to service_role;

grant select
on public.profiles
to service_role;

grant select, insert, update, delete
on public.device_tokens
to service_role;

grant select, update
on public.notification_preferences
to service_role;

grant select, insert, update, delete
on public.notifications
to service_role;

grant select, insert, update, delete
on public.notification_deliveries
to service_role;
