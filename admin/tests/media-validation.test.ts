import { describe, expect, it } from "vitest";
import { buildMediaStoragePath, MAX_IMAGE_BYTES, validateImageUpload, verifyImageDecodes } from "../src/lib/media/validation";

function png(width: number, height: number): Uint8Array {
  const bytes = new Uint8Array(24);
  bytes.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const view = new DataView(bytes.buffer);
  view.setUint32(16, width);
  view.setUint32(20, height);
  return bytes;
}

describe("media validation", () => {
  it("uses the binary signature and dimensions", () => {
    expect(validateImageUpload({ bytes: png(1200, 800), filename: "hero.png", declaredMimeType: "image/png" })).toMatchObject({
      mimeType: "image/png",
      extension: "png",
      width: 1200,
      height: 800,
    });
  });

  it("rejects spoofed files, mismatched extensions, oversized files, and unsafe dimensions", () => {
    expect(() => validateImageUpload({ bytes: new Uint8Array([1, 2, 3]), filename: "attack.png" })).toThrow("ليس صورة");
    expect(() => validateImageUpload({ bytes: png(800, 800), filename: "hero.jpg", declaredMimeType: "image/png" })).toThrow("امتداد");
    expect(() => validateImageUpload({ bytes: new Uint8Array(MAX_IMAGE_BYTES + 1), filename: "large.png" })).toThrow("8 ميجابايت");
    expect(() => validateImageUpload({ bytes: png(20, 20), filename: "tiny.png" })).toThrow("أبعاد");
  });

  it("creates a versioned, group-scoped storage path", () => {
    expect(buildMediaStoragePath("categories", "webp", "11111111-1111-4111-8111-111111111111", new Date("2026-08-28T00:00:00Z"))).toBe(
      "categories/2026/08/11111111-1111-4111-8111-111111111111.webp",
    );
  });

  it("rejects a forged header that an image decoder cannot open", async () => {
    const bytes = png(800, 800);
    const detected = validateImageUpload({ bytes, filename: "forged.png", declaredMimeType: "image/png" });
    await expect(verifyImageDecodes(bytes, detected)).rejects.toThrow("تعذر فك الصورة");
  });
});
