"use client";

import { type FormEvent, useState } from "react";
import Link from "next/link";
import { ArrowLeft, Check, KeyRound, LoaderCircle, ShieldCheck, UsersRound } from "lucide-react";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

export function TournamentJoinForm() {
  const [state, setState] = useState<"idle" | "busy" | "done" | "error">("idle");
  const [message, setMessage] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setState("busy");
    setMessage("");
    const form = new FormData(event.currentTarget);
    const supabase = createBrowserSupabaseClient();
    if (!supabase) { setState("error"); setMessage("خدمة البطولات غير متاحة حالياً."); return; }
    const { error } = await supabase.rpc("register_tournament_team", {
      p_invite_code: String(form.get("code") ?? "").trim().toUpperCase(),
      p_team_name: String(form.get("teamName") ?? "").trim(),
      p_roster: [],
    });
    if (error) {
      setState("error");
      setMessage(error.message.includes("not found") ? "الرمز غير صحيح أو التسجيل في البطولة مغلق." : "تعذر إرسال طلب الانضمام. حاول مجدداً.");
      return;
    }
    setState("done");
  }

  if (state === "done") return <div className="join-success"><span><Check size={34} /></span><h2>تم إرسال الطلب.</h2><p>وصل طلب التسجيل إلى البطولة. متابعة دورة المنظّم والقرعة والنتائج كاملة تتم حالياً من التطبيق.</p><div className="mt-6 flex flex-wrap justify-center gap-3"><Link href="/championships" className="site-action-secondary dark">العودة للبطولات</Link></div></div>;

  return <form className="join-form" onSubmit={submit}>
    <div className="join-form-head"><span><KeyRound size={27} /></span><div><h2>رمز واحد وندخل.</h2><p>خذ الرمز من منظم البطولة واكتب اسم فريقك.</p></div></div>
    <label className="site-field"><span>رمز الانضمام</span><input name="code" required minLength={4} maxLength={16} placeholder="A11-482" dir="ltr" /></label>
    <label className="site-field"><span>اسم الفريق أو اللاعب</span><div><UsersRound size={18} /><input name="teamName" required minLength={2} maxLength={40} placeholder="مثال: صقور الحارة" /></div></label>
    <div className="join-privacy"><ShieldCheck size={18} /><span>لا نشارك بريدك مع منظم البطولة أو المشاركين.</span></div>
    {state === "error" ? <p className="auth-alert is-error" role="alert">{message}</p> : null}
    <button type="submit" className="site-action w-full" disabled={state === "busy"}>{state === "busy" ? <LoaderCircle size={18} className="animate-spin" /> : <KeyRound size={18} />}{state === "busy" ? "جاري التحقق…" : "إرسال طلب الانضمام"}<ArrowLeft size={17} /></button>
  </form>;
}
