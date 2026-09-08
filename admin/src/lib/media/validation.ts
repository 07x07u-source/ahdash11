export const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
export const MIN_IMAGE_DIMENSION = 64;
export const MAX_IMAGE_DIMENSION = 6000;

export const mediaGroups = [
  "app-content",
  "categories",
  "store",
  "achievements",
  "promotions",
  "onboarding",
  "branding",
  "app-icons",
] as const;

export type MediaGroup = (typeof mediaGroups)[number];
export type AllowedImageMime = "image/jpeg" | "image/png" | "image/webp";

export interface ValidatedImage {
  mimeType: AllowedImageMime;
  extension: "jpg" | "png" | "webp";
  width: number;
  height: number;
  sizeBytes: number;
}

export class MediaValidationError extends Error {}

function startsWith(bytes: Uint8Array, signature: number[]): boolean {
  return signature.every((value, index) => bytes[index] === value);
}

function uint16BE(bytes: Uint8Array, offset: number): number {
  return bytes[offset] * 256 + bytes[offset + 1];
}

function uint16LE(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 256;
}

function uint24LE(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 256 + bytes[offset + 2] * 65_536;
}

function uint32BE(bytes: Uint8Array, offset: number): number {
  return bytes[offset] * 16_777_216 + bytes[offset + 1] * 65_536 + bytes[offset + 2] * 256 + bytes[offset + 3];
}

function ascii(bytes: Uint8Array, offset: number, length: number): string {
  return String.fromCharCode(...bytes.slice(offset, offset + length));
}

function jpegDimensions(bytes: Uint8Array): { width: number; height: number } | null {
  const startOfFrame = new Set([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]);
  let offset = 2;
  while (offset + 8 < bytes.length) {
    if (bytes[offset] !== 0xff) {
      offset += 1;
      continue;
    }
    while (bytes[offset] === 0xff) offset += 1;
    const marker = bytes[offset];
    offset += 1;
    if (marker === 0xd9 || marker === 0xda) break;
    if (offset + 1 >= bytes.length) break;
    const segmentLength = uint16BE(bytes, offset);
    if (segmentLength < 2 || offset + segmentLength > bytes.length) break;
    if (startOfFrame.has(marker) && segmentLength >= 7) {
      return { height: uint16BE(bytes, offset + 3), width: uint16BE(bytes, offset + 5) };
    }
    offset += segmentLength;
  }
  return null;
}

function webpDimensions(bytes: Uint8Array): { width: number; height: number } | null {
  const chunk = ascii(bytes, 12, 4);
  if (chunk === "VP8X" && bytes.length >= 30) {
    return { width: uint24LE(bytes, 24) + 1, height: uint24LE(bytes, 27) + 1 };
  }
  if (chunk === "VP8L" && bytes.length >= 25 && bytes[20] === 0x2f) {
    const b1 = bytes[21];
    const b2 = bytes[22];
    const b3 = bytes[23];
    const b4 = bytes[24];
    return {
      width: 1 + (((b2 & 0x3f) << 8) | b1),
      height: 1 + (((b4 & 0x0f) << 10) | (b3 << 2) | ((b2 & 0xc0) >> 6)),
    };
  }
  if (chunk === "VP8 " && bytes.length >= 30 && bytes[23] === 0x9d && bytes[24] === 0x01 && bytes[25] === 0x2a) {
    return { width: uint16LE(bytes, 26) & 0x3fff, height: uint16LE(bytes, 28) & 0x3fff };
  }
  return null;
}

function detectImage(bytes: Uint8Array): Omit<ValidatedImage, "sizeBytes"> | null {
  if (bytes.length >= 24 && startsWith(bytes, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return { mimeType: "image/png", extension: "png", width: uint32BE(bytes, 16), height: uint32BE(bytes, 20) };
  }
  if (bytes.length >= 12 && startsWith(bytes, [0xff, 0xd8, 0xff])) {
    const dimensions = jpegDimensions(bytes);
    return dimensions ? { mimeType: "image/jpeg", extension: "jpg", ...dimensions } : null;
  }
  if (bytes.length >= 30 && ascii(bytes, 0, 4) === "RIFF" && ascii(bytes, 8, 4) === "WEBP") {
    const dimensions = webpDimensions(bytes);
    return dimensions ? { mimeType: "image/webp", extension: "webp", ...dimensions } : null;
  }
  return null;
}

export function validateImageUpload(input: {
  bytes: Uint8Array;
  filename: string;
  declaredMimeType?: string;
}): ValidatedImage {
  if (!input.bytes.length) throw new MediaValidationError("ملف الصورة فارغ.");
  if (input.bytes.length > MAX_IMAGE_BYTES) throw new MediaValidationError("حجم الصورة يتجاوز 8 ميجابايت.");

  const detected = detectImage(input.bytes);
  if (!detected) throw new MediaValidationError("الملف ليس صورة JPEG أو PNG أو WebP صالحة.");

  const declaredMime = input.declaredMimeType?.toLowerCase();
  if (declaredMime && declaredMime !== "application/octet-stream" && declaredMime !== detected.mimeType) {
    throw new MediaValidationError("نوع الملف المعلن لا يطابق محتوى الصورة.");
  }

  const filenameExtension = input.filename.toLowerCase().match(/\.([a-z0-9]+)$/)?.[1];
  const allowedExtensions = detected.mimeType === "image/jpeg" ? ["jpg", "jpeg"] : [detected.extension];
  if (!filenameExtension || !allowedExtensions.includes(filenameExtension)) {
    throw new MediaValidationError("امتداد الملف لا يطابق صيغة الصورة.");
  }

  if (
    detected.width < MIN_IMAGE_DIMENSION ||
    detected.height < MIN_IMAGE_DIMENSION ||
    detected.width > MAX_IMAGE_DIMENSION ||
    detected.height > MAX_IMAGE_DIMENSION
  ) {
    throw new MediaValidationError("أبعاد الصورة يجب أن تكون بين 64 و6000 بكسل.");
  }

  return { ...detected, sizeBytes: input.bytes.length };
}

export async function verifyImageDecodes(bytes: Uint8Array, expected: ValidatedImage): Promise<void> {
  try {
    const metadata = await sharp(bytes, {
      failOn: "error",
      limitInputPixels: MAX_IMAGE_DIMENSION * MAX_IMAGE_DIMENSION,
    }).metadata();
    const formatMime = metadata.format === "jpeg" ? "image/jpeg" : metadata.format === "png" ? "image/png" : metadata.format === "webp" ? "image/webp" : null;
    if (formatMime !== expected.mimeType || metadata.width !== expected.width || metadata.height !== expected.height) {
      throw new MediaValidationError("بيانات الصورة الداخلية غير متطابقة.");
    }
  } catch (error) {
    if (error instanceof MediaValidationError) throw error;
    throw new MediaValidationError("تعذر فك الصورة؛ قد يكون الملف تالفًا أو غير آمن.");
  }
}

export function buildMediaStoragePath(group: MediaGroup, extension: ValidatedImage["extension"], id: string, now = new Date()): string {
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, "0");
  if (!/^[0-9a-f-]{36}$/i.test(id)) throw new Error("Invalid media id");
  return `${group}/${year}/${month}/${id}.${extension}`;
}
import sharp from "sharp";
