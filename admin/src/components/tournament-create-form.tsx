"use client";

import { type FormEvent, useState } from "react";
import Link from "next/link";
import { ArrowLeft, CalendarDays, Check, Copy, LoaderCircle, ShieldCheck, Sparkles, Trophy, UsersRound } from "lucide-react";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

export function TournamentCreateForm() {
  const [teamSize, setTeamSize] = useState("1");
  const [created, setCreated] = useState(false);
  const [copied, setCopied] = useState(false);
  const [createdCode, setCreatedCode] = useState("A11-482");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    const form = new FormData(event.currentTarget);
    const supabase = createBrowserSupabaseClient();
    if (!supabase) {
      setError("خدمة البطولات غير متصلة حالياً.");
      setBusy(false);
      return;
    }

    const clientId = crypto.randomUUID();
    const { data: tournamentId, error: createError } = await supabase.rpc("create_tournament", {
      p_client_id: clientId,
      p_name: String(form.get("name") ?? "بطولة أحدعش"),
      p_rules: {
        visibility: "public",
        seeding: "draw",
        capacity: Number(form.get("players") ?? 8),
        players_per_team: Number(teamSize),
        timer_seconds: 30,
        helpers_enabled: true,
        tiebreaker_enabled: true,
        category_ids: [],
        format: "knockout",
        start_date: String(form.get("date") ?? ""),
        start_time: String(form.get("time") ?? ""),
        categories: String(form.get("categories") ?? "mixed"),
      },
    });

    if (createError || !tournamentId) {
      setError(createError?.message.includes("JWT") ? "انتهت الجلسة. سجّل الدخول من جديد." : "تعذر إنشاء البطولة الآن. تحقق من البيانات وحاول مجدداً.");
      setBusy(false);
      return;
    }

    const { data: createdTournament } = await supabase.from("tournaments").select("invite_code").eq("id", tournamentId).maybeSingle();
    setCreatedCode(String(createdTournament?.invite_code ?? clientId.slice(0, 8)).toUpperCase());
    setCreated(true);
    setBusy(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  async function copyCode() {
    await navigator.clipboard?.writeText(createdCode);
    setCopied(true);
  }

  if (created) {
    return (
      <section className="create-success" aria-live="polite">
        <span className="create-success-icon"><Trophy size={34} /></span>
        <span className="site-kicker site-kicker-dark">تم تجهيز البطولة</span>
        <h1>ملعبك جاهز.</h1>
        <p>حُفظت البطولة في حسابك. شارك رمز الدعوة، وأكمل إدارة دورة المنافسة من التطبيق.</p>
        <button type="button" className="invite-code" onClick={copyCode} aria-label="نسخ رمز البطولة">
          <span><small>رمز الانضمام</small><strong dir="ltr">{createdCode}</strong></span>
          {copied ? <Check size={20} /> : <Copy size={20} />}
        </button>
        <div className="mt-7 flex flex-wrap justify-center gap-3">
          <Link href="/championships" className="site-action">العودة للبطولات <ArrowLeft size={17} /></Link>
          <button type="button" className="site-action-secondary dark" onClick={() => setCreated(false)}>تعديل الإعدادات</button>
        </div>
      </section>
    );
  }

  return (
    <form className="create-grid" onSubmit={submit}>
      <section className="create-main">
        <div className="create-section-head"><span>01</span><div><h2>أساسيات البطولة</h2><p>الاسم والوقت المناسبان للمجموعة.</p></div></div>
        <div className="mt-7 grid gap-5 sm:grid-cols-2">
          <label className="site-field sm:col-span-2"><span>اسم البطولة</span><input name="name" required minLength={3} placeholder="مثال: كأس ليلة الجمعة" /></label>
          <label className="site-field"><span>تاريخ البداية</span><div><CalendarDays size={18} /><input name="date" required type="date" /></div></label>
          <label className="site-field"><span>وقت البداية</span><input name="time" required type="time" defaultValue="21:00" /></label>
        </div>

        <div className="create-divider" />
        <div className="create-section-head"><span>02</span><div><h2>نظام المنافسة</h2><p>يدعم الموقع حالياً نظام خروج المغلوب فقط.</p></div></div>
        <div className="format-single" role="status"><Trophy size={20} /><div><strong>خروج مغلوب</strong><span>النظام الوحيد المدعوم في البنية الحالية</span></div><Check size={18} /></div>

        <div className="mt-6 grid gap-5 sm:grid-cols-2">
          <label className="site-field"><span>عدد المشاركين</span><select name="players" defaultValue="8"><option value="4">4 لاعبين</option><option value="8">8 لاعبين</option><option value="16">16 لاعباً</option><option value="32">32 لاعباً</option></select></label>
          <label className="site-field"><span>حجم الفريق</span><select name="teamSize" value={teamSize} onChange={(event) => setTeamSize(event.target.value)}><option value="1">لاعب واحد لكل فريق</option><option value="2">لاعبان لكل فريق</option><option value="4">أربعة لاعبين لكل فريق</option></select></label>
          <label className="site-field sm:col-span-2"><span>فئات الأسئلة</span><select name="categories" defaultValue="mixed"><option value="mixed">تشكيلة متنوعة</option><option value="history">تاريخ وأساطير</option><option value="leagues">الدوريات العالمية</option><option value="saudi">الكرة السعودية</option></select></label>
        </div>
      </section>

      <aside className="create-summary">
        <span className="inline-flex size-11 items-center justify-center rounded-2xl bg-[var(--site-lime)] text-[#10120e]"><Sparkles size={21} /></span>
        <h2>ملخص البطولة</h2>
        <ul>
          <li><Trophy size={17} /><span>النظام</span><strong>خروج مغلوب</strong></li>
          <li><UsersRound size={17} /><span>الفرق</span><strong>{teamSize === "1" ? "فردية" : `${teamSize} لاعبين`}</strong></li>
          <li><ShieldCheck size={17} /><span>الدخول</span><strong>برمز خاص</strong></li>
        </ul>
        <label className="create-check"><input type="checkbox" required /><span>أوافق على <Link href="/legal/tournament-rules">قواعد البطولات</Link> وسياسة اللعب النزيه.</span></label>
        {error ? <p className="auth-alert is-error" role="alert">{error}</p> : null}
        <button type="submit" className="site-action w-full" disabled={busy}>{busy ? <LoaderCircle size={18} className="animate-spin" /> : <Trophy size={18} />}{busy ? "جاري الإنشاء…" : "إنشاء البطولة"} <ArrowLeft size={18} /></button>
        <p className="mt-3 text-center text-xs leading-5 text-[#77746d]">تُربط البطولة بحسابك ولا يمكن إنشاؤها كزائر.</p>
      </aside>
    </form>
  );
}
