import { normalizeArabicText } from "./normalize";

function tokenSet(text: string): Set<string> {
  return new Set(normalizeArabicText(text).split(" ").filter((token) => token.length > 1));
}

function jaccardSimilarity(left: string, right: string): number {
  const leftTokens = tokenSet(left);
  const rightTokens = tokenSet(right);
  if (leftTokens.size === 0 || rightTokens.size === 0) return 0;

  const intersection = [...leftTokens].filter((token) => rightTokens.has(token)).length;
  const union = new Set([...leftTokens, ...rightTokens]).size;
  return intersection / union;
}

function levenshteinDistance(left: string, right: string): number {
  if (left === right) return 0;
  if (!left.length) return right.length;
  if (!right.length) return left.length;

  const previous = Array.from({ length: right.length + 1 }, (_, index) => index);
  const current = new Array<number>(right.length + 1);

  for (let leftIndex = 1; leftIndex <= left.length; leftIndex += 1) {
    current[0] = leftIndex;
    for (let rightIndex = 1; rightIndex <= right.length; rightIndex += 1) {
      const substitution = previous[rightIndex - 1] + (left[leftIndex - 1] === right[rightIndex - 1] ? 0 : 1);
      current[rightIndex] = Math.min(previous[rightIndex] + 1, current[rightIndex - 1] + 1, substitution);
    }
    for (let index = 0; index <= right.length; index += 1) previous[index] = current[index];
  }

  return previous[right.length];
}

export function questionSimilarity(left: string, right: string): number {
  const normalizedLeft = normalizeArabicText(left);
  const normalizedRight = normalizeArabicText(right);
  if (!normalizedLeft || !normalizedRight) return 0;
  if (normalizedLeft === normalizedRight) return 1;

  const maxLength = Math.max(normalizedLeft.length, normalizedRight.length);
  const characterScore = 1 - levenshteinDistance(normalizedLeft, normalizedRight) / maxLength;
  const tokenScore = jaccardSimilarity(normalizedLeft, normalizedRight);

  return Number((tokenScore * 0.62 + characterScore * 0.38).toFixed(4));
}
