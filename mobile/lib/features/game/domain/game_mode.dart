enum GameType { classic, trueFalse, speed, ordering, clubGuess, eagleEye }

enum GameFormat { localParty, practice, teamChallenge, dailyChallenge }

extension GameTypeCopy on GameType {
  String get slug => switch (this) {
    GameType.classic => 'classic',
    GameType.trueFalse => 'true-false',
    GameType.speed => 'speed',
    GameType.ordering => 'ordering',
    GameType.clubGuess => 'club-guess',
    GameType.eagleEye => 'eagle-eye',
  };

  String get titleAr => switch (this) {
    GameType.classic => 'كلاسيك',
    GameType.trueFalse => 'صح أو خطأ',
    GameType.speed => 'السرعة',
    GameType.ordering => 'رتّبهم',
    GameType.clubGuess => 'من النادي؟',
    GameType.eagleEye => 'عين الصقر',
  };

  String get descriptionAr => switch (this) {
    GameType.classic => 'أربع خيارات.. وقرار واحد يحسمها',
    GameType.trueFalse => 'سؤال خاطف واختيار واضح',
    GameType.speed => 'جاوب أكثر قبل ما يخلص الوقت',
    GameType.ordering => 'رتّب الأحداث أو اللاعبين صح',
    GameType.clubGuess => 'اكشف النادي من تلميحاته',
    GameType.eagleEye => 'لاحظ التفاصيل قبل الكل',
  };

  bool get isEnabled =>
      this == GameType.classic ||
      this == GameType.trueFalse ||
      this == GameType.speed;

  static GameType? fromSlug(String value) {
    for (final type in GameType.values) {
      if (type.slug == value) return type;
    }
    return null;
  }
}

extension GameFormatCopy on GameFormat {
  String get titleAr => switch (this) {
    GameFormat.localParty => 'لعبة جماعية',
    GameFormat.practice => 'تدريب فردي',
    GameFormat.teamChallenge => 'تحدي الفريق',
    GameFormat.dailyChallenge => 'تحدي اليوم',
  };

  String get descriptionAr => switch (this) {
    GameFormat.localParty => 'فريقان حول جهاز واحد • 6 فئات • 36 سؤالًا',
    GameFormat.practice => 'غير مصنّف وبدون مكافآت',
    GameFormat.teamChallenge => 'نقاط أسبوعية للفريق',
    GameFormat.dailyChallenge => 'جولة يومية محدودة',
  };
}
