import Link from "next/link";
import { Eye, Grid3X3, Landmark, Medal, Repeat2, Shirt, Trophy } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { createServerSupabaseClient } from "@/lib/supabase/server";

type WebsiteCategory = {
  id: string;
  slug: string;
  name: string;
  description: string;
  icon: LucideIcon;
  featured: boolean;
};

const fallbackCategories: WebsiteCategory[] = [
  { id: "eagle-eye", slug: "eagle-eye", name: "عين الصقر", description: "تفاصيل الأندية والقمصان والشعارات.", icon: Eye, featured: false },
  { id: "transfers", slug: "transfers", name: "سوق الانتقالات", description: "مسيرات اللاعبين والصفقات التي صنعت الفرق.", icon: Repeat2, featured: false },
  { id: "leagues", slug: "leagues", name: "الدوريات والبطولات", description: "من البطولات المحلية إلى ليالي القارة.", icon: Trophy, featured: true },
  { id: "locker-room", slug: "locker-room", name: "غرفة الملابس", description: "الأرقام والمراكز وتفاصيل التشكيلات.", icon: Shirt, featured: false },
  { id: "stadiums", slug: "stadiums", name: "الملاعب", description: "ملاعب شهيرة، مدن وذكريات كروية.", icon: Landmark, featured: false },
  { id: "individual-awards", slug: "individual-awards", name: "الجوائز الفردية", description: "الهدافون والجوائز والإنجازات الكبيرة.", icon: Medal, featured: false },
];

const iconByKey: Record<string, LucideIcon> = {
  eye: Eye,
  swap: Repeat2,
  trophy: Trophy,
  shirt: Shirt,
  stadium: Landmark,
  medal: Medal,
};

async function loadWebsiteCategories(): Promise<{ categories: WebsiteCategory[]; live: boolean }> {
  const supabase = await createServerSupabaseClient();
  if (!supabase) return { categories: fallbackCategories, live: false };

  const result = await supabase
    .from("categories")
    .select("id,slug,name_ar,description_ar,icon_key,is_featured,sort_order")
    .is("parent_id", null)
    .eq("is_active", true)
    .eq("editorial_status", "published")
    .order("is_featured", { ascending: false })
    .order("sort_order")
    .limit(6);

  if (result.error || !result.data?.length) return { categories: fallbackCategories, live: false };
  return {
    categories: result.data.map((row) => ({
      id: String(row.id),
      slug: String(row.slug),
      name: String(row.name_ar),
      description: String(row.description_ar ?? "أسئلة كروية منتقاة لجولة أحدعش."),
      icon: iconByKey[String(row.icon_key ?? "")] ?? Grid3X3,
      featured: Boolean(row.is_featured),
    })),
    live: true,
  };
}

export async function WebsiteCategoryRail() {
  const { categories, live } = await loadWebsiteCategories();
  return (
    <section className="site-category-rail" aria-labelledby="website-categories-title">
      <div className="site-container site-section-space">
        <div className="site-category-heading">
          <div>
            <span className="site-kicker site-kicker-dark"><Grid3X3 size={14} />كتالوج اللعبة</span>
            <h2 id="website-categories-title">ستة ملاعب للمعرفة.</h2>
          </div>
          <p>نفس الأقسام المنشورة التي يقرأها تطبيق الهاتف من Supabase، مرتبة هنا بنفس روح الواجهة وبطاقة واضحة لكل مسار.</p>
        </div>
        <div className="site-category-grid">
          {categories.map((category, index) => {
            const Icon = category.icon;
            return (
              <Link href="/play?mode=classic&format=local-party" key={category.id} className={`site-category-card ${category.featured ? "is-featured" : ""}`}>
                <span className="site-category-index">{String(index + 1).padStart(2, "0")}</span>
                <span className="site-category-icon"><Icon size={22} /></span>
                <span className="site-category-copy"><strong>{category.name}</strong><small>{category.description}</small></span>
                <span className="site-category-cta">ابدأ من هنا</span>
              </Link>
            );
          })}
        </div>
        <p className="site-category-source"><span className={live ? "is-live" : ""} />{live ? "متزامنة مع كتالوج Supabase المنشور" : "ستتزامن مع Supabase بعد نشر الكتالوج"}</p>
      </div>
    </section>
  );
}
