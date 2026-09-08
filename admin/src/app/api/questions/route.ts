import { z } from "zod";
import { authorizeAdminApi } from "@/lib/auth/context";
import {
  createPartyQuestionSchema,
  toCreatePartyQuestionRpcParams,
} from "@/lib/questions/editor-contract";
import { rejectCrossOriginMutation } from "@/lib/security/request";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const crossOrigin = rejectCrossOriginMutation(request);
  if (crossOrigin) return crossOrigin;
  const authorization = await authorizeAdminApi("moderator");
  if (authorization.response || !authorization.context) return authorization.response;

  try {
    const input = createPartyQuestionSchema.parse(await request.json());
    const supabase = await createServerSupabaseClient();
    if (!supabase || authorization.context.isDevelopmentFallback) {
      return Response.json(
        {
          success: true,
          developmentFallback: true,
          question: {
            id: `draft-${Date.now()}`,
            status: "draft",
            question_format: input.questionFormat,
            needs_review: true,
          },
        },
        { status: 201 },
      );
    }

    const { data, error } = await supabase.rpc(
      "create_admin_party_question",
      toCreatePartyQuestionRpcParams(input),
    );
    if (error) throw new Error(error.message);
    if (input.questionFormat === "image" && input.imageMediaId) {
      const questionId = data && typeof data === "object" && "id" in data ? String(data.id) : "";
      if (!questionId) throw new Error("تعذر ربط أصل الوسائط بمسودة السؤال.");
      const { error: mediaError } = await supabase.rpc("attach_question_media_v5", {
        p_question_id: questionId,
        p_media_id: input.imageMediaId,
        p_caption: input.imageCaption || null,
        p_focal_x: input.focalX,
        p_focal_y: input.focalY,
      });
      if (mediaError) throw new Error(mediaError.message);
    }
    return Response.json({ success: true, developmentFallback: false, question: data }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return Response.json({ error: error.issues[0]?.message ?? "بيانات السؤال غير صالحة." }, { status: 400 });
    }
    return Response.json(
      { error: error instanceof Error ? error.message : "تعذر إنشاء مسودة السؤال." },
      { status: 400 },
    );
  }
}
