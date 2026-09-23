import Image from "next/image";
import { Apple, Check, Gamepad2, Monitor, Play, ShieldCheck, Trophy } from "lucide-react";

const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL?.trim();
const googlePlayUrl = process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL?.trim();

export function MobileAppDownload() {
  return (
    <main className="mobile-download-view">
      <div className="mobile-download-glow" aria-hidden="true" />
      <section className="mobile-download-card">
        <div className="mobile-download-brand">
          <Image src="/branding/app-icon.png" alt="أيقونة لعبة أحدعش 11" width={104} height={104} priority />
          <Image src="/branding/logo-horizontal.png" alt="أحدعش 11" width={170} height={56} priority />
        </div>

        <span className="mobile-download-kicker"><Gamepad2 size={16} />تجربة الجوال</span>
        <h1>جولة Party<br /><em>في التطبيق.</em></h1>
        <p>اجمع فريقين حول جهاز واحد، اختَر ست فئات، وابدأ 36 سؤالاً كروياً.</p>

        <div className="mobile-download-benefits" aria-label="مزايا التطبيق">
          <span><Trophy size={17} />Party محلي</span>
          <span><Gamepad2 size={17} />كلاسيك وتدريب</span>
          <span><ShieldCheck size={17} />هوية عربية RTL</span>
        </div>

        <div className="mobile-store-actions">
          <StoreButton href={appStoreUrl} store="App Store" note="نزّله على" icon="apple" />
          <StoreButton href={googlePlayUrl} store="Google Play" note="احصل عليه من" icon="play" />
        </div>

        {!appStoreUrl || !googlePlayUrl ? (
          <p className="mobile-store-note"><Check size={15} />روابط المتاجر ستعمل فور اعتماد صفحة النشر الرسمية.</p>
        ) : null}

        <div className="mobile-desktop-note"><Monitor size={18} /><span>تصفح الموقع الكامل من الكمبيوتر.</span></div>
      </section>
    </main>
  );
}

function StoreButton({ href, store, note, icon }: { href?: string; store: string; note: string; icon: "apple" | "play" }) {
  const Icon = icon === "apple" ? Apple : Play;
  const content = <><Icon size={27} fill={icon === "apple" ? "currentColor" : "none"} /><span><small>{href ? note : "قريباً على"}</small><strong>{store}</strong></span></>;

  if (!href) return <span className="mobile-store-button is-disabled" aria-disabled="true">{content}</span>;
  return <a href={href} className="mobile-store-button" target="_blank" rel="noreferrer">{content}</a>;
}
