import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "لوحة أحدعش | 11",
    template: "%s | أحدعش 11",
  },
  description: "لوحة تشغيل وإدارة منصة أحدعش لمسابقات كرة القدم.",
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
