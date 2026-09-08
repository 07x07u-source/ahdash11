import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import { hasMinimumRole } from "@/lib/auth/roles";
import { assertCommittedImportResult } from "@/lib/import/database-contract";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

export const runtime = "nodejs";

const decisionSchema = z.object({
  rowNumber: z.number().int().min(2),
  action: z.enum(["approve", "skip"]),
  categoryId: z.string().min(1).nullable().optional(),
  subcategoryId: z.string().min(1).nullable().optional(),
  difficulty: z.enum(["easy", "medium", "hard", "expert"]).optional(),
});

const commitSchema = z.object({
  batchId: z.string().min(1),
  publish: z.boolean().default(false),
  approveAllReview: z.boolean().default(false),
  decisions: z.array(decisionSchema).max(5000).default([]),
});

export async function POST(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const body = commitSchema.parse(await request.json());

    if (body.publish && !hasMinimumRole(authorization.context.role, "admin")) {
      return Response.json({ error: "نشر الأسئلة مباشرة يتطلب دور مدير أو أعلى." }, { status: 403 });
    }

    const supabase = await createServerSupabaseClient();
    if (!supabase || body.batchId.startsWith("dev-")) {
      const approved = body.decisions.filter((decision) => decision.action === "approve").length;
      const skipped = body.decisions.filter((decision) => decision.action === "skip").length;
      return Response.json({
        success: true,
        developmentFallback: true,
        batchId: body.batchId,
        approved,
        skipped,
        message: "اكتملت محاكاة الاستيراد. اربط Supabase لحفظ الأسئلة فعليًا.",
      });
    }

    if (body.approveAllReview) {
      const { error } = await supabase
        .from("import_rows")
        .update({ status: "valid" })
        .eq("batch_id", body.batchId)
        .eq("status", "needs_review");
      if (error) throw new Error(error.message);
    }

    if (body.decisions.length) {
      const rowNumbers = body.decisions.map((decision) => decision.rowNumber);
      const { data: storedRows, error: readError } = await supabase
        .from("import_rows")
        .select("id, row_number, normalized_data")
        .eq("batch_id", body.batchId)
        .in("row_number", rowNumbers);
      if (readError) throw new Error(readError.message);

      const storedByRow = new Map((storedRows ?? []).map((row) => [Number(row.row_number), row]));
      for (const decision of body.decisions) {
        const stored = storedByRow.get(decision.rowNumber);
        if (!stored) continue;
        const normalizedData = { ...(stored.normalized_data as Record<string, unknown>) };
        if (decision.categoryId !== undefined) normalizedData.category_id = decision.categoryId;
        if (decision.subcategoryId !== undefined) normalizedData.subcategory_id = decision.subcategoryId;
        if (decision.difficulty) normalizedData.difficulty = decision.difficulty;
        normalizedData.needs_review = false;

        const { error } = await supabase
          .from("import_rows")
          .update({
            status: decision.action === "approve" ? "valid" : "skipped",
            normalized_data: normalizedData,
          })
          .eq("id", stored.id)
          .eq("batch_id", body.batchId);
        if (error) throw new Error(error.message);
      }
    }

    const { error: readyError } = await supabase
      .from("import_batches")
      .update({ status: "ready" })
      .eq("id", body.batchId);
    if (readyError) throw new Error(readyError.message);

    const { data, error: commitError } = await supabase.rpc("commit_party_import_batch", {
      p_batch_id: body.batchId,
      p_publish: body.publish,
    });
    if (commitError) throw new Error(commitError.message);
    assertCommittedImportResult(data);

    return Response.json({
      success: true,
      developmentFallback: false,
      batchId: body.batchId,
      result: data,
      message: body.publish ? "تم استيراد الأسئلة ونشرها." : "تم استيراد الأسئلة إلى قائمة المراجعة.",
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return Response.json({ error: "بيانات المراجعة غير صالحة.", details: error.issues }, { status: 400 });
    }
    const message = error instanceof Error ? error.message : "تعذر إكمال الاستيراد.";
    return Response.json({ error: message }, { status: 400 });
  }
}
