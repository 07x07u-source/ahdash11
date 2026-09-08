import { z } from "zod";

export const tournamentAdminMutationSchema = z.object({
  id: z.string().uuid(),
  action: z.enum(["cancel", "reopen"]),
});

export type TournamentAdminMutation = z.infer<typeof tournamentAdminMutationSchema>;
