"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import {
  Activity,
  BellRing,
  Boxes,
  Bug,
  CircleHelp,
  ClipboardList,
  FileClock,
  FileUp,
  Gauge,
  Images,
  DatabaseZap,
  ShieldAlert,
  Menu,
  MessageSquareWarning,
  Palette,
  PanelsTopLeft,
  Settings2,
  ShoppingBag,
  Trophy,
  TicketCheck,
  Swords,
  Gamepad2,
  UsersRound,
  X,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import type { AdminContext } from "@/lib/auth/context";
import { roleLabel } from "@/lib/auth/roles";
import { cn } from "@/lib/utils";
import { LogoutButton } from "./logout-button";
import { CommandPalette } from "./command-palette";

interface NavigationItem { href: string; label: string; icon: LucideIcon }
interface NavigationGroup { label: string; items: NavigationItem[] }

const navigation: NavigationGroup[] = [
  { label: "نظرة عامة", items: [{ href: "/dashboard", label: "لوحة المؤشرات", icon: Gauge }] },
  { label: "المحتوى", items: [
    { href: "/categories", label: "التصنيفات", icon: Boxes },
    { href: "/questions", label: "الأسئلة", icon: CircleHelp },
    { href: "/import", label: "الاستيراد", icon: FileUp },
    { href: "/content", label: "محتوى التطبيق", icon: PanelsTopLeft },
    { href: "/media", label: "مكتبة الوسائط", icon: Images },
    { href: "/branding", label: "هوية التطبيق", icon: Palette },
    { href: "/football-data", label: "Football Data", icon: DatabaseZap },
  ] },
  { label: "اللعبة والمستخدمون", items: [
    { href: "/party-game", label: "لعبة الجلسة", icon: Gamepad2 },
    { href: "/tournaments", label: "البطولات", icon: Trophy },
    { href: "/matches", label: "المباريات", icon: Swords },
    { href: "/users", label: "المستخدمون", icon: UsersRound },
    { href: "/reports", label: "بلاغات الأسئلة", icon: MessageSquareWarning },
    { href: "/user-reports", label: "بلاغات المستخدمين", icon: ClipboardList },
    { href: "/social", label: "Social", icon: ShieldAlert },
  ] },
  { label: "الاقتصاد والتفاعل", items: [
    { href: "/store", label: "المتجر والاقتصاد", icon: ShoppingBag },
    { href: "/premium-vouchers", label: "قسائم Premium", icon: TicketCheck },
    { href: "/notifications", label: "الإشعارات", icon: BellRing },
  ] },
  { label: "المراقبة", items: [
    { href: "/errors", label: "مشاكل التطبيق", icon: Bug },
    { href: "/system-health", label: "صحة الأنظمة", icon: Activity },
    { href: "/audit", label: "سجل التدقيق", icon: FileClock },
  ] },
  { label: "الإعدادات", items: [{ href: "/settings", label: "إعدادات اللعب", icon: Settings2 }] },
];

function SidebarContent({ admin, close }: { admin: AdminContext; close?: () => void }) {
  const pathname = usePathname();
  return <>
    <div className="flex h-20 items-center justify-between border-b border-white/7 px-5">
      <Link href="/dashboard" onClick={close} className="flex items-center gap-3" aria-label="العودة إلى لوحة أحدعش">
        <span className="grid h-10 w-28 place-items-center overflow-hidden rounded-md bg-[#fbf7ef] px-2"><Image src="/branding/logo-horizontal.png" alt="شعار أحدعش" width={104} height={34} className="h-8 w-auto object-contain" priority /></span>
        <span className="text-[10px] font-semibold text-[#b8ad9e]">مركز العمليات</span>
      </Link>
      {close ? <button type="button" onClick={close} className="grid size-9 place-items-center rounded-lg text-[#8e98a7] hover:bg-white/5" aria-label="إغلاق القائمة"><X size={19} /></button> : null}
    </div>
    <div className="scrollbar-thin flex-1 overflow-y-auto px-3 py-4">
      {navigation.map((group) => <section key={group.label} className="mb-5">
        <p className="mb-2 px-3 text-[10px] font-extrabold tracking-wider text-[#5f6c7a]">{group.label}</p>
        <nav className="space-y-1" aria-label={group.label}>
          {group.items.map((item) => {
            const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
            const Icon = item.icon;
            return <Link key={item.href} href={item.href} onClick={close} className={cn("group flex min-h-11 items-center gap-3 rounded-md px-3 text-[13px] font-bold transition", active ? "bg-[#5f8f0f]/16 text-[#e8dcc8] shadow-[inset_-2px_0_0_#78a91b]" : "text-[#a79d90] hover:bg-white/[0.045] hover:text-white")}><Icon size={18} className={active ? "text-[#78a91b]" : "text-[#756d63] group-hover:text-[#d7c6ac]"} /><span className="flex-1">{item.label}</span></Link>;
          })}
        </nav>
      </section>)}
    </div>
    <div className="border-t border-white/7 p-3">
      {admin.isDevelopmentFallback ? <div className="mb-3 rounded-xl border border-[#ffc857]/15 bg-[#ffc857]/6 p-3 text-[10px] leading-5 text-[#d7bd7d]">وضع التطوير فعّال. لا تُعرض بيانات تشغيلية وهمية.</div> : null}
      <div className="flex items-center gap-3 rounded-xl bg-white/[0.035] p-2.5"><span className="grid size-9 shrink-0 place-items-center rounded-lg bg-[#b6ff3b] text-xs font-black text-[#0b0f14]">{admin.displayName.trim().charAt(0)}</span><span className="min-w-0 flex-1"><strong className="block truncate text-xs text-white">{admin.displayName}</strong><span className="block truncate text-[10px] text-[#82909f]">{roleLabel[admin.role]}</span></span></div>
      <div className="mt-1"><LogoutButton /></div>
    </div>
  </>;
}

export function AppShell({ admin, children }: { admin: AdminContext; children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const formattedDate = useMemo(() => new Intl.DateTimeFormat("ar-SA", { weekday: "long", day: "numeric", month: "long" }).format(new Date()), []);
  useEffect(() => {
    if (!mobileOpen) return;
    const previousOverflow = document.body.style.overflow;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMobileOpen(false);
    };
    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", closeOnEscape);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", closeOnEscape);
    };
  }, [mobileOpen]);
  return <div className="min-h-screen">
    <aside className="fixed inset-y-0 right-0 z-30 hidden w-72 flex-col border-l border-white/7 bg-[#171613] lg:flex"><SidebarContent admin={admin} /></aside>
    {mobileOpen ? <div className="fixed inset-0 z-50 lg:hidden"><button type="button" aria-label="إغلاق القائمة" className="absolute inset-0 bg-black/45" onClick={() => setMobileOpen(false)} /><aside className="absolute inset-y-0 right-0 flex w-[min(88vw,20rem)] flex-col border-l border-white/8 bg-[#171613]"><SidebarContent admin={admin} close={() => setMobileOpen(false)} /></aside></div> : null}
    <div className="lg:mr-72">
      <header className="surface-glass sticky top-0 z-20 flex h-16 items-center justify-between border-x-0 border-t-0 px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-3"><button type="button" onClick={() => setMobileOpen(true)} className="grid size-10 place-items-center rounded-xl border border-black/10 bg-white text-[#27313b] lg:hidden" aria-label="فتح القائمة"><Menu size={20} /></button><div><p className="text-[10px] font-bold text-[var(--muted)]">{formattedDate}</p><p className="text-xs font-extrabold text-[var(--foreground)]">مرحبًا، {admin.displayName.split(" ")[0]}</p></div></div>
        <div className="flex items-center gap-2"><CommandPalette /><Link href="/system-health" className="hidden items-center gap-2 rounded-full border border-[#74b512]/20 bg-[#74b512]/7 px-3 py-1.5 text-[10px] font-bold text-[#527f0c] md:flex"><span className="size-1.5 rounded-full bg-[#74b512]" />مراقبة الأنظمة</Link><Link href="/notifications" className="grid size-10 place-items-center rounded-xl border border-black/10 bg-white text-[#4d5965] hover:text-black" aria-label="الإشعارات"><BellRing size={18} /></Link></div>
      </header>
      <main className="brand-grid min-h-[calc(100vh-4rem)] p-4 sm:p-6 lg:p-8"><div className="mx-auto max-w-[1520px]">{children}</div></main>
    </div>
  </div>;
}
