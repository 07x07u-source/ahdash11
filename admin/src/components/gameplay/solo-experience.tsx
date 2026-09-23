"use client";

import { useCallback, useEffect, useState } from "react";
import { ArrowLeft, Check, Gauge, LoaderCircle, RotateCcw, Shield, Sparkles, Target, Trophy, X } from "lucide-react";
import { GameplayCategoryPicker } from "./gameplay-category-picker";
import { GameplayQuestionContent } from "./gameplay-question-content";
import { GameplayTimer } from "./gameplay-timer";
import { loadGameplayCatalog, loadSoloQuestionPack, recordSoloAnswer, type GameplayCatalog } from "@/lib/gameplay/catalog";
import type { GameplayDifficulty } from "@/lib/gameplay/contracts";
import { readSoloPersonalBest, writeSoloPersonalBest } from "@/lib/gameplay/persistence";
import { advanceSoloQuestion, answerSoloQuestion, createSoloSession, currentSoloQuestion, expireSoloTimer, soloAccuracy, soloLongestStreak, type SoloSession, type SoloSetup } from "@/lib/gameplay/solo-engine";

const difficultyOptions: { value: GameplayDifficulty; label: string; copy: string }[] = [
  { value: "easy", label: "سهل", copy: "مدخل هادئ" },
  { value: "medium", label: "متوسط", copy: "توازن مناسب" },
  { value: "hard", label: "صعب", copy: "اختبار قوي" },
  { value: "expert", label: "خبير", copy: "أدق التفاصيل" },
];

export function SoloExperience() {
  const [catalog, setCatalog] = useState<GameplayCatalog | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [selectedCategoryIds, setSelectedCategoryIds] = useState<string[]>([]);
  const [difficulty, setDifficulty] = useState<GameplayDifficulty>("medium");
  const [questionCount, setQuestionCount] = useState(11);
  const [session, setSession] = useState<SoloSession | null>(null);
  const [starting, setStarting] = useState(false);

  const loadCatalog = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      setCatalog(await loadGameplayCatalog());
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "تعذر تحميل الكتالوج.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    void loadGameplayCatalog()
      .then((nextCatalog) => { if (!cancelled) setCatalog(nextCatalog); })
      .catch((loadError: unknown) => { if (!cancelled) setError(loadError instanceof Error ? loadError.message : "تعذر تحميل الكتالوج."); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, []);

  const onTimerExpired = useCallback(() => {
    if (!session) return;
    const question = currentSoloQuestion(session);
    const nextSession = expireSoloTimer(session);
    if (nextSession === session) return;
    setSession(nextSession);
    if (question) void recordSoloAnswer(question.id, null);
  }, [session]);

  async function start(setup?: SoloSetup) {
    const effective: SoloSetup = setup ?? { categoryIds: selectedCategoryIds, difficulty, questionCount };
    if (!effective.categoryIds.length) {
      setError("اختر فئة واحدة على الأقل.");
      return;
    }
    setStarting(true);
    setError("");
    try {
      const questions = await loadSoloQuestionPack({ categoryIds: effective.categoryIds, difficulty: effective.difficulty, count: effective.questionCount });
      setSession(createSoloSession(questions, effective, readSoloPersonalBest()));
    } catch (startError) {
      setError(startError instanceof Error ? startError.message : "تعذر تجهيز التحدي.");
    } finally {
      setStarting(false);
    }
  }

  function answer(index: number | null) {
    if (!session) return;
    const question = currentSoloQuestion(session);
    const nextSession = answerSoloQuestion(session, index);
    if (nextSession === session || !question) return;
    setSession(nextSession);
    void recordSoloAnswer(question.id, index);
  }

  function next() {
    if (!session) return;
    const advanced = advanceSoloQuestion(session);
    if (advanced.phase === "result") writeSoloPersonalBest(advanced.personalBest);
    setSession(advanced);
  }

  if (loading) return <div className="gameplay-state-card" role="status"><LoaderCircle size={28} className="animate-spin" /><h2>نجهّز التحدي الفردي…</h2><p>المحتوى يأتي من حزمة Solo المنشورة.</p></div>;
  if (!catalog) return <div className="gameplay-state-card is-error" role="alert"><Shield size={30} /><h2>تعذر فتح Solo</h2><p>{error || "الكتالوج غير متاح."}</p><button type="button" className="site-action" onClick={loadCatalog}>إعادة المحاولة</button></div>;

  if (!session) {
    return (
      <section className="solo-setup-shell">
        <header className="gameplay-flow-header"><div><span className="site-kicker site-kicker-dark"><Target size={15} />Solo / Classic</span><h1>جولة على مقاس معرفتك.</h1><p>اختر الفئات والصعوبة وعدد الأسئلة، ثم ابدأ بمحتوى حقيقي.</p></div></header>
        <div className="party-setup-panel">
          <div className="gameplay-panel-heading"><div><small>إعداد الجولة</small><h2>اختر الفئات</h2><p>يمكنك الجمع بين أكثر من فئة متاحة.</p></div><Sparkles size={27} /></div>
          <GameplayCategoryPicker categories={catalog.categories.filter((category) => category.questionCount > 0)} selected={selectedCategoryIds} maximum={6} premiumAccess={catalog.premiumAccess} onToggle={(id) => { setSelectedCategoryIds((current) => current.includes(id) ? current.filter((value) => value !== id) : current.length < 6 ? [...current, id] : current); setError(""); }} />
          <div className="solo-setup-options">
            <fieldset><legend>مستوى الصعوبة</legend><div>{difficultyOptions.map((option) => <button type="button" key={option.value} aria-pressed={difficulty === option.value} className={difficulty === option.value ? "is-selected" : ""} onClick={() => setDifficulty(option.value)}><strong>{option.label}</strong><small>{option.copy}</small></button>)}</div></fieldset>
            <fieldset><legend>عدد الأسئلة</legend><div>{[5, 11, 15].map((count) => <button type="button" key={count} aria-pressed={questionCount === count} className={questionCount === count ? "is-selected" : ""} onClick={() => setQuestionCount(count)}><strong>{count}</strong><small>{count === 11 ? "جولة أحدعش" : count < 11 ? "سريعة" : "مطوّلة"}</small></button>)}</div></fieldset>
          </div>
          <footer className="gameplay-setup-footer"><span />{error ? <p role="alert">{error}</p> : null}<button type="button" className="site-action" disabled={starting || !selectedCategoryIds.length} onClick={() => void start()}>{starting ? <LoaderCircle size={18} className="animate-spin" /> : <Target size={18} />}{starting ? "نختار الأسئلة…" : "ابدأ التحدي"}<ArrowLeft size={17} /></button></footer>
        </div>
      </section>
    );
  }

  const question = currentSoloQuestion(session);
  if (session.phase === "result") {
    return (
      <section className="solo-result-shell" aria-live="polite">
        <span><Trophy size={42} /></span><small>انتهت الجولة</small><h1 dir="ltr">{session.score}</h1><h2>{session.score >= session.personalBest ? "رقمك الأفضل محفوظ على هذا المتصفح." : "جولة مكتملة—والأفضل ما زال ينتظرك."}</h2>
        <div><article><small>الدقة</small><strong dir="ltr">{Math.round(soloAccuracy(session) * 100)}%</strong></article><article><small>الإجابات الصحيحة</small><strong>{session.records.filter((record) => record.correct).length}/{session.questions.length}</strong></article><article><small>أطول سلسلة</small><strong>{soloLongestStreak(session)}</strong></article><article><small>أفضل نتيجة</small><strong dir="ltr">{session.personalBest}</strong></article></div>
        <footer><button type="button" className="site-action" disabled={starting} onClick={() => void start(session.setup)}><RotateCcw size={18} />إعادة الجولة</button><button type="button" className="site-action-secondary dark" onClick={() => setSession(null)}>تعديل الإعداد</button></footer>
      </section>
    );
  }

  if (!question) return null;
  const revealed = session.phase === "revealed";
  const correctIndex = question.correctOptionIndex;
  const lastRecord = session.records.at(-1);
  return (
    <section className="solo-question-shell">
      <header><div><span className="site-kicker site-kicker-dark"><Gauge size={14} />{difficultyOptions.find((item) => item.value === session.setup.difficulty)?.label}</span><h1>السؤال {session.currentIndex + 1} من {session.questions.length}</h1></div><aside><small>النقاط</small><strong dir="ltr">{session.score}</strong></aside></header>
      {!revealed ? <GameplayTimer startedAt={session.questionStartedAt} durationSeconds={session.timerSeconds} onExpired={onTimerExpired} /> : null}
      <GameplayQuestionContent question={question} revealAnswer={revealed} showOptions={false} />
      <div className="solo-answer-grid">{question.options.map((option, index) => {
        const isCorrect = revealed && index === correctIndex;
        const isWrong = revealed && session.selectedIndex === index && index !== correctIndex;
        return <button type="button" key={`${index}-${option}`} disabled={revealed} onClick={() => answer(index)} className={isCorrect ? "is-correct" : isWrong ? "is-wrong" : ""}><span>{index + 1}</span><strong>{option}</strong>{isCorrect ? <Check size={19} /> : isWrong ? <X size={19} /> : null}</button>;
      })}</div>
      {revealed ? <footer className="solo-reveal-footer"><p className={lastRecord?.correct ? "is-correct" : "is-wrong"}>{lastRecord?.correct ? `إجابة صحيحة +${(lastRecord.basePoints + lastRecord.speedBonus)}` : session.selectedIndex === null ? "انتهى الوقت" : "إجابة غير صحيحة"}</p><button type="button" className="site-action" onClick={next}>{session.currentIndex + 1 === session.questions.length ? "عرض النتيجة" : "السؤال التالي"}<ArrowLeft size={17} /></button></footer> : null}
    </section>
  );
}
