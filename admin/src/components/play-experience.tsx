"use client";

import Link from "next/link";
import { Target, UsersRound } from "lucide-react";
import { PartyExperience } from "@/components/gameplay/party-experience";
import { SoloExperience } from "@/components/gameplay/solo-experience";
import { normalizeGameFormat, normalizeGameMode } from "@/lib/site/game-modes";

export function PlayExperience({ mode: modeValue, format: formatValue }: { mode: string; format: string }) {
  const mode = normalizeGameMode(modeValue);
  const format = normalizeGameFormat(formatValue);
  return (
    <div className="real-play-experience">
      <nav className="gameplay-mode-switch" aria-label="اختر طريقة اللعب المحلية">
        <Link href={`/play?mode=${mode}&format=local-party`} className={format === "local-party" ? "is-active" : ""} aria-current={format === "local-party" ? "page" : undefined}><UsersRound size={19} /><span><strong>Party محلي</strong><small>فريقان · 36 سؤالاً</small></span></Link>
        <Link href={`/play?mode=${mode}&format=practice`} className={format === "practice" ? "is-active" : ""} aria-current={format === "practice" ? "page" : undefined}><Target size={19} /><span><strong>Solo / Classic</strong><small>تحدٍ فردي محلي</small></span></Link>
      </nav>
      {format === "local-party" ? <PartyExperience /> : <SoloExperience />}
    </div>
  );
}
