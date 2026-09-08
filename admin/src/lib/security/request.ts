export function rejectCrossOriginMutation(request: Request): Response | null {
  const origin = request.headers.get("origin");
  if (!origin) return null;
  let requestOrigin: string;
  try {
    requestOrigin = new URL(request.url).origin;
  } catch {
    return Response.json({ error: "مصدر الطلب غير صالح." }, { status: 403 });
  }
  return origin === requestOrigin
    ? null
    : Response.json({ error: "رُفض طلب من مصدر خارجي." }, { status: 403 });
}
