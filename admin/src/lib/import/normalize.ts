const arabicDiacritics = /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]/g;
const punctuation = /[^\p{L}\p{N}\s]/gu;

export function normalizeArabicText(value: unknown): string {
  return String(value ?? "")
    .trim()
    .toLocaleLowerCase("ar")
    .replace(arabicDiacritics, "")
    .replace(/ـ/g, "")
    .replace(/[إأآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/ة/g, "ه")
    .replace(punctuation, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizeHeader(value: unknown): string {
  return normalizeArabicText(value).replace(/\s+/g, " ");
}

export function stableContentHash(value: string): string {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0");
}
