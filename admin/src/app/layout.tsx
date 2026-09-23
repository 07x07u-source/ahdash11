import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "أحدعش 11 — العب وتحدَّ أصحابك",
    template: "%s | أحدعش 11",
  },
  description: "لعبة أسئلة كرة قدم اجتماعية: العب، تحدَّ أصحابك وأنشئ بطولاتك.",
  icons: {
    icon: "/branding/app-icon.png",
    apple: "/branding/app-icon.png",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
