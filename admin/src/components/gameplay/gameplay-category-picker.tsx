"use client";

import { useMemo, useState } from "react";
import { Check, LockKeyhole, Search, ShieldAlert } from "lucide-react";
import { categoryIsAccessible } from "@/lib/gameplay/catalog";
import type { GameplayCategory } from "@/lib/gameplay/contracts";

export function GameplayCategoryPicker({ categories, selected, maximum, premiumAccess, onToggle, exact = false }: {
  categories: GameplayCategory[];
  selected: string[];
  maximum: number;
  premiumAccess: boolean;
  onToggle: (categoryId: string) => void;
  exact?: boolean;
}) {
  const [query, setQuery] = useState("");
  const visible = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase("ar");
    return categories.filter((category) => !needle || `${category.name} ${category.description}`.toLocaleLowerCase("ar").includes(needle));
  }, [categories, query]);
  return (
    <div className="gameplay-category-picker">
      <div className="gameplay-category-toolbar">
        <label><Search size={18} /><span className="sr-only">ابحث في الفئات</span><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث عن دوري، نادٍ أو حقبة…" /></label>
        <div aria-live="polite"><strong>{selected.length}</strong><span>من {maximum}{exact ? " مطلوبة" : " كحد أقصى"}</span></div>
      </div>
      {visible.length ? (
        <div className="gameplay-category-grid">
          {visible.map((category) => {
            const active = selected.includes(category.id);
            const locked = !categoryIsAccessible(category, premiumAccess);
            const disabled = !category.ready || locked || (!active && selected.length >= maximum);
            return (
              <button
                key={category.id}
                type="button"
                disabled={disabled}
                onClick={() => onToggle(category.id)}
                className={`${active ? "is-selected" : ""} ${locked ? "is-locked" : ""}`}
                aria-pressed={active}
                aria-label={`${category.name}، ${active ? "محددة" : locked ? "مقفلة وتتطلب Premium" : category.ready ? "متاحة" : "غير جاهزة"}`}
              >
                {category.imageUrl ? <span className="gameplay-category-cover" style={{ backgroundImage: `linear-gradient(180deg,rgba(12,34,26,.04),rgba(12,34,26,.86)),url(${JSON.stringify(category.imageUrl)})`, backgroundPosition: `${category.focalX * 100}% ${category.focalY * 100}%` }} /> : <span className="gameplay-category-cover is-empty" />}
                {active || locked || !category.ready ? <span className="gameplay-category-state">{active ? <Check size={17} /> : locked ? <LockKeyhole size={16} /> : <ShieldAlert size={16} />}</span> : null}
                <span className="gameplay-category-copy"><strong>{category.name}</strong><small>{locked ? "فئة Premium" : category.ready ? `${category.questionCount} سؤالاً صالحاً` : "لا تكفي لبناء جولة"}</small></span>
              </button>
            );
          })}
        </div>
      ) : <p className="gameplay-empty-search">{categories.length ? "لا توجد فئة تطابق بحثك." : "لا توجد فئات منشورة متاحة لهذه الجولة حالياً."}</p>}
    </div>
  );
}
