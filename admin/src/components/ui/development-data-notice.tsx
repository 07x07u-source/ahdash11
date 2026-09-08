import { DatabaseZap } from "lucide-react";

export function DevelopmentDataNotice({ label = "تعرض هذه الصفحة بيانات تطوير محلية لأن Supabase غير متصل." }: { label?: string }) {
  return (
    <div className="flex items-start gap-2 rounded-xl border border-[#ffc857]/14 bg-[#ffc857]/6 px-3 py-2.5 text-[10px] leading-5 text-[#d7bd7d]">
      <DatabaseZap size={15} className="mt-0.5 shrink-0 text-[#ffc857]" />
      {label}
    </div>
  );
}
