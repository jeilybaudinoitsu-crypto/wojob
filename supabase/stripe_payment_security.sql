-- Apply this once to projects where the previous subscription update policy
-- has already been installed. Paid plans are updated only by the Stripe webhook.
revoke update on public.empresas from public, anon, authenticated;

drop policy if exists "WoJob admins update company subscription"
  on public.empresas;
