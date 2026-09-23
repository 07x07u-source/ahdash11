export const gameModes = [
  { slug: "classic", title: "كلاسيك", eyebrow: "النمط المعتمد", description: "سؤال كروي مباشر واختيار واحد صحيح.", color: "lime", discoverableOnWebsite: true, productStatus: "LIVE_MOBILE" },
  { slug: "true-false", title: "صح أو خطأ", eyebrow: "قيد الإعداد", description: "محرك موجود لكنه غير مطروح كمدخل معتمد حالياً.", color: "pink", discoverableOnWebsite: false, productStatus: "IMPLEMENTED_NOT_RELEASE_READY" },
  { slug: "speed", title: "السرعة", eyebrow: "قيد الإعداد", description: "محرك موجود لكنه غير مطروح كمدخل معتمد حالياً.", color: "gold", discoverableOnWebsite: false, productStatus: "IMPLEMENTED_NOT_RELEASE_READY" },
  { slug: "ordering", title: "رتّبهم", eyebrow: "مؤجل", description: "ليس ضمن المنتج النشط حالياً.", color: "blue", discoverableOnWebsite: false, productStatus: "DEFERRED" },
  { slug: "club-guess", title: "من النادي؟", eyebrow: "مؤجل", description: "ليس ضمن المنتج النشط حالياً.", color: "green", discoverableOnWebsite: false, productStatus: "DEFERRED" },
  { slug: "eagle-eye", title: "عين الصقر", eyebrow: "مؤجل", description: "ليس ضمن المنتج النشط حالياً.", color: "violet", discoverableOnWebsite: false, productStatus: "DEFERRED" },
] as const;

export const gameFormats = [
  { slug: "local-party", title: "Party محلي", description: "فريقان على جهاز واحد.", discoverableOnWebsite: true, productStatus: "LIVE_MOBILE" },
  { slug: "practice", title: "تدريب فردي", description: "جولة محلية هادئة.", discoverableOnWebsite: true, productStatus: "LIVE_MOBILE" },
  { slug: "team-challenge", title: "تحدي الفريق", description: "مسار حسابي يحتاج تحقق إصدار.", discoverableOnWebsite: false, productStatus: "IMPLEMENTED_NOT_RELEASE_READY" },
] as const;

export type GameModeSlug = (typeof gameModes)[number]["slug"];
export type GameFormatSlug = (typeof gameFormats)[number]["slug"];

export function normalizeGameMode(value: string): GameModeSlug {
  return gameModes.some((item) => item.slug === value && item.discoverableOnWebsite) ? value as GameModeSlug : "classic";
}

export function normalizeGameFormat(value: string): GameFormatSlug {
  return gameFormats.some((item) => item.slug === value && item.discoverableOnWebsite) ? value as GameFormatSlug : "local-party";
}
