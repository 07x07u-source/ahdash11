import type { LucideIcon } from "lucide-react";

export function MetricCard({
  label,
  value,
  change,
  icon: Icon,
  accent = "green",
}: {
  label: string;
  value: string;
  change: string;
  icon: LucideIcon;
  accent?: "green" | "gold" | "blue" | "red";
}) {
  const accentStyles = {
    green: "bg-[#74b512]/10 text-[#5f9909]",
    gold: "bg-[#aa7200]/10 text-[#936100]",
    blue: "bg-[#2f6fba]/10 text-[#2f6fba]",
    red: "bg-[#c83443]/10 text-[#c83443]",
  }[accent];

  return (
    <article className="surface-card surface-card-hover p-4 sm:p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-bold text-[var(--muted)]">{label}</p>
          <p className="mt-3 text-2xl font-black tracking-tight text-[var(--foreground)]" dir="ltr">{value}</p>
        </div>
        <span className={`grid size-10 place-items-center rounded-xl ${accentStyles}`} aria-hidden="true">
          <Icon size={19} strokeWidth={2.2} />
        </span>
      </div>
      <p className="mt-4 text-[11px] leading-5 text-[var(--muted)]">{change}</p>
    </article>
  );
}
