import { PlayExperience } from "@/components/play-experience";
import { requirePlayerPage } from "@/lib/auth/player";

export const metadata = {
  title: "العب الآن",
  description: "ابدأ Party محلياً أو جولة Solo بمحتوى أحدعش 11 المنشور.",
};

export const dynamic = "force-dynamic";

export default async function PlayPage({ searchParams }: { searchParams: Promise<{ mode?: string; format?: string }> }) {
  const query = await searchParams;
  const returnParams = new URLSearchParams();
  if (typeof query.mode === "string") returnParams.set("mode", query.mode);
  if (typeof query.format === "string") returnParams.set("format", query.format);
  const returnTo = `/play${returnParams.toString() ? `?${returnParams.toString()}` : ""}`;
  await requirePlayerPage(returnTo, "/account/register");
  const mode = typeof query.mode === "string" ? query.mode : "classic";
  const format = typeof query.format === "string" ? query.format : "local-party";
  return (
    <div className="site-paper-section min-h-[calc(100vh-4.75rem)]">
      <div className="site-container py-8 sm:py-12">
        <PlayExperience mode={mode} format={format} />
      </div>
    </div>
  );
}
