import Papa from "papaparse";
import { readSheet } from "read-excel-file/node";
import { hasRecognizedQuestionHeaders } from "./validation";
import type { RawQuestionRow } from "./types";

export const MAX_IMPORT_FILE_BYTES = 10 * 1024 * 1024;
export const MAX_IMPORT_ROWS = 5_000;

function nonEmptyRows(rows: RawQuestionRow[]): RawQuestionRow[] {
  return rows.filter((row) => Object.values(row).some((value) => String(value ?? "").trim().length > 0));
}

function assertHeaders(rows: RawQuestionRow[]) {
  if (!rows.length) throw new Error("الملف لا يحتوي على صفوف بيانات.");
  const headers = Object.keys(rows[0]);
  if (!hasRecognizedQuestionHeaders(headers)) {
    throw new Error("عناوين الأعمدة غير معروفة. استخدم: السؤال، الخيار الأول… الرابع، الإجابة الصحيحة، الصورة - اختياري.");
  }
}

function parseCsv(contents: ArrayBuffer): RawQuestionRow[] {
  const text = new TextDecoder("utf-8", { fatal: false }).decode(contents).replace(/^\uFEFF/, "");
  const parsed = Papa.parse<RawQuestionRow>(text, {
    header: true,
    skipEmptyLines: "greedy",
    transformHeader: (header) => header.trim(),
  });

  if (parsed.errors.some((error) => error.code !== "TooFewFields")) {
    throw new Error(`تعذر قراءة CSV: ${parsed.errors[0]?.message ?? "تنسيق غير صالح"}`);
  }

  return nonEmptyRows(parsed.data);
}

async function parseWorkbook(contents: ArrayBuffer): Promise<RawQuestionRow[]> {
  const sheet = await readSheet(Buffer.from(contents));
  const [headerRow, ...dataRows] = sheet;
  if (!headerRow?.length) throw new Error("ملف Excel لا يحتوي على أوراق أو عناوين.");
  const headers = headerRow.map((cell) => String(cell ?? "").trim());
  return nonEmptyRows(dataRows.map((cells) => Object.fromEntries(headers.map((header, index) => [header, cells[index] ?? ""]))));
}

export function detectSourceType(filename: string): "csv" | "xlsx" {
  const extension = filename.toLowerCase().split(".").pop();
  if (extension === "csv") return "csv";
  if (extension === "xlsx") return "xlsx";
  throw new Error("نوع الملف غير مدعوم. ارفع CSV أو XLSX فقط.");
}

export async function parseQuestionFile(contents: ArrayBuffer, filename: string): Promise<RawQuestionRow[]> {
  if (contents.byteLength === 0) throw new Error("الملف فارغ.");
  if (contents.byteLength > MAX_IMPORT_FILE_BYTES) throw new Error("حجم الملف يتجاوز الحد المسموح (10 ميجابايت).");

  const sourceType = detectSourceType(filename);
  const rows = sourceType === "csv" ? parseCsv(contents) : await parseWorkbook(contents);
  assertHeaders(rows);

  if (rows.length > MAX_IMPORT_ROWS) {
    throw new Error(`الملف يحتوي على أكثر من ${MAX_IMPORT_ROWS.toLocaleString("ar-SA")} صف. قسّمه إلى دفعات أصغر.`);
  }

  return rows;
}
