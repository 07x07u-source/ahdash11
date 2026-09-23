"use client";

import { useCallback, useEffect, useState } from "react";
import {
  ArrowLeft,
  Check,
  CirclePlay,
  Grid3X3,
  LoaderCircle,
  Phone,
  Redo2,
  RotateCcw,
  Shield,
  Shuffle,
  Trophy,
  Undo2,
  UserMinus,
  UsersRound,
} from "lucide-react";
import { GameplayCategoryPicker } from "./gameplay-category-picker";
import { GameplayQuestionContent } from "./gameplay-question-content";
import { GameplayTimer } from "./gameplay-timer";
import { loadGameplayCatalog, loadPartyQuestionPack, type GameplayCatalog } from "@/lib/gameplay/catalog";
import { PARTY_CATEGORY_COUNT, PARTY_HELPERS_PER_TEAM, type PartyHelperId } from "@/lib/gameplay/contracts";
import {
  activePartyQuestion,
  canUsePartyHelper,
  choosePartyQuestion,
  createPartySession,
  expirePartyTimer,
  offerPartySteal,
  partyQuestions,
  partyWinner,
  revealPartyAnswer,
  scorePartyQuestion,
  splitPartyPlayers,
  togglePartyCategory,
  undoPartyScore,
  usePartyHelper as applyPartyHelper,
  validatePartyTeams,
  type PartySession,
  type PartyTeam,
  type TeamIndex,
} from "@/lib/gameplay/party-engine";
import { clearPartySession, readPartySession, writePartySession } from "@/lib/gameplay/persistence";

type SetupStage = "categories" | "teams" | "helpers" | "ready";

const helperIcons: Record<PartyHelperId, typeof Shield> = {
  two_chances: Check,
  call_friend: Phone,
  risk: Trophy,
  bench: UserMinus,
  pass: Redo2,
};

function initialTeams(): [PartyTeam, PartyTeam] {
  return [
    { name: "الفريق الأول", players: [], selectedHelpers: [], usedHelpers: [] },
    { name: "الفريق الثاني", players: [], selectedHelpers: [], usedHelpers: [] },
  ];
}

function playerNames(source: string) {
  return source.split(/[\n,،]+/).map((name) => name.trim()).filter(Boolean);
}

export function PartyExperience() {
  const [catalog, setCatalog] = useState<GameplayCatalog | null>(null);
  const [catalogError, setCatalogError] = useState("");
  const [loadingCatalog, setLoadingCatalog] = useState(true);
  const [savedSession, setSavedSession] = useState<PartySession | null>(null);
  const [session, setSession] = useState<PartySession | null>(null);
  const [stage, setStage] = useState<SetupStage>("categories");
  const [selectedCategoryIds, setSelectedCategoryIds] = useState<string[]>([]);
  const [teams, setTeams] = useState<[PartyTeam, PartyTeam]>(initialTeams);
  const [splitPlayers, setSplitPlayers] = useState(false);
  const [playersInput, setPlayersInput] = useState("");
  const [timerSeconds, setTimerSeconds] = useState<number | null>(60);
  const [error, setError] = useState("");
  const [starting, setStarting] = useState(false);

  const loadCatalog = useCallback(async () => {
    setLoadingCatalog(true);
    setCatalogError("");
    try {
      setCatalog(await loadGameplayCatalog());
    } catch (loadError) {
      setCatalogError(loadError instanceof Error ? loadError.message : "تعذر تحميل كتالوج أحدعش.");
    } finally {
      setLoadingCatalog(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    const timer = window.setTimeout(() => setSavedSession(readPartySession()), 0);
    void loadGameplayCatalog()
      .then((nextCatalog) => { if (!cancelled) setCatalog(nextCatalog); })
      .catch((loadError: unknown) => { if (!cancelled) setCatalogError(loadError instanceof Error ? loadError.message : "تعذر تحميل كتالوج أحدعش."); })
      .finally(() => { if (!cancelled) setLoadingCatalog(false); });
    return () => { cancelled = true; window.clearTimeout(timer); };
  }, []);

  useEffect(() => {
    if (session) writePartySession(session);
  }, [session]);

  const onTimerExpired = useCallback(() => {
    setSession((current) => current ? expirePartyTimer(current) : current);
  }, []);

  function moveToTeams() {
    if (selectedCategoryIds.length !== PARTY_CATEGORY_COUNT) {
      setError("اختر 6 فئات مختلفة بالضبط.");
      return;
    }
    setError("");
    setStage("teams");
  }

  function updateTeamName(index: TeamIndex, name: string) {
    setTeams((current) => current.map((team, teamIndex) => teamIndex === index ? { ...team, name } : team) as [PartyTeam, PartyTeam]);
  }

  function preparePlayerSplit() {
    if (!splitPlayers) return true;
    try {
      const [first, second] = splitPartyPlayers(playerNames(playersInput));
      setTeams((current) => [{ ...current[0], players: first }, { ...current[1], players: second }]);
      setError("");
      return true;
    } catch (splitError) {
      setError(splitError instanceof Error ? splitError.message : "تعذر تقسيم اللاعبين.");
      return false;
    }
  }

  function moveToHelpers() {
    const teamError = validatePartyTeams(teams);
    if (teamError) {
      setError(teamError);
      return;
    }
    if (splitPlayers) {
      const submittedPlayers = playerNames(playersInput);
      const assignedPlayers = teams.flatMap((team) => team.players);
      const assignmentMatches = submittedPlayers.length === assignedPlayers.length
        && submittedPlayers.every((player) => assignedPlayers.includes(player));
      if (!assignmentMatches && !preparePlayerSplit()) return;
    } else {
      setTeams((current) => [{ ...current[0], players: [] }, { ...current[1], players: [] }]);
    }
    setError("");
    setStage("helpers");
  }

  function movePlayer(player: string, from: TeamIndex) {
    const target = (1 - from) as TeamIndex;
    setTeams((current) => {
      if (current[from].players.length <= 1) return current;
      const next = current.map((team) => ({ ...team, players: [...team.players] })) as [PartyTeam, PartyTeam];
      next[from].players = next[from].players.filter((name) => name !== player);
      next[target].players.push(player);
      return next;
    });
  }

  function toggleHelper(teamIndex: TeamIndex, helperId: PartyHelperId) {
    setTeams((current) => current.map((team, index) => {
      if (index !== teamIndex) return team;
      const active = team.selectedHelpers.includes(helperId);
      if (!active && team.selectedHelpers.length >= PARTY_HELPERS_PER_TEAM) return team;
      return { ...team, selectedHelpers: active ? team.selectedHelpers.filter((id) => id !== helperId) : [...team.selectedHelpers, helperId] };
    }) as [PartyTeam, PartyTeam]);
  }

  function moveToReady() {
    if (teams.some((team) => team.selectedHelpers.length !== PARTY_HELPERS_PER_TEAM)) {
      setError("اختر 3 مساعدات لكل فريق.");
      return;
    }
    setError("");
    setStage("ready");
  }

  async function startRound() {
    if (!catalog) return;
    setStarting(true);
    setError("");
    try {
      const categories = selectedCategoryIds.map((id) => catalog.categories.find((category) => category.id === id)).filter((category): category is NonNullable<typeof category> => Boolean(category));
      const questions = await loadPartyQuestionPack(selectedCategoryIds);
      const next = createPartySession({ categories, questions, teams, helpers: catalog.helpers, rules: catalog.rules, timerSeconds });
      clearPartySession();
      setSavedSession(null);
      setSession(next);
    } catch (startError) {
      setError(startError instanceof Error ? startError.message : "تعذر تجهيز الجولة.");
    } finally {
      setStarting(false);
    }
  }

  function newGame() {
    clearPartySession();
    setSavedSession(null);
    setSession(null);
    setStage("categories");
    setSelectedCategoryIds([]);
    setTeams(initialTeams());
    setSplitPlayers(false);
    setPlayersInput("");
    setError("");
  }

  if (session) {
    return <PartySessionView session={session} setSession={setSession} onExpired={onTimerExpired} onReplay={startRound} replaying={starting} onNewGame={newGame} />;
  }

  if (savedSession && !catalog) {
    return <PartyResumeCard session={savedSession} loading={loadingCatalog} error={catalogError} onResume={() => setSession(savedSession)} onRetry={loadCatalog} />;
  }

  if (loadingCatalog) return <GameplayLoading title="نجهّز كتالوج Party الحقيقي…" />;
  if (catalogError || !catalog) return <GameplayFailure title="تعذر فتح Party" message={catalogError || "كتالوج اللعب غير متاح."} onRetry={loadCatalog} />;

  const readyCategories = catalog.categories.filter((category) => category.ready);
  return (
    <section className="party-setup-shell">
      <header className="gameplay-flow-header">
        <div><span className="site-kicker site-kicker-dark"><UsersRound size={15} />Party محلي</span><h1>جهّزوا جولة الـ36 سؤالاً.</h1><p>فريقان، متصفح واحد، ومحتوى منشور من كتالوج أحدعش.</p></div>
        <ol aria-label="مراحل إعداد Party">
          {(["categories", "teams", "helpers", "ready"] as const).map((item, index) => <li key={item} className={stage === item ? "is-current" : ""}><span>{index + 1}</span>{["الفئات", "الفريقان", "المساعدات", "الجاهزية"][index]}</li>)}
        </ol>
      </header>

      {savedSession ? (
        <div className="party-resume-banner">
          <div><CirclePlay size={22} /><span><strong>لديكم جولة محفوظة</strong><small>{partyQuestions(savedSession).filter((question) => question.used).length} من 36 سؤالاً مكتملًا</small></span></div>
          <button type="button" onClick={() => setSession(savedSession)}>متابعة الجولة <ArrowLeft size={17} /></button>
        </div>
      ) : null}

      {stage === "categories" ? (
        <div className="party-setup-panel">
          <div className="gameplay-panel-heading"><div><small>الخطوة 1</small><h2>اختاروا ست فئات</h2><p>كل فئة يجب أن تملك سؤالين سهلين ومتوسطين وصعبين.</p></div><Grid3X3 size={26} /></div>
          <GameplayCategoryPicker categories={readyCategories} selected={selectedCategoryIds} maximum={6} premiumAccess={catalog.premiumAccess} exact onToggle={(id) => { setSelectedCategoryIds((current) => togglePartyCategory(current, id)); setError(""); }} />
          <SetupFooter error={error}><button type="button" className="site-action" onClick={moveToTeams} disabled={selectedCategoryIds.length !== 6}>إعداد الفريقين <ArrowLeft size={18} /></button></SetupFooter>
        </div>
      ) : null}

      {stage === "teams" ? (
        <div className="party-setup-panel">
          <div className="gameplay-panel-heading"><div><small>الخطوة 2</small><h2>سمّوا الفريقين</h2><p>الأسماء بحد أقصى 24 حرفاً، وتقسيم اللاعبين اختياري.</p></div><UsersRound size={27} /></div>
          <div className="party-team-inputs">
            {[0, 1].map((index) => <label key={index}><span>اسم الفريق {index + 1}</span><input value={teams[index as TeamIndex].name} maxLength={24} onChange={(event) => updateTeamName(index as TeamIndex, event.target.value)} /></label>)}
          </div>
          <label className="party-split-toggle"><input type="checkbox" checked={splitPlayers} onChange={(event) => setSplitPlayers(event.target.checked)} /><span><Shuffle size={19} /><b>قسّم اللاعبين تلقائياً</b><small>اكتب الأسماء وسنوزعهم بالتساوي، ويمكنك تعديل التوزيع.</small></span></label>
          {splitPlayers ? <div className="party-player-list"><label><span>أسماء اللاعبين — افصل بينهم بفاصلة أو سطر</span><textarea value={playersInput} onChange={(event) => { setPlayersInput(event.target.value); setTeams((current) => [{ ...current[0], players: [] }, { ...current[1], players: [] }]); }} placeholder="سلمان، خالد، نواف، ماجد" rows={4} /></label><button type="button" className="site-action-secondary dark" onClick={preparePlayerSplit}><Shuffle size={17} />وزّع الأسماء</button></div> : null}
          {teams.some((team) => team.players.length) ? <div className="party-player-distribution">{teams.map((team, index) => <div key={team.name}><strong>{team.name}</strong>{team.players.map((player) => <button type="button" key={player} onClick={() => movePlayer(player, index as TeamIndex)}>{player}<span>نقل</span></button>)}</div>)}</div> : null}
          <SetupFooter error={error} onBack={() => setStage("categories")}><button type="button" className="site-action" onClick={moveToHelpers}>اختيار المساعدات <ArrowLeft size={18} /></button></SetupFooter>
        </div>
      ) : null}

      {stage === "helpers" ? (
        <div className="party-setup-panel">
          <div className="gameplay-panel-heading"><div><small>الخطوة 3</small><h2>ثلاث مساعدات لكل فريق</h2><p>كل مساعدة تُستخدم مرة واحدة فقط. «اتصال بصديق» مؤقت محلي ولا يتصل بأي شخص.</p></div><Shield size={27} /></div>
          <div className="party-helper-setup">
            {teams.map((team, teamIndex) => <div key={teamIndex}><header><strong>{team.name}</strong><span>{team.selectedHelpers.length}/3</span></header><div>{catalog.helpers.map((helper) => {
              const Icon = helperIcons[helper.id];
              const selected = team.selectedHelpers.includes(helper.id);
              const benchUnavailable = helper.id === "bench" && teams[1 - teamIndex].players.length === 0;
              return <button type="button" key={helper.id} disabled={benchUnavailable || (!selected && team.selectedHelpers.length >= 3)} aria-pressed={selected} className={selected ? "is-selected" : ""} onClick={() => toggleHelper(teamIndex as TeamIndex, helper.id)}><Icon size={20} /><span><b>{helper.name}</b><small>{benchUnavailable ? "تحتاج إلى تقسيم لاعبين" : helper.description}</small></span>{selected ? <Check size={17} /> : null}</button>;
            })}</div></div>)}
          </div>
          <SetupFooter error={error} onBack={() => setStage("teams")}><button type="button" className="site-action" onClick={moveToReady}>ملخص الجاهزية <ArrowLeft size={18} /></button></SetupFooter>
        </div>
      ) : null}

      {stage === "ready" ? (
        <div className="party-setup-panel party-ready-panel">
          <div className="gameplay-panel-heading"><div><small>الخطوة 4</small><h2>كل شيء جاهز</h2><p>راجعوا التكوين ثم ابدأوا تحميل الحزمة الفعلية.</p></div><Check size={28} /></div>
          <div className="party-ready-grid">
            {teams.map((team, index) => <article key={team.name}><span>الفريق {index + 1}</span><h3>{team.name}</h3><p>{team.players.length ? team.players.join(" · ") : "بدون توزيع أسماء"}</p><ul>{team.selectedHelpers.map((id) => <li key={id}>{catalog.helpers.find((helper) => helper.id === id)?.name}</li>)}</ul></article>)}
            <aside><span>الفئات</span><strong>{selectedCategoryIds.length}</strong><small>36 سؤالاً فريداً</small></aside>
            <aside><span>المؤقت</span><strong>{timerSeconds ?? "∞"}</strong><small>{timerSeconds ? "ثانية للسؤال" : "بدون توقيت"}</small></aside>
          </div>
          <fieldset className="party-timer-options"><legend>وقت السؤال</legend>{[15, 20, 30, 45, 60, null].map((value) => <button type="button" key={value ?? "none"} aria-pressed={timerSeconds === value} className={timerSeconds === value ? "is-selected" : ""} onClick={() => setTimerSeconds(value)}>{value ? `${value} ثانية` : "بدون مؤقت"}</button>)}</fieldset>
          <SetupFooter error={error} onBack={() => setStage("helpers")}><button type="button" className="site-action" onClick={() => void startRound()} disabled={starting}>{starting ? <LoaderCircle size={18} className="animate-spin" /> : <CirclePlay size={18} />}{starting ? "نجهز 36 سؤالاً…" : "ابدأ Party"}</button></SetupFooter>
        </div>
      ) : null}
    </section>
  );
}

function SetupFooter({ error, onBack, children }: { error: string; onBack?: () => void; children: React.ReactNode }) {
  return <footer className="gameplay-setup-footer">{onBack ? <button type="button" className="site-action-secondary dark" onClick={onBack}>رجوع</button> : <span />}{error ? <p role="alert">{error}</p> : null}{children}</footer>;
}

function PartySessionView({ session, setSession, onExpired, onReplay, replaying, onNewGame }: {
  session: PartySession;
  setSession: React.Dispatch<React.SetStateAction<PartySession | null>>;
  onExpired: () => void;
  onReplay: () => Promise<void>;
  replaying: boolean;
  onNewGame: () => void;
}) {
  const [benchPickerOpen, setBenchPickerOpen] = useState(false);
  const active = activePartyQuestion(session);
  const activeCategory = active ? session.categories.find((category) => category.id === active.categoryId) : null;
  const usedCount = partyQuestions(session).filter((question) => question.used).length;
  const winner = partyWinner(session);
  const selectedHelper = session.armedHelper ? session.helpers.find((helper) => helper.id === session.armedHelper) : null;

  function update(transform: (current: PartySession) => PartySession) {
    setSession((current) => current ? transform(current) : current);
  }

  if (session.phase === "result") {
    return (
      <section className="party-result-shell" aria-live="polite">
        <span className="party-result-trophy"><Trophy size={44} /></span>
        <span className="site-kicker site-kicker-dark">انتهت 36 مواجهة</span>
        <h1>{winner === null ? "تعادل يليق بالمنافسة." : `${session.teams[winner].name} حسمها.`}</h1>
        <div className="party-result-scores">{session.teams.map((team, index) => <article key={team.name} className={winner === index ? "is-winner" : ""}><small>{winner === index ? "الفائز" : "النتيجة"}</small><strong>{team.name}</strong><b dir="ltr">{session.scores[index]}</b></article>)}</div>
        <p>الحالة محفوظة محلياً في هذا المتصفح فقط، بلا مزامنة سحابية.</p>
        <div className="party-result-actions">
          <button type="button" className="site-action" disabled={replaying} onClick={() => void onReplay()}>{replaying ? <LoaderCircle size={18} className="animate-spin" /> : <RotateCcw size={18} />}إعادة بنفس الإعداد</button>
          <button type="button" className="site-action-secondary dark" onClick={() => update(undoPartyScore)}><Undo2 size={17} />تراجع عن آخر نتيجة</button>
          <button type="button" className="site-action-secondary dark" onClick={onNewGame}>لعبة جديدة</button>
        </div>
      </section>
    );
  }

  if (active && (session.phase === "answering" || session.phase === "steal" || session.phase === "revealed")) {
    const answerer = session.teams[session.answeringTeamIndex];
    const allowedScoreTeams: TeamIndex[] = session.answerContext === "primary" ? [0, 1] : [session.answeringTeamIndex];
    return (
      <section className="party-question-shell">
        <header className="party-live-score"><div>{session.teams.map((team, index) => <span key={team.name} className={session.answeringTeamIndex === index ? "is-answering" : ""}><small>{team.name}</small><strong dir="ltr">{session.scores[index]}</strong></span>)}</div><aside><small>{activeCategory?.name}</small><strong>{active.pointValue} نقطة</strong></aside></header>
        <div className="party-question-status"><span>{session.phase === "steal" ? "فرصة خطف" : session.answerContext === "pass" ? "الفخ مفعّل" : "دور الإجابة"}</span><strong>{answerer.name}</strong>{selectedHelper ? <small>{selectedHelper.name}{session.helperDetail ? ` · ${session.helperDetail}` : ""}</small> : null}</div>
        {session.phase !== "revealed" ? <GameplayTimer startedAt={session.timerStartedAt} durationSeconds={session.timerDurationSeconds} onExpired={onExpired} label={session.phase === "steal" ? "وقت الخطف" : "وقت الإجابة"} /> : null}
        <GameplayQuestionContent question={active} revealAnswer={session.phase === "revealed"} />
        {session.phase === "answering" && !session.armedHelper ? <div className="party-live-helpers"><span>مساعدة {session.teams[session.turnTeamIndex].name}</span>{session.helpers.filter((helper) => helper.timing === "after_question").map((helper) => { const Icon = helperIcons[helper.id]; return <button type="button" key={helper.id} disabled={!canUsePartyHelper(session, helper.id)} onClick={() => { if (helper.id === "bench") setBenchPickerOpen((open) => !open); else update((current) => applyPartyHelper(current, helper.id, helper.id === "call_friend" ? "20 ثانية مستقلة" : null)); }}><Icon size={17} />{helper.name}</button>; })}</div> : null}
        {benchPickerOpen && session.phase === "answering" && !session.armedHelper ? <div className="party-bench-picker" role="group" aria-label="اختر لاعباً ليستريح"><span>من يستريح في هذا السؤال؟</span><div>{session.teams[1 - session.turnTeamIndex].players.map((player) => <button type="button" key={player} onClick={() => { update((current) => applyPartyHelper(current, "bench", player)); setBenchPickerOpen(false); }}><UserMinus size={16} />{player}</button>)}</div></div> : null}
        {session.phase !== "revealed" ? (
          <footer className="party-question-actions">
            {session.phase === "answering" && session.answerContext !== "pass" && session.rules.allowSteal ? <button type="button" className="site-action-secondary dark" onClick={() => update(offerPartySteal)}>لم يُجب — امنح الخطف</button> : null}
            <button type="button" className="site-action" onClick={() => update(revealPartyAnswer)}>كشف الإجابة <ArrowLeft size={17} /></button>
          </footer>
        ) : (
          <footer className="party-score-decision">
            <span>لمن تُحتسب الإجابة الصحيحة؟</span>
            <div>{allowedScoreTeams.map((teamIndex) => <button type="button" key={teamIndex} className="site-action" onClick={() => update((current) => scorePartyQuestion(current, teamIndex))}><Check size={17} />{session.teams[teamIndex].name}</button>)}<button type="button" className="site-action-secondary dark" onClick={() => update((current) => scorePartyQuestion(current, null))}>لا إجابة صحيحة</button></div>
          </footer>
        )}
      </section>
    );
  }

  return (
    <section className="party-board-shell">
      <header className="party-board-header">
        <div><span className="site-kicker site-kicker-dark"><Grid3X3 size={14} />لوحة 6 × 6</span><h1>دور {session.teams[session.turnTeamIndex].name}</h1><p>{usedCount} من 36 سؤالاً انتهى</p></div>
        <div className="party-board-scores">{session.teams.map((team, index) => <span key={team.name} className={session.turnTeamIndex === index ? "is-turn" : ""}><small>{team.name}</small><strong dir="ltr">{session.scores[index]}</strong></span>)}</div>
      </header>
      <div className="party-before-helper"><span>مساعدة قبل السؤال</span>{session.helpers.filter((helper) => helper.timing === "before_question").map((helper) => { const Icon = helperIcons[helper.id]; const armed = session.armedHelper === helper.id; return <button type="button" key={helper.id} className={armed ? "is-armed" : ""} disabled={!armed && !canUsePartyHelper(session, helper.id)} onClick={() => { if (!armed) update((current) => applyPartyHelper(current, helper.id, null)); }}><Icon size={17} />{armed ? `${helper.name} مفعّلة` : helper.name}</button>; })}{session.scoreEvents.length ? <button type="button" onClick={() => update(undoPartyScore)}><Undo2 size={16} />تراجع عن آخر نتيجة</button> : null}</div>
      <div className="party-board" aria-label="لوحة أسئلة Party">
        {session.categories.map((category) => <article key={category.id}>
          <header style={category.imageUrl ? { backgroundImage: `linear-gradient(180deg,rgba(9,29,22,.1),rgba(9,29,22,.9)),url(${JSON.stringify(category.imageUrl)})`, backgroundPosition: `${category.focalX * 100}% ${category.focalY * 100}%` } : undefined}><small>فئة الفريق {category.ownerTeamIndex + 1}</small><strong>{category.name}</strong></header>
          <div>{category.questions.map((question) => <button type="button" key={question.id} disabled={question.used} onClick={() => update((current) => choosePartyQuestion(current, question.id))} aria-label={`${category.name}، ${question.pointValue} نقطة، ${question.used ? "مستخدمة" : "متاحة"}`}><span>{question.used ? <Check size={18} /> : question.pointValue}</span><small>{question.used ? "انتهى" : question.difficulty === "easy" ? "سهل" : question.difficulty === "medium" ? "متوسط" : "صعب"}</small></button>)}</div>
        </article>)}
      </div>
    </section>
  );
}

function GameplayLoading({ title }: { title: string }) {
  return <div className="gameplay-state-card" role="status"><LoaderCircle size={28} className="animate-spin" /><h2>{title}</h2><p>لن نستخدم أسئلة تجريبية إذا تعذر الكتالوج.</p></div>;
}

function GameplayFailure({ title, message, onRetry }: { title: string; message: string; onRetry: () => void }) {
  return <div className="gameplay-state-card is-error" role="alert"><Shield size={30} /><h2>{title}</h2><p>{message}</p><button type="button" className="site-action" onClick={onRetry}>إعادة المحاولة</button></div>;
}

function PartyResumeCard({ session, loading, error, onResume, onRetry }: { session: PartySession; loading: boolean; error: string; onResume: () => void; onRetry: () => void }) {
  const used = partyQuestions(session).filter((question) => question.used).length;
  return <section className="party-resume-standalone"><div className="gameplay-state-card"><CirclePlay size={34} /><span className="site-kicker site-kicker-dark">جولة محفوظة</span><h2>أكملوا من السؤال التالي.</h2><p>{used} من 36 سؤالاً مكتملًا. لا تحتاج الجولة المحفوظة إلى إعادة تحميل الكتالوج.</p><button type="button" className="site-action" onClick={onResume}>متابعة الجولة <ArrowLeft size={17} /></button>{loading ? <small>نحاول تحديث الكتالوج في الخلفية…</small> : error ? <button type="button" className="site-action-secondary dark" onClick={onRetry}>إعادة تحميل الكتالوج</button> : null}</div></section>;
}
