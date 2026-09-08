import { cn } from "@/lib/utils";

type Tone = "success" | "warning" | "danger" | "info" | "neutral";

const toneClasses: Record<Tone, string> = {
  success: "border-[#74b512]/25 bg-[#74b512]/10 text-[#527f0c]",
  warning: "border-[#aa7200]/25 bg-[#aa7200]/10 text-[#855900]",
  danger: "border-[#c83443]/25 bg-[#c83443]/10 text-[#a72b38]",
  info: "border-[#2f6fba]/25 bg-[#2f6fba]/10 text-[#275f9f]",
  neutral: "border-black/10 bg-black/[0.035] text-[#5f6974]",
};

export function StatusBadge({ children, tone = "neutral" }: { children: React.ReactNode; tone?: Tone }) {
  return (
    <span className={cn("inline-flex items-center rounded-full border px-2.5 py-1 text-[11px] font-bold whitespace-nowrap", toneClasses[tone])}>
      {children}
    </span>
  );
}
