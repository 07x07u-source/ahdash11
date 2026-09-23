"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { ArrowUpLeft, Gamepad2, Home, LogIn, Menu, ShieldCheck, UserRound, X } from "lucide-react";
import { cn } from "@/lib/utils";

const navigation = [
  { href: "/", label: "الرئيسية" },
  { href: "/games", label: "طريقة اللعب" },
  { href: "/championships", label: "البطولات" },
  { href: "/support", label: "المساعدة" },
];

const mobileNavigation = [
  { href: "/", label: "الرئيسية", icon: Home },
  { href: "/games", label: "العب", icon: Gamepad2 },
  { href: "/account", label: "حسابي", icon: UserRound },
];

function isCurrent(pathname: string, href: string) {
  return href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(`${href}/`);
}

type ShellPlayer = { displayName: string; username: string } | null;

export function SiteShell({ children, player }: { children: React.ReactNode; player: ShellPlayer }) {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    if (!menuOpen) return;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMenuOpen(false);
    };
    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", closeOnEscape);
    return () => {
      document.body.style.overflow = "";
      window.removeEventListener("keydown", closeOnEscape);
    };
  }, [menuOpen]);

  return (
    <div className="site-frame">
      <a href="#site-main" className="site-skip-link">تجاوز إلى المحتوى</a>
      <header className="site-header">
        <div className="site-container site-header-inner">
          <Link href="/" className="site-logo site-brand-lockup" aria-label="أحدعش 11 — الرئيسية">
            <Image src="/branding/logo-horizontal.png" alt="أحدعش 11" width={164} height={54} priority />
            <span aria-hidden="true">لعبة كروية عربية</span>
          </Link>

          <nav className="site-nav-surface hidden items-center gap-1 lg:flex" aria-label="التنقل الرئيسي">
            {navigation.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={cn("site-nav-link", isCurrent(pathname, item.href) && "is-active")}
              >
                {item.label}
              </Link>
            ))}
          </nav>

          <div className="flex items-center gap-2">
            <Link href={player ? "/account" : "/account/login"} className="site-account-link" aria-label={player ? `حساب ${player.displayName}` : "تسجيل الدخول"}>
              <span>{player ? player.displayName.charAt(0) : <LogIn size={17} />}</span>
              <strong>{player ? player.displayName : "دخول"}</strong>
            </Link>
            <Link href={player ? "/games" : "/account/register"} className="site-header-cta hidden sm:inline-flex">
              {player ? "استكشف اللعب" : "ابدأ بحساب"}
              <ArrowUpLeft size={17} />
            </Link>
            <button
              type="button"
              className="site-menu-button lg:hidden"
              onClick={() => setMenuOpen(true)}
              aria-label="فتح القائمة"
              aria-expanded={menuOpen}
            >
              <Menu size={21} />
            </button>
          </div>
        </div>
      </header>

      {menuOpen ? (
        <div className="site-menu-layer lg:hidden">
          <button type="button" className="absolute inset-0 bg-black/70" aria-label="إغلاق القائمة" onClick={() => setMenuOpen(false)} />
          <aside className="site-menu-panel">
            <div className="flex items-center justify-between">
              <span className="text-sm font-black text-white">القائمة</span>
              <button type="button" className="site-menu-button" onClick={() => setMenuOpen(false)} aria-label="إغلاق القائمة">
                <X size={20} />
              </button>
            </div>
            <nav className="mt-8 grid gap-2" aria-label="قائمة الهاتف">
              {navigation.map((item) => (
                <Link key={item.href} href={item.href} onClick={() => setMenuOpen(false)} className={cn("site-mobile-link", isCurrent(pathname, item.href) && "is-active")}>
                  {item.label}
                  <ArrowUpLeft size={18} />
                </Link>
              ))}
            </nav>
            <Link href={player ? "/account" : "/account/login"} onClick={() => setMenuOpen(false)} className="site-mobile-account">
              <span>{player ? player.displayName.charAt(0) : <LogIn size={18} />}</span>
              <div><strong>{player ? player.displayName : "تسجيل الدخول"}</strong><small>{player ? `@${player.username}` : "العب واحفظ تقدمك"}</small></div>
              <ArrowUpLeft size={18} />
            </Link>
            <Link href={player ? "/games" : "/account/register"} onClick={() => setMenuOpen(false)} className="site-action mt-5 w-full">{player ? "استكشف اللعب" : "أنشئ حساب اللاعب"}</Link>
          </aside>
        </div>
      ) : null}

      <main id="site-main">{children}</main>

      <footer className="site-footer">
        <div className="site-container grid gap-8 py-10 md:grid-cols-[1.25fr_1fr_1fr]">
          <div>
            <div className="site-logo w-fit">
              <Image src="/branding/logo-horizontal.png" alt="أحدعش 11" width={150} height={50} />
            </div>
            <p className="mt-4 max-w-sm text-sm leading-7 text-[#a8a59d]">لعبة Party عربية لأسئلة كرة القدم: فريقان، جهاز واحد، وجولة تُحسم بالمعرفة.</p>
          </div>
          <div>
            <h2 className="text-sm font-black text-white">استكشف</h2>
            <div className="mt-4 grid gap-3 text-sm text-[#aaa79f]">
              <Link href="/games">كيف تلعب</Link>
              <Link href="/account/register">إنشاء حساب</Link>
              <Link href="/championships">البطولات</Link>
              <Link href="/support">الدعم والمساعدة</Link>
            </div>
          </div>
          <div>
            <h2 className="text-sm font-black text-white">القانونية</h2>
            <div className="mt-4 grid gap-3 text-sm text-[#aaa79f]">
              <Link href="/legal/privacy">سياسة الخصوصية</Link>
              <Link href="/legal/terms">شروط الاستخدام</Link>
              <Link href="/legal/community">قواعد المجتمع</Link>
              <Link href="/legal">كل السياسات</Link>
            </div>
          </div>
        </div>
        <div className="border-t border-white/8">
          <div className="site-container flex flex-col gap-3 py-5 text-xs text-[#77746d] sm:flex-row sm:items-center sm:justify-between">
            <span>© 2026 أحدعش 11. جميع الحقوق محفوظة.</span>
            <span className="inline-flex items-center gap-2"><ShieldCheck size={15} className="text-[var(--site-action)]" />لعب نزيه · خصوصية أولاً</span>
          </div>
        </div>
      </footer>

      <nav className="site-mobile-dock lg:hidden" aria-label="التنقل السريع">
        {mobileNavigation.map((item) => {
          const Icon = item.icon;
          const active = isCurrent(pathname, item.href);
          return (
            <Link key={item.href} href={item.href} className={cn("site-dock-item", active && "is-active")} aria-current={active ? "page" : undefined}>
              <Icon size={active ? 23 : 21} strokeWidth={active ? 2.7 : 2.2} />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
