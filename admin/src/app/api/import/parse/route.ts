import { authorizeAdminApi } from "@/lib/auth/context";
import { getFallbackCategories } from "@/lib/import/classification";
import { toImportRowDatabaseContract } from "@/lib/import/database-contract";
import { detectSourceType, parseQuestionFile } from "@/lib/import/parser";
import { processImportRows } from "@/lib/import/processor";
import type { CategoryDescriptor, ExistingQuestion } from "@/lib/import/types";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { rejectCrossOriginMutation } from "@/lib/security/request";

export const runtime = "nodejs";

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

async function loadClassificationContext(): Promise<{
  categories: CategoryDescriptor[];
  existingQuestions: ExistingQuestion[];
}> {
  const supabase = await createServerSupabaseClient();
  if (!supabase) return { categories: getFallbackCategories(), existingQuestions: [] };

  const [categoriesResult, questionsResult] = await Promise.all([
    supabase
      .from("categories")
      .select("id, slug, name_ar, parent_id, keywords")
      .eq("is_active", true)
      .order("sort_order", { ascending: true }),
    supabase
      .from("questions")
      .select("id, question_text, normalized_text")
      .not("status", "eq", "archived")
      .limit(5000),
  ]);

  const categories: CategoryDescriptor[] = (categoriesResult.data ?? []).map((category) => ({
    id: String(category.id),
    slug: String(category.slug ?? ""),
    name: String(category.name_ar ?? category.slug ?? "قسم"),
    parentId: category.parent_id ? String(category.parent_id) : null,
    keywords: Array.isArray(category.keywords) ? category.keywords.map(String) : [],
  }));

  const existingQuestions: ExistingQuestion[] = (questionsResult.data ?? []).map((question) => ({
    id: String(question.id),
    text: String(question.question_text ?? ""),
    normalizedText: question.normalized_text ? String(question.normalized_text) : null,
  }));

  return {
    categories: categories.length ? categories : getFallbackCategories(),
    existingQuestions,
  };
}

export async function POST(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const formData = await request.formData();
    const file = formData.get("file");
    if (!(file instanceof File)) {
      return Response.json({ error: "لم يتم إرفاق ملف." }, { status: 400 });
    }

    const sourceType = detectSourceType(file.name);
    const rawRows = await parseQuestionFile(await file.arrayBuffer(), file.name);
    const { categories, existingQuestions } = await loadClassificationContext();
    const processed = processImportRows(rawRows, file.name, categories, existingQuestions);
    const supabase = await createServerSupabaseClient();

    if (!supabase) {
      return Response.json({
        batchId: `dev-${Date.now()}`,
        filename: file.name,
        sourceType,
        developmentFallback: true,
        categories,
        ...processed,
      });
    }

    const { data: batch, error: batchError } = await supabase
      .from("import_batches")
      .insert({
        filename: file.name,
        source_type: sourceType,
        status: "validating",
        total_rows: processed.summary.total,
        valid_rows: processed.summary.valid,
        invalid_rows: processed.summary.invalid,
        review_rows: processed.summary.review,
        duplicate_rows: processed.summary.duplicate,
        settings: { classifier: "rules-v1", similarity_threshold: 0.72 },
        created_by: authorization.context.id,
      })
      .select("id")
      .single();

    if (batchError || !batch) throw new Error(batchError?.message || "تعذر إنشاء دفعة الاستيراد.");

    const importRows = processed.rows.map((row) => ({
      batch_id: batch.id,
      row_number: row.rowNumber,
      raw_data: row.raw,
      normalized_data: toImportRowDatabaseContract(row),
      status: row.status,
      errors: row.errors,
      warnings: row.warnings,
      classification: row.classification,
      confidence: row.classification.confidence,
      duplicate_question_id: row.duplicateQuestionId,
      similar_question_ids: row.similarQuestions
        .filter((similar) => similar.source === "database" && uuidPattern.test(similar.id))
        .map((similar) => similar.id),
    }));

    for (let start = 0; start < importRows.length; start += 250) {
      const { error } = await supabase.from("import_rows").insert(importRows.slice(start, start + 250));
      if (error) {
        await supabase.from("import_batches").update({ status: "failed", error_summary: { message: error.message } }).eq("id", batch.id);
        throw new Error(error.message);
      }
    }

    const batchStatus = processed.summary.review || processed.summary.invalid || processed.summary.duplicate ? "review" : "ready";
    await supabase.from("import_batches").update({ status: batchStatus }).eq("id", batch.id);

    return Response.json({
      batchId: batch.id,
      filename: file.name,
      sourceType,
      developmentFallback: false,
      categories,
      ...processed,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "تعذر تحليل الملف.";
    return Response.json({ error: message }, { status: 400 });
  }
}
