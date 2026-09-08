final class AnswerEvaluation {
  const AnswerEvaluation({
    required this.correct,
    required this.normalizedInput,
    this.partialCredit = 0,
  });

  final bool correct;
  final String normalizedInput;
  final double partialCredit;
}

final class AnswerEvaluator {
  const AnswerEvaluator();

  AnswerEvaluation text({
    required String input,
    required String answer,
    List<String> alternatives = const [],
  }) {
    final normalizedInput = normalizeArabic(input);
    final accepted = [
      answer,
      ...alternatives,
    ].map(normalizeArabic).where((value) => value.isNotEmpty).toSet();
    return AnswerEvaluation(
      correct: normalizedInput.isNotEmpty && accepted.contains(normalizedInput),
      normalizedInput: normalizedInput,
    );
  }

  AnswerEvaluation numeric({
    required String input,
    required num answer,
    num tolerance = 0,
  }) {
    final normalizedInput = normalizeArabicDigits(input).trim();
    final parsed = num.tryParse(normalizedInput.replaceAll(',', '.'));
    final allowed = tolerance.abs();
    return AnswerEvaluation(
      correct: parsed != null && (parsed - answer).abs() <= allowed,
      normalizedInput: normalizedInput,
    );
  }

  AnswerEvaluation ordering({
    required List<String> submitted,
    required List<String> expected,
    bool allowPartial = false,
  }) {
    if (submitted.length != expected.length || expected.isEmpty) {
      return const AnswerEvaluation(correct: false, normalizedInput: '');
    }
    var matching = 0;
    for (var index = 0; index < expected.length; index++) {
      if (normalizeArabic(submitted[index]) ==
          normalizeArabic(expected[index])) {
        matching++;
      }
    }
    final fraction = matching / expected.length;
    return AnswerEvaluation(
      correct: matching == expected.length,
      normalizedInput: submitted.map(normalizeArabic).join('|'),
      partialCredit: allowPartial ? fraction : (fraction == 1 ? 1 : 0),
    );
  }

  static String normalizeArabic(String value) => normalizeArabicDigits(value)
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ـ', '')
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String normalizeArabicDigits(String value) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    var result = value;
    for (var index = 0; index < 10; index++) {
      result = result
          .replaceAll(arabicIndic[index], '$index')
          .replaceAll(easternArabic[index], '$index');
    }
    return result;
  }
}
