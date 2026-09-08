-- Allow trusted server-side service_role to evaluate role helper functions.

grant execute on function public.current_app_role()
to service_role;

grant execute on function public.has_role(public.app_role)
to service_role;
