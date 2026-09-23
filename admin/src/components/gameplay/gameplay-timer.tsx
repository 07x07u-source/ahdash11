"use client";

import { useEffect, useRef, useState } from "react";
import { Clock3 } from "lucide-react";

export function GameplayTimer({ startedAt, durationSeconds, onExpired, label = "الوقت المتبقي" }: {
  startedAt: number | null;
  durationSeconds: number | null;
  onExpired: () => void;
  label?: string;
}) {
  const [clock, setClock] = useState({ key: "", remaining: durationSeconds });
  const expiredKey = useRef<string | null>(null);
  const expiryKey = startedAt === null || durationSeconds === null ? null : `${startedAt}:${durationSeconds}`;

  useEffect(() => {
    if (startedAt === null || durationSeconds === null) {
      return;
    }
    const tick = () => {
      const next = Math.max(0, Math.ceil((startedAt + durationSeconds * 1000 - Date.now()) / 1000));
      setClock((current) => current.key === expiryKey && current.remaining === next ? current : { key: expiryKey ?? "", remaining: next });
      if (next === 0 && expiredKey.current !== expiryKey) {
        expiredKey.current = expiryKey;
        onExpired();
      }
    };
    tick();
    const timer = window.setInterval(tick, 250);
    return () => window.clearInterval(timer);
  }, [durationSeconds, expiryKey, onExpired, startedAt]);

  if (durationSeconds === null || startedAt === null) {
    return <span className="gameplay-timer is-untimed"><Clock3 size={17} /><span>بدون مؤقت</span></span>;
  }
  const safeRemaining = clock.key === expiryKey ? clock.remaining ?? durationSeconds : durationSeconds;
  const urgent = safeRemaining <= Math.min(5, Math.ceil(durationSeconds / 4));
  return (
    <div className={`gameplay-timer ${urgent ? "is-urgent" : ""}`} role="timer" aria-live={urgent ? "assertive" : "off"} aria-label={`${label}: ${safeRemaining} ثانية`}>
      <Clock3 size={18} />
      <span>{label}</span>
      <strong dir="ltr">{safeRemaining}</strong>
      <i aria-hidden="true"><b style={{ width: `${Math.max(0, Math.min(100, safeRemaining / durationSeconds * 100))}%` }} /></i>
    </div>
  );
}
