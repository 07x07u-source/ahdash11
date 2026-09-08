"use client";

import { Eye, EyeOff, LoaderCircle, LockKeyhole, Mail } from "lucide-react";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

export function LoginForm() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");

    const form = new FormData(event.currentTarget);
    const supabase = createBrowserSupabaseClient();

    if (!supabase) {
      setError("لم يتم إعداد Supabase. استخدم وضع التطوير أو أضف متغيرات البيئة.");
      setBusy(false);
      return;
    }

    const { error: authError } = await supabase.auth.signInWithPassword({
      email: String(form.get("email") ?? ""),
      password: String(form.get("password") ?? ""),
    });

    if (authError) {
      setError("تعذر تسجيل الدخول. تحقق من البريد وكلمة المرور ثم حاول مجددًا.");
      setBusy(false);
      return;
    }

    router.replace("/dashboard");
    router.refresh();
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <label className="block">
        <span className="mb-2 block text-xs font-bold text-[#aeb7c4]">البريد الإلكتروني</span>
        <span className="relative block">
          <Mail className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 text-[#697586]" size={17} />
          <input className="field pr-11" type="email" name="email" autoComplete="email" placeholder="admin@ahdash11.com" required />
        </span>
      </label>

      <label className="block">
        <span className="mb-2 block text-xs font-bold text-[#aeb7c4]">كلمة المرور</span>
        <span className="relative block">
          <LockKeyhole className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 text-[#697586]" size={17} />
          <input className="field px-11" type={showPassword ? "text" : "password"} name="password" autoComplete="current-password" placeholder="••••••••••" required />
          <button type="button" onClick={() => setShowPassword((value) => !value)} className="absolute left-2.5 top-1/2 grid size-8 -translate-y-1/2 place-items-center rounded-lg text-[#697586] hover:bg-white/5 hover:text-white" aria-label={showPassword ? "إخفاء كلمة المرور" : "إظهار كلمة المرور"}>
            {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
          </button>
        </span>
      </label>

      {error ? <p role="alert" className="rounded-xl border border-[#ff4d57]/20 bg-[#ff4d57]/8 p-3 text-xs leading-5 text-[#ff9298]">{error}</p> : null}

      <button type="submit" disabled={busy} className="button-primary w-full">
        {busy ? <LoaderCircle size={17} className="animate-spin" /> : <LockKeyhole size={17} />}
        {busy ? "جارٍ التحقق…" : "دخول آمن"}
      </button>
    </form>
  );
}
