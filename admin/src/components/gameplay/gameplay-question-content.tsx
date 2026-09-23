import type { GameplayQuestion } from "@/lib/gameplay/contracts";

export function GameplayQuestionContent({ question, revealAnswer, showOptions = true }: { question: GameplayQuestion; revealAnswer: boolean; showOptions?: boolean }) {
  const imageQuestion = question.format === "image" || question.format === "image_crop" || question.format === "image_blur";
  return (
    <div className="gameplay-question-content">
      {imageQuestion ? question.imageUrl ? (
        // The authorized catalog owns this media URL and its rights metadata.
        // eslint-disable-next-line @next/next/no-img-element
        <img src={question.imageUrl} alt={`صورة مرتبطة بالسؤال: ${question.text}`} className={question.format === "image_blur" && !revealAnswer ? "is-blurred" : question.format === "image_crop" && !revealAnswer ? "is-cropped" : ""} />
      ) : <div className="gameplay-media-missing">الصورة المرخصة غير متاحة لهذا السؤال.</div> : null}
      <h2>{question.text}</h2>
      {showOptions && (question.format === "multiple_choice" || question.format === "true_false") && question.options.length ? (
        <ol className="gameplay-question-options" aria-label="خيارات السؤال">
          {question.options.map((option, index) => <li key={`${index}-${option}`}><span>{index + 1}</span>{option}</li>)}
        </ol>
      ) : null}
      {revealAnswer ? (
        <div className="gameplay-answer-reveal" aria-live="polite">
          <span>الإجابة</span><strong>{question.correctAnswer}</strong>
          {question.explanation ? <p>{question.explanation}</p> : null}
        </div>
      ) : <p className="gameplay-answer-hidden">الإجابة مخفية حتى يقرر المضيف كشفها.</p>}
    </div>
  );
}
