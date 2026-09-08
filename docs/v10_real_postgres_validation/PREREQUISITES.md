# Prerequisites for the real PostgreSQL validation gate

## Blocking condition

Docker is completely unavailable, not merely stopped. Supabase local development requires a working Docker-compatible container runtime, so the real database gate cannot continue safely on the current machine.

## Exact next human action

1. Install Docker Desktop for Windows using a supported backend (WSL 2 or Hyper-V, according to the Windows edition and organizational policy). Codex did not install or configure it.
2. Start Docker Desktop and wait until its engine reports healthy.
3. In a new terminal, verify both commands succeed:

   ```powershell
   docker --version
   docker info
   ```

   `docker info` must include a reachable Server/daemon result; a CLI-only installation is insufficient.
4. Make a Supabase CLI available locally or temporarily after Docker works. A project-local mechanism is preferred; verify with `supabase --version` or the equivalent local package invocation. Do not link the repository to a remote project.
5. Ensure the repository's local-only ports are free: 54320, 54321, 54322, 54323, and 54324.
6. Re-run this validation gate. It will then create disposable local environments for both the fresh-history path and the baseline-through-`20260831000300` upgrade path before running JWT/RLS and two-connection concurrency tests.

Installing system PostgreSQL separately is not required if local Supabase can run successfully through Docker.

## Safety prerequisites for the next run

- Do not supply a Production project reference, database URL, password, JWT, service credential, or Production user account.
- Do not run `supabase link` against Production.
- Test tooling must reject non-loopback hosts and must not provide a Production force override.
- Use only deterministic local test users, fixtures, and disposable databases.
- Keep raw voucher values, JWTs, and service credentials out of logs and evidence.

## Ready-to-resume condition

Resume only when `docker info` succeeds against a local daemon. Supabase CLI availability can then be handled with a safe local/temporary mechanism if it remains absent.

Until that condition is met:

**REAL POSTGRES GATE: BLOCKED**

