import '../../../core/storage/app_database.dart';
import '../../game/domain/game_mode.dart';
import '../domain/question_history_entry.dart';
import '../domain/question_repository.dart';
import '../domain/quiz_question.dart';

final class DriftQuestionRepository implements QuestionRepository {
  DriftQuestionRepository(this._database);

  final AppDatabase _database;

  static const demoQuestions = <QuizQuestion>[
    QuizQuestion(
      id: 'demo-eagle-1',
      text: 'في المحتوى التجريبي: أي رمز يُستخدم عادةً لتمثيل كرة القدم؟',
      options: ['كرة قدم', 'مضرب', 'مسبح', 'دراجة'],
      correctOptionIndex: 0,
      categoryId: 'eagle-eye-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'visual'],
    ),
    QuizQuestion(
      id: 'demo-eagle-2',
      text: 'أي لون هو اللون المميز في هوية أحدعش؟',
      options: ['الأخضر الكهربائي', 'البني', 'الوردي', 'البنفسجي'],
      correctOptionIndex: 0,
      categoryId: 'eagle-eye-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'brand'],
    ),
    QuizQuestion(
      id: 'demo-eagle-3',
      text: 'كم خيارًا يظهر في شاشة السؤال داخل هذا الإصدار؟',
      options: ['خياران', 'ثلاثة', 'أربعة', 'خمسة'],
      correctOptionIndex: 2,
      categoryId: 'eagle-eye-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo'],
    ),
    QuizQuestion(
      id: 'demo-transfer-1',
      text: 'ماذا تعني نافذة الانتقالات في كرة القدم؟',
      options: [
        'فترة تسجيل اللاعبين',
        'وقت المباراة',
        'فترة الراحة',
        'ركلات الترجيح',
      ],
      correctOptionIndex: 0,
      categoryId: 'transfers-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'transfers'],
    ),
    QuizQuestion(
      id: 'demo-transfer-2',
      text: 'أي سجل يصف ترتيب أندية اللاعب عبر مسيرته؟',
      options: ['مسيرة اللاعب', 'سعة الملعب', 'لون القميص', 'وقت المباراة'],
      correctOptionIndex: 0,
      categoryId: 'transfers-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'career'],
    ),
    QuizQuestion(
      id: 'demo-transfer-3',
      text: 'في سؤال انتقالات، ما المعلومة الأنسب للتحقق منها؟',
      options: ['النادي السابق', 'لون العشب', 'حجم الكرة', 'رقم المدرج'],
      correctOptionIndex: 0,
      categoryId: 'transfers-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'metadata'],
    ),
    QuizQuestion(
      id: 'demo-competition-1',
      text: 'ما نوع البطولة التي تجمع أندية من أكثر من دولة؟',
      options: ['قارية', 'محلية فقط', 'ودية داخلية', 'تدريبية'],
      correctOptionIndex: 0,
      categoryId: 'competitions-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'competition'],
    ),
    QuizQuestion(
      id: 'demo-competition-2',
      text: 'أي كلمة تصف ترتيب الفرق بحسب النقاط؟',
      options: [
        'جدول الدوري',
        'قائمة التبديلات',
        'تقرير الملعب',
        'سجل الإصابات',
      ],
      correctOptionIndex: 0,
      categoryId: 'competitions-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'league'],
    ),
    QuizQuestion(
      id: 'demo-competition-3',
      text: 'في نظام المجموعات، ما الذي يحدد الانتقال للدور التالي عادةً؟',
      options: ['الترتيب', 'لون الطقم', 'سعة الملعب', 'عمر المدرب'],
      correctOptionIndex: 0,
      categoryId: 'competitions-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'format'],
    ),
    QuizQuestion(
      id: 'demo-locker-1',
      text: 'من يحدد الخطة الأساسية للفريق عادةً؟',
      options: ['المدرب', 'المصور', 'المعلق', 'حامل الراية'],
      correctOptionIndex: 0,
      categoryId: 'locker-room-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'coach'],
    ),
    QuizQuestion(
      id: 'demo-locker-2',
      text: 'أي وصف يطابق التشكيلة الأساسية؟',
      options: [
        'اللاعبون الذين يبدأون المباراة',
        'الجمهور',
        'الطاقم الإعلامي',
        'الحكام فقط',
      ],
      correctOptionIndex: 0,
      categoryId: 'locker-room-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'lineup'],
    ),
    QuizQuestion(
      id: 'demo-locker-3',
      text: 'أين تُعرض أرقام قمصان اللاعبين عادةً؟',
      options: ['على القميص', 'على العشب', 'على الكرة فقط', 'على المرمى'],
      correctOptionIndex: 0,
      categoryId: 'locker-room-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'shirt'],
    ),
    QuizQuestion(
      id: 'demo-stadium-1',
      text: 'ما الذي تقيسه سعة الملعب؟',
      options: [
        'عدد الحضور الممكن',
        'طول المباراة',
        'عدد التبديلات',
        'سرعة اللاعب',
      ],
      correctOptionIndex: 0,
      categoryId: 'stadiums-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'capacity'],
    ),
    QuizQuestion(
      id: 'demo-stadium-2',
      text: 'أي جزء يوجد عند طرفي ملعب كرة القدم؟',
      options: ['المرمى', 'منصة التتويج', 'غرفة الصحافة', 'بوابة التذاكر'],
      correctOptionIndex: 0,
      categoryId: 'stadiums-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'pitch'],
    ),
    QuizQuestion(
      id: 'demo-stadium-3',
      text: 'أي معلومة تربط الملعب بموقعه؟',
      options: ['المدينة', 'رقم اللاعب', 'نتيجة المباراة', 'نوع الجائزة'],
      correctOptionIndex: 0,
      categoryId: 'stadiums-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'location'],
    ),
    QuizQuestion(
      id: 'demo-awards-1',
      text: 'لمن تُمنح الجائزة الفردية؟',
      options: ['لفرد', 'لملعب', 'لجمهور كامل دائمًا', 'لجدول الدوري'],
      correctOptionIndex: 0,
      categoryId: 'awards-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'award'],
    ),
    QuizQuestion(
      id: 'demo-awards-2',
      text: 'أي إحصائية ترتبط عادةً بجائزة هداف؟',
      options: ['عدد الأهداف', 'عدد المقاعد', 'طول الملعب', 'سعر التذكرة'],
      correctOptionIndex: 0,
      categoryId: 'awards-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'scorer'],
    ),
    QuizQuestion(
      id: 'demo-awards-3',
      text: 'ما الغرض من سجل الجوائز التاريخية؟',
      options: [
        'توثيق الفائزين',
        'قياس الملعب',
        'بيع التذاكر',
        'تحديد وقت التوقف',
      ],
      correctOptionIndex: 0,
      categoryId: 'awards-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'history'],
    ),
    QuizQuestion(
      id: 'demo-eagle-4',
      text: 'أي لاعب يرتدي عادةً قميصًا بلون يميّزه عن بقية زملائه؟',
      options: ['حارس المرمى', 'رأس الحربة', 'قلب الدفاع', 'الجناح'],
      correctOptionIndex: 0,
      categoryId: 'eagle-eye-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'visual'],
    ),
    QuizQuestion(
      id: 'demo-eagle-5',
      text: 'ما العلامة التي تميّز قائد الفريق داخل الملعب غالبًا؟',
      options: ['شارة الذراع', 'قفازان', 'صافرة', 'راية ركنية'],
      correctOptionIndex: 0,
      categoryId: 'eagle-eye-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'visual'],
    ),
    QuizQuestion(
      id: 'demo-eagle-6',
      text: 'أي خط مرسوم يقسم أرضية ملعب كرة القدم إلى نصفين؟',
      options: ['خط المنتصف', 'خط المرمى', 'قوس الركنية', 'منطقة المرمى'],
      correctOptionIndex: 0,
      categoryId: 'eagle-eye-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'pitch'],
    ),
    QuizQuestion(
      id: 'demo-transfer-4',
      text: 'ماذا يسمى انتقال اللاعب مؤقتًا إلى نادٍ آخر؟',
      options: ['إعارة', 'اعتزال', 'تمديد', 'تصعيد'],
      correctOptionIndex: 0,
      categoryId: 'transfers-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'transfers'],
    ),
    QuizQuestion(
      id: 'demo-transfer-5',
      text: 'ماذا يعني وصف اللاعب بأنه حر في سوق الانتقالات؟',
      options: [
        'لا يرتبط بعقد مع نادٍ',
        'لا يملك رقمًا',
        'لا يشارك دوليًا',
        'يلعب بلا وكيل',
      ],
      correctOptionIndex: 0,
      categoryId: 'transfers-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'contract'],
    ),
    QuizQuestion(
      id: 'demo-transfer-6',
      text: 'أي جهة تسجل عقد اللاعب ليصبح مؤهلًا للمشاركة محليًا؟',
      options: [
        'اتحاد اللعبة المختص',
        'إدارة الملعب',
        'شركة البث',
        'رابطة الجمهور',
      ],
      correctOptionIndex: 0,
      categoryId: 'transfers-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'registration'],
    ),
    QuizQuestion(
      id: 'demo-competition-4',
      text: 'كم نقطة يحصل عليها الفريق عادةً عند الفوز في مباراة دوري؟',
      options: ['ثلاث نقاط', 'نقطتان', 'أربع نقاط', 'نقطة واحدة'],
      correctOptionIndex: 0,
      categoryId: 'competitions-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'league'],
    ),
    QuizQuestion(
      id: 'demo-competition-5',
      text: 'ماذا يحدث عادةً للخاسر في مباراة خروج المغلوب؟',
      options: [
        'يودع البطولة',
        'يتصدر المجموعة',
        'يحصل على نقطة',
        'يعيد المباراة دائمًا',
      ],
      correctOptionIndex: 0,
      categoryId: 'competitions-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'knockout'],
    ),
    QuizQuestion(
      id: 'demo-competition-6',
      text: 'في مواجهة من مباراتين، ما الذي يجمع نتيجتي الذهاب والإياب؟',
      options: [
        'النتيجة الإجمالية',
        'نسبة الاستحواذ',
        'عدد الجماهير',
        'ترتيب الدوري',
      ],
      correctOptionIndex: 0,
      categoryId: 'competitions-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'aggregate'],
    ),
    QuizQuestion(
      id: 'demo-locker-4',
      text: 'كم لاعبًا يبدأ المباراة لكل فريق داخل الملعب في كرة القدم؟',
      options: ['11 لاعبًا', '10 لاعبين', '12 لاعبًا', '9 لاعبين'],
      correctOptionIndex: 0,
      categoryId: 'locker-room-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'lineup'],
    ),
    QuizQuestion(
      id: 'demo-locker-5',
      text: 'ماذا يسمى دخول لاعب بدلًا من لاعب آخر أثناء المباراة؟',
      options: ['تبديل', 'تسلل', 'ركنية', 'تمرير بيني'],
      correctOptionIndex: 0,
      categoryId: 'locker-room-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'substitution'],
    ),
    QuizQuestion(
      id: 'demo-locker-6',
      text: 'من يمثل اللاعبين عادةً في الحديث مع الحكم داخل الملعب؟',
      options: ['قائد الفريق', 'مدرب الحراس', 'المصور', 'مسؤول التذاكر'],
      correctOptionIndex: 0,
      categoryId: 'locker-room-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'captain'],
    ),
    QuizQuestion(
      id: 'demo-stadium-4',
      text: 'ما اسم الخط الطويل على جانب أرضية الملعب؟',
      options: ['خط التماس', 'خط المرمى', 'خط الجزاء', 'خط التسلل'],
      correctOptionIndex: 0,
      categoryId: 'stadiums-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'pitch'],
    ),
    QuizQuestion(
      id: 'demo-stadium-5',
      text: 'أين تبدأ المباراة بعد صافرة البداية؟',
      options: ['دائرة المنتصف', 'منطقة الجزاء', 'قوس الركنية', 'منطقة المدرب'],
      correctOptionIndex: 0,
      categoryId: 'stadiums-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'kickoff'],
    ),
    QuizQuestion(
      id: 'demo-stadium-6',
      text: 'كم تبعد علامة الجزاء عن منتصف خط المرمى بحسب قانون اللعبة؟',
      options: ['11 مترًا', '9 أمتار', '12 مترًا', '15 مترًا'],
      correctOptionIndex: 0,
      categoryId: 'stadiums-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'laws'],
    ),
    QuizQuestion(
      id: 'demo-awards-4',
      text: 'ما الجائزة المرتبطة عادةً بأكثر لاعب تسجيلًا للأهداف؟',
      options: [
        'الحذاء الذهبي',
        'القفاز الذهبي',
        'جائزة اللعب النظيف',
        'درع الدوري',
      ],
      correctOptionIndex: 0,
      categoryId: 'awards-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'award'],
    ),
    QuizQuestion(
      id: 'demo-awards-5',
      text: 'أي جائزة ترتبط عادةً بأداء حراس المرمى؟',
      options: [
        'القفاز الذهبي',
        'الحذاء الذهبي',
        'جائزة الهداف',
        'شارة القيادة',
      ],
      correctOptionIndex: 0,
      categoryId: 'awards-demo',
      difficulty: QuestionDifficulty.medium,
      tags: ['demo', 'goalkeeper'],
    ),
    QuizQuestion(
      id: 'demo-awards-6',
      text: 'ما الذي تقيّمه جائزة اللعب النظيف بصورة أساسية؟',
      options: [
        'السلوك والانضباط',
        'سعة الملعب',
        'قيمة الانتقالات',
        'عدد التذاكر',
      ],
      correctOptionIndex: 0,
      categoryId: 'awards-demo',
      difficulty: QuestionDifficulty.hard,
      tags: ['demo', 'fair-play'],
    ),
    QuizQuestion(
      id: 'demo-true-false-visual',
      text: 'يمكن أن يساعد لون القميص وشكله في تمييز النادي.',
      options: ['صح', 'خطأ'],
      correctOptionIndex: 0,
      categoryId: 'eagle-eye-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'true-false'],
      gameType: GameType.trueFalse,
    ),
    QuizQuestion(
      id: 'demo-true-false-transfer',
      text: 'نافذة الانتقالات هي الاسم الآخر لوقت المباراة.',
      options: ['صح', 'خطأ'],
      correctOptionIndex: 1,
      categoryId: 'transfers-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'true-false'],
      gameType: GameType.trueFalse,
    ),
    QuizQuestion(
      id: 'demo-true-false-competition',
      text: 'يتصدر جدول الدوري عادةً الفريق صاحب أكبر عدد من النقاط.',
      options: ['صح', 'خطأ'],
      correctOptionIndex: 0,
      categoryId: 'competitions-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'true-false'],
      gameType: GameType.trueFalse,
    ),
    QuizQuestion(
      id: 'demo-true-false-lineup',
      text: 'التشكيلة الأساسية هي مجموعة اللاعبين الذين يبدأون المباراة.',
      options: ['صح', 'خطأ'],
      correctOptionIndex: 0,
      categoryId: 'locker-room-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'true-false'],
      gameType: GameType.trueFalse,
    ),
    QuizQuestion(
      id: 'demo-true-false-stadium',
      text: 'سعة الملعب تقيس عدد الحضور الذي يمكن استيعابه.',
      options: ['صح', 'خطأ'],
      correctOptionIndex: 0,
      categoryId: 'stadiums-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'true-false'],
      gameType: GameType.trueFalse,
    ),
    QuizQuestion(
      id: 'demo-true-false-awards',
      text: 'ترتبط جائزة الهداف عادةً بعدد البطاقات الصفراء.',
      options: ['صح', 'خطأ'],
      correctOptionIndex: 1,
      categoryId: 'awards-demo',
      difficulty: QuestionDifficulty.easy,
      tags: ['demo', 'true-false'],
      gameType: GameType.trueFalse,
    ),
  ];

  @override
  Future<List<QuestionHistoryEntry>> loadHistory() async {
    final rows = await _database.readQuestionHistory();
    return rows
        .map(
          (row) => QuestionHistoryEntry(
            questionId: row['question_id']! as String,
            seenCount: row['seen_count']! as int,
            correctCount: row['correct_count']! as int,
            lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
              row['last_seen_at']! as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<QuizQuestion>> loadSoloPool() async {
    final cached = await _database.readQuestions();
    final merged = <String, QuizQuestion>{};
    for (final row in cached) {
      final question = QuizQuestion.fromJson(row);
      merged[question.id] = question;
    }
    for (final question in demoQuestions) {
      merged.putIfAbsent(question.id, () => question);
    }
    await _database.replaceQuestions(
      merged.values.map((question) => question.toJson()).toList(),
    );
    return merged.values.toList(growable: false);
  }

  @override
  Future<void> recordAnswer({
    required String questionId,
    required int selectedIndex,
    required bool correct,
  }) {
    return _database.recordQuestionSeen(
      questionId: questionId,
      correct: correct,
      seenAt: DateTime.now(),
    );
  }
}
