"use client";

import type { FormEvent } from "react";
import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Apple,
  ArrowLeft,
  Check,
  Eye,
  EyeOff,
  LoaderCircle,
  LockKeyhole,
  Mail,
  ShieldCheck,
  UserRound,
} from "lucide-react";
import { buildPlayerAuthCallbackUrl, type PlayerOAuthProvider } from "@/lib/auth/redirects";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

type AuthMode = "login" | "register" | "recover" | "reset";
type BusyAction = "email" | PlayerOAuthProvider | null;

const authCopy: Record<AuthMode, { title: string; description: string; action: string }> = {
  login: {
    title: "أهلاً بعودتك",
    description: "ادخل إلى حساب اللاعب ثم تابع من المكان المناسب لك.",
    action: "تسجيل الدخول",
  },
  register: {
    title: "أنشئ حساب اللاعب",
    description: "حساب واحد للدخول إلى اللعب والبطولات وميزات اللاعب.",
    action: "إنشاء الحساب",
  },
  recover: {
    title: "استعد حسابك",
    description: "أدخل بريدك وسنرسل رابط إعادة تعيين آمناً.",
    action: "إرسال رابط الاستعادة",
  },
  reset: {
    title: "كلمة مرور جديدة",
    description: "اختر كلمة قوية ومختلفة عن السابقة.",
    action: "حفظ كلمة المرور",
  },
};

export function PlayerAuthForm({ mode, next = "/account", initialError = "" }: { mode: AuthMode; next?: string; initialError?: string }) {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [busyAction, setBusyAction] = useState<BusyAction>(null);
  const [error, setError] = useState(initialError);
  const [message, setMessage] = useState("");
  const busy = busyAction !== null;
  const copy = authCopy[mode];

  function resetFeedback(action: BusyAction) {
    setBusyAction(action);
    setError("");
    setMessage("");
  }

  async function signInWithProvider(provider: PlayerOAuthProvider) {
    resetFeedback(provider);
    const supabase = createBrowserSupabaseClient();
    if (!supabase) {
      setError("خدمة الحسابات غير متصلة حالياً. حاول لاحقاً.");
      setBusyAction(null);
      return;
    }

    try {
      const { error: oauthError } = await supabase.auth.signInWithOAuth({
        provider,
        options: { redirectTo: buildPlayerAuthCallbackUrl(window.location.origin, next) },
      });
      if (oauthError) {
        setError(`تعذر بدء الدخول عبر ${provider === "google" ? "Google" : "Apple"}. حاول مجدداً أو استخدم البريد.`);
        setBusyAction(null);
      }
    } catch {
      setError("تعذر فتح مزود تسجيل الدخول. تحقق من الاتصال وحاول مجدداً.");
      setBusyAction(null);
    }
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    resetFeedback("email");
    const form = new FormData(event.currentTarget);
    const email = String(form.get("email") ?? "").trim();
    const password = String(form.get("password") ?? "");
    const supabase = createBrowserSupabaseClient();

    if (!supabase) {
      setError("خدمة الحسابات غير متصلة حالياً. حاول لاحقاً.");
      setBusyAction(null);
      return;
    }

    if (mode === "recover") {
      const { error: recoverError } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: buildPlayerAuthCallbackUrl(window.location.origin, "/account/reset"),
      });
      if (recoverError) setError("تعذر إرسال رابط الاستعادة. تحقق من البريد وحاول مجدداً.");
      else setMessage("إذا كان البريد مرتبطاً بحساب فسيصلك رابط الاستعادة.");
      setBusyAction(null);
      return;
    }

    if (mode === "reset") {
      const confirmPassword = String(form.get("confirmPassword") ?? "");
      if (password !== confirmPassword) {
        setError("كلمتا المرور غير متطابقتين.");
        setBusyAction(null);
        return;
      }
      const { error: updateError } = await supabase.auth.updateUser({ password });
      if (updateError) setError("تعذر تحديث كلمة المرور. اطلب رابط استعادة جديداً.");
      else {
        setMessage("تم تحديث كلمة المرور بنجاح.");
        window.setTimeout(() => {
          router.replace("/account");
          router.refresh();
        }, 700);
      }
      setBusyAction(null);
      return;
    }

    if (mode === "register") {
      const confirmPassword = String(form.get("confirmPassword") ?? "");
      if (password !== confirmPassword) {
        setError("كلمتا المرور غير متطابقتين.");
        setBusyAction(null);
        return;
      }
      const displayName = String(form.get("displayName") ?? "").trim();
      const current = await supabase.auth.getUser();
      const anonymous = current.data.user?.is_anonymous === true || current.data.user?.app_metadata?.provider === "anonymous";
      const { data, error: registerError } = anonymous
        ? await supabase.auth.updateUser(
            { email, password, data: { display_name: displayName } },
            { emailRedirectTo: buildPlayerAuthCallbackUrl(window.location.origin, next) },
          )
        : await supabase.auth.signUp({
            email,
            password,
            options: {
              data: { display_name: displayName },
              emailRedirectTo: buildPlayerAuthCallbackUrl(window.location.origin, next),
            },
          });
      if (registerError) {
        setError(registerError.message.toLowerCase().includes("already") ? "البريد مستخدم في حساب آخر." : "تعذر إنشاء الحساب. تحقق من البيانات وحاول مجدداً.");
        setBusyAction(null);
        return;
      }
      const registeredSession = "session" in data ? data.session : null;
      if (!data.user || (!anonymous && !registeredSession)) {
        setMessage("تم إنشاء الحساب. افتح رسالة التحقق في بريدك لإكمال الدخول.");
        setBusyAction(null);
        return;
      }
    } else {
      const { error: loginError } = await supabase.auth.signInWithPassword({ email, password });
      if (loginError) {
        setError("البريد أو كلمة المرور غير صحيحة.");
        setBusyAction(null);
        return;
      }
    }

    router.replace(next);
    router.refresh();
  }

  const showOAuth = mode === "login" || mode === "register";

  return (
    <form onSubmit={submit} className="player-auth-form" aria-busy={busy}>
      <header className="auth-form-heading">
        <span className="site-kicker site-kicker-dark"><ShieldCheck size={14} />حساب اللاعب</span>
        <h1>{copy.title}</h1>
        <p>{copy.description}</p>
      </header>

      {showOAuth ? (
        <>
          <div className="auth-provider-grid" aria-label="خيارات تسجيل الدخول السريع">
            <button type="button" disabled={busy} onClick={() => signInWithProvider("google")}>
              {busyAction === "google" ? <LoaderCircle size={20} className="animate-spin" /> : <span className="auth-google-mark" aria-hidden="true">G</span>}
              <span>المتابعة عبر Google</span>
            </button>
            <button type="button" disabled={busy} onClick={() => signInWithProvider("apple")}>
              {busyAction === "apple" ? <LoaderCircle size={20} className="animate-spin" /> : <Apple size={21} aria-hidden="true" />}
              <span>المتابعة عبر Apple</span>
            </button>
          </div>
          <div className="auth-divider"><span>أو باستخدام البريد</span></div>
        </>
      ) : null}

      {mode === "register" ? (
        <label className="auth-field">
          <span>الاسم داخل اللعبة</span>
          <div><UserRound size={18} /><input name="displayName" autoComplete="nickname" minLength={2} maxLength={50} placeholder="مثال: سلمان" required disabled={busy} /></div>
        </label>
      ) : null}
      {mode !== "reset" ? (
        <label className="auth-field">
          <span>البريد الإلكتروني</span>
          <div><Mail size={18} /><input name="email" type="email" inputMode="email" autoComplete="email" placeholder="name@example.com" dir="ltr" required disabled={busy} /></div>
        </label>
      ) : null}
      {mode !== "recover" ? (
        <label className="auth-field">
          <span>كلمة المرور</span>
          <div>
            <LockKeyhole size={18} />
            <input name="password" type={showPassword ? "text" : "password"} autoComplete={mode === "login" ? "current-password" : "new-password"} minLength={8} placeholder="8 أحرف على الأقل" required disabled={busy} />
            <button type="button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? "إخفاء كلمة المرور" : "إظهار كلمة المرور"} disabled={busy}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button>
          </div>
        </label>
      ) : null}
      {mode === "register" || mode === "reset" ? (
        <label className="auth-field">
          <span>تأكيد كلمة المرور</span>
          <div><LockKeyhole size={18} /><input name="confirmPassword" type={showPassword ? "text" : "password"} autoComplete="new-password" minLength={8} placeholder="أعد كتابة كلمة المرور" required disabled={busy} /></div>
        </label>
      ) : null}

      {mode === "register" ? <label className="auth-consent"><input type="checkbox" required disabled={busy} /><span>أوافق على <Link href="/legal/terms">شروط الاستخدام</Link> و<Link href="/legal/privacy">سياسة الخصوصية</Link>.</span></label> : null}
      {mode === "login" ? <Link href="/account/recover" className="auth-forgot">نسيت كلمة المرور؟</Link> : null}
      {error ? <p className="auth-alert is-error" role="alert">{error}</p> : null}
      {message ? <p className="auth-alert is-success" role="status"><Check size={17} />{message}</p> : null}

      <button type="submit" disabled={busy} className="site-action w-full">
        {busyAction === "email" ? <LoaderCircle size={18} className="animate-spin" /> : <LockKeyhole size={18} />}
        {busyAction === "email" ? "لحظة…" : copy.action}
        <ArrowLeft size={17} />
      </button>
      <p className="auth-switch">
        {mode === "login" ? <>جديد في أحدعش؟ <Link href={`/account/register?next=${encodeURIComponent(next)}`}>أنشئ حساباً</Link></> : null}
        {mode === "register" ? <>عندك حساب؟ <Link href={`/account/login?next=${encodeURIComponent(next)}`}>سجّل الدخول</Link></> : null}
        {mode === "recover" ? <Link href="/account/login">العودة لتسجيل الدخول</Link> : null}
      </p>
    </form>
  );
}
