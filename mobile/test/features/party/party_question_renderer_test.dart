import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renderer registry covers every released party format', () {
    expect(
      PartyQuestionRendererRegistry.supportedFormats,
      containsAll(PartyQuestionFormat.values),
    );
  });

  for (final size in const [Size(390, 760), Size(844, 390)]) {
    testWidgets(
      'all party formats render safely at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final format in PartyQuestionFormat.values) {
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ar'),
              theme: AppTheme.light,
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: PartyQuestionRenderer(question: _question(format)),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Format ${format.name} overflowed or threw at $size',
          );
        }
      },
    );
  }
}

PartyQuestionSnapshot _question(PartyQuestionFormat format) =>
    PartyQuestionSnapshot(
      id: 'format-${format.name}',
      categoryId: 'category',
      text: 'ما الإجابة المناسبة لهذا السؤال؟',
      answer: 'الإجابة',
      difficulty: QuestionDifficulty.medium,
      pointValue: 200,
      format: format,
      options: const ['الأول', 'الثاني', 'الثالث', 'الرابع'],
      imageUrl:
          format == PartyQuestionFormat.image ||
              format == PartyQuestionFormat.imageCrop ||
              format == PartyQuestionFormat.imageBlur
          ? 'assets/visuals/eagle-eye-cover.png'
          : null,
      orderingItems: const ['لاعب أ', 'لاعب ب', 'لاعب ج'],
      hints: const ['التلميح الأول', 'التلميح الثاني'],
      pointDecayPerHint: 50,
    );
