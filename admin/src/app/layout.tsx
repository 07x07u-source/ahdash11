import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://ahdash11.com"),
  title: {
    default: "أحدعش 11 — العب وتحدَّ أصحابك",
    template: "%s | أحدعش 11",
  },
  description: "لعبة أسئلة كرة قدم اجتماعية: العب، تحدَّ أصحابك وأنشئ بطولاتك.",
  openGraph: {
    type: "website",
    locale: "ar_SA",
    url: "https://ahdash11.com",
    siteName: "أحدعش 11",
    title: "أحدعش 11 — العب وتحدَّ أصحابك",
    description: "لعبة أسئلة كرة قدم اجتماعية: العب، تحدَّ أصحابك وأنشئ بطولاتك.",
    images: ["/branding/app-icon.png"],
  },
  twitter: {
    card: "summary_large_image",
    title: "أحدعش 11 — العب وتحدَّ أصحابك",
    description: "لعبة أسئلة كرة قدم اجتماعية: العب، تحدَّ أصحابك وأنشئ بطولاتك.",
    images: ["/branding/app-icon.png"],
  },
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
