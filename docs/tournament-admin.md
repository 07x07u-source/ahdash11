# Tournament Admin Center

Route: `/tournaments` in the existing Next.js operations shell.

The center reports total tournaments, live tournaments, registered teams, and pending registrations. Operators can search by tournament name/ID and inspect status, capacity, match completion, registration backlog, and last update.

Admin actions are intentionally narrow:

- Cancel a non-completed tournament without deleting teams, matches, or event history.
- Reopen a cancelled tournament into registration.
- Refresh operational state.

Every mutation rejects cross-origin browser requests, requires the `admin` role, validates UUID/action with Zod, and relies on Tournament RLS. Moderators receive read access only. If the migration is not deployed, the center shows a precise migration-pending state rather than fake production data.

Login/profile imagery remains managed through the existing Media Library and App Content workflows. No parallel upload store or public font hosting was introduced.

