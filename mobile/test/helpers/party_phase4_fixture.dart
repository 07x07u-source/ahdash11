import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';

final phase4Clock = DateTime.utc(2026, 9, 5, 12);

const phase4Teams = [
  PartyTeam(
    name: 'صقور الجزيرة',
    colorValue: 0xFF4B8DE8,
    players: ['سلمان', 'فيصل'],
    selectedHelpers: {
      PartyHelperId.risk,
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
    },
  ),
  PartyTeam(
    name: 'ذئاب المدرج',
    colorValue: 0xFFE84B8A,
    players: ['نواف', 'تركي'],
    selectedHelpers: {
      PartyHelperId.pass,
      PartyHelperId.bench,
      PartyHelperId.callFriend,
    },
  ),
];

final phase4BoardSession = PartyGameSession(
  id: 'phase4-session',
  teams: phase4Teams,
  categories: List.generate(
    6,
    (categoryIndex) => PartyCategorySnapshot(
      id: 'category-$categoryIndex',
      name: const [
        'دوري روشن',
        'دوري الأبطال',
        'المنتخبات',
        'سوق الانتقالات',
        'الأساطير',
        'عين الصقر',
      ][categoryIndex],
      colorValue: const [
        0xFF78A91B,
        0xFFB77A00,
        0xFF4B8DE8,
        0xFFE84B8A,
        0xFF7446A8,
        0xFF14805D,
      ][categoryIndex],
      ownerTeamIndex: categoryIndex < 3 ? 0 : 1,
      questions: List.generate(
        6,
        (questionIndex) => PartyQuestionSnapshot(
          id: 'question-$categoryIndex-$questionIndex',
          categoryId: 'category-$categoryIndex',
          text: questionIndex == 0
              ? 'من اللاعب الذي يظهر في هذه اللقطة التاريخية وهو يرفع كأس السوبر؟'
              : 'من سجل هدف الفوز في نهائي البطولة القارية بعد مباراة امتدت إلى الأشواط الإضافية؟',
          answer: 'اللاعب أحدعش',
          alternativeAnswers: const ['أحدعش'],
          difficulty: questionIndex < 2
              ? QuestionDifficulty.easy
              : questionIndex < 4
              ? QuestionDifficulty.medium
              : QuestionDifficulty.hard,
          pointValue: questionIndex < 2
              ? 100
              : questionIndex < 4
              ? 200
              : 300,
          format: questionIndex == 0
              ? PartyQuestionFormat.image
              : PartyQuestionFormat.openAnswer,
          imageUrl: questionIndex == 0
              ? 'assets/images/backgrounds/v9_2_home_stadium.png'
              : null,
          mechanicConfig: questionIndex == 0
              ? const {
                  'aspect_ratio': 1.7777777778,
                  'focal_x': 0.5,
                  'focal_y': 0.45,
                }
              : const {},
          explanation: 'معلومة موثقة قصيرة تظهر للمضيف بعد كشف الإجابة فقط.',
          used: categoryIndex == 0 && questionIndex == 1,
        ),
      ),
    ),
  ),
  helperDefinitions: defaultPartyHelperDefinitions,
  timerSeconds: 30,
  createdAt: phase4Clock,
  scores: const [700, 500],
  turnTeamIndex: 0,
  answeringTeamIndex: 0,
);

PartyGameSession phase4QuestionSession({bool image = false}) =>
    phase4BoardSession.copyWith(
      activeQuestionId: image ? 'question-0-0' : 'question-0-2',
      questionTimerStartedAt: phase4Clock.subtract(const Duration(seconds: 6)),
      questionTimerDurationSeconds: 30,
    );

PartyGameSession phase4RevealSession() =>
    phase4QuestionSession().copyWith(revealed: true, clearQuestionTimer: true);

PartyGameSession phase4CompletedSession({bool tied = false}) =>
    phase4BoardSession.copyWith(
      categories: phase4BoardSession.categories
          .map(
            (category) => category.copyWith(
              questions: category.questions
                  .map((question) => question.copyWith(used: true))
                  .toList(),
            ),
          )
          .toList(),
      scores: tied ? const [3200, 3200] : const [4700, 4100],
      scoreEvents: List.generate(
        36,
        (index) => PartyScoreEvent(
          questionId: 'question-${index ~/ 6}-${index % 6}',
          teamDeltas: index.isEven ? const [100, 0] : const [0, 100],
          previousTurn: index.isEven ? 0 : 1,
          createdAt: phase4Clock,
        ),
      ),
      completedAt: phase4Clock,
    );
