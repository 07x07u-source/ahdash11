import Image from "next/image";
import { Check, CircleDot, UsersRound } from "lucide-react";

type AuthSurfaceMode = "login" | "register" | "recover" | "reset";

const surfaceCopy: Record<AuthSurfaceMode, { eyebrow: string; title: string; description: string }> = {
  login: {
    eyebrow: "ارجع إلى تشكيلتك",
    title: "حسابك هو بوابة الملعب.",
    description: "سجّل الدخول للوصول إلى اللعب والبطولات ومساحات حساب اللاعب المتاحة على الموقع.",
  },
  register: {
    eyebrow: "بداية مرتبة",
    title: "جهّز حسابك قبل صافرة البداية.",
    description: "أنشئ هويتك في أحدعش ثم اختر المسار المناسب لجولتك.",
  },
  recover: {
    eyebrow: "عودة آمنة",
    title: "رابط واحد يعيدك.",
    description: "نستخدم بريد الحساب لإرسال مسار آمن لإعادة تعيين كلمة المرور.",
  },
  reset: {
    eyebrow: "الخطوة الأخيرة",
    title: "غيّر كلمة المرور وارجع.",
    description: "بعد الحفظ ستعود مباشرة إلى مركز اللاعب.",
  },
};

export function PlayerAuthSurface({ mode, children }: { mode: AuthSurfaceMode; children: React.ReactNode }) {
  const copy = surfaceCopy[mode];
  return (
    <div className={`auth-surface auth-surface-${mode}`}>
      <aside className="auth-visual" aria-label="عن تجربة أحدعش 11">
        <div className="auth-brand-lockup">
          <Image src="/branding/logo-horizontal.png" alt="أحدعش 11" width={190} height={64} priority />
          <span>لعبة Party كروية سعودية</span>
        </div>
        <figure className="auth-visual-art">
          <Image
            src="/artwork/website-game-modes.png"
            alt="فريقان يستعدان لجولة أسئلة كرة قدم"
            fill
            sizes="(min-width: 1024px) 48vw, 1px"
          />
          <figcaption><UsersRound size={15} />Party محلي، واضح من البداية</figcaption>
        </figure>
        <div className="auth-visual-copy">
          <span className="auth-visual-kicker"><CircleDot size={14} />{copy.eyebrow}</span>
          <h2>{copy.title}</h2>
          <p>{copy.description}</p>
          <div className="auth-party-facts">
            <span><UsersRound size={18} /><b>فريقان</b><small>على جهاز واحد</small></span>
            <span><Check size={18} /><b>ست فئات</b><small>و36 سؤالاً</small></span>
          </div>
        </div>
      </aside>
      <div className="auth-form-wrap">{children}</div>
    </div>
  );
}
