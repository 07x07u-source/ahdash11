import { z } from "zod";

const uuid = z.string().uuid();
const optionalText = (max: number) => z.string().trim().max(max).optional().nullable();
const color = z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional().nullable();
const visualStatus = z.enum(["fallback", "custom", "licensed"]);

const visualFields = {
  visualStatus,
  logoUrl: z.string().url().optional().nullable(),
  licenseReference: optionalText(300),
  primaryColor: color,
  secondaryColor: color,
};

const footballDataCreateBaseSchema = z.discriminatedUnion("entity", [
  z.object({
    entity: z.literal("country"),
    code: z.string().trim().toUpperCase().regex(/^[A-Z]{2,3}$/),
    nameAr: z.string().trim().min(2).max(80),
    nameEn: z.string().trim().min(2).max(80),
    featured: z.boolean().default(false),
  }).strict(),
  z.object({
    entity: z.literal("league"),
    countryId: uuid,
    nameAr: z.string().trim().min(2).max(100),
    nameEn: z.string().trim().min(2).max(100),
    shortName: optionalText(24),
    ...visualFields,
  }).strict(),
  z.object({
    entity: z.literal("club"),
    leagueId: uuid,
    nameAr: z.string().trim().min(2).max(100),
    nameEn: z.string().trim().min(2).max(100),
    shortName: optionalText(24),
    ...visualFields,
  }).strict(),
]);

export const footballDataCreateSchema = footballDataCreateBaseSchema.superRefine(
  (value, context) => {
    if (value.entity !== "country") validateVisualRights(value, context);
  },
);

export const footballDataUpdateSchema = z.object({
  entity: z.enum(["country", "league", "club"]),
  id: uuid,
  nameAr: z.string().trim().min(2).max(100).optional(),
  nameEn: z.string().trim().min(2).max(100).optional(),
  shortName: optionalText(24),
  active: z.boolean().optional(),
  featured: z.boolean().optional(),
  visualStatus: visualStatus.optional(),
  logoUrl: z.string().url().optional().nullable(),
  licenseReference: optionalText(300),
  primaryColor: color,
  secondaryColor: color,
}).strict().superRefine((value, context) => {
  if (value.entity === "country" && (value.visualStatus || value.logoUrl || value.licenseReference)) {
    context.addIssue({ code: "custom", message: "الدول لا تحمل حالة حقوق شعار." });
  }
  if (value.visualStatus) validateVisualRights(value, context);
});

export const footballDataDeleteSchema = z.object({
  entity: z.enum(["country", "league", "club"]),
  id: uuid,
}).strict();

export const socialTeamModerationSchema = z.object({
  teamId: uuid,
  status: z.enum(["active", "suspended", "archived"]),
  reason: z.string().trim().max(500).nullable(),
}).strict().superRefine((value, context) => {
  if (value.status !== "active" && !value.reason) {
    context.addIssue({ code: "custom", path: ["reason"], message: "سبب الإجراء مطلوب." });
  }
});

export const socialReportReviewSchema = z.object({
  reportId: uuid,
  status: z.enum(["reviewing", "resolved", "dismissed"]),
  note: z.string().trim().max(500).nullable(),
}).strict();

function validateVisualRights(
  value: { visualStatus?: string; logoUrl?: string | null; licenseReference?: string | null },
  context: z.RefinementCtx,
) {
  if (value.visualStatus === "fallback" && value.logoUrl) {
    context.addIssue({ code: "custom", path: ["logoUrl"], message: "الحالة البديلة لا تستخدم شعارًا." });
  }
  if ((value.visualStatus === "custom" || value.visualStatus === "licensed") && !value.logoUrl) {
    context.addIssue({ code: "custom", path: ["logoUrl"], message: "رابط الأصل مطلوب لهذه الحالة." });
  }
  if (value.visualStatus === "licensed" && !value.licenseReference) {
    context.addIssue({ code: "custom", path: ["licenseReference"], message: "مرجع الترخيص مطلوب." });
  }
}
