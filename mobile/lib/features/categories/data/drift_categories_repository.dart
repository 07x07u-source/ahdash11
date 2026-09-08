import 'package:flutter/material.dart';

import '../../../core/storage/app_database.dart';
import '../../../shared/domain/category.dart';
import '../domain/categories_repository.dart';

final class DriftCategoriesRepository implements CategoriesRepository {
  DriftCategoriesRepository(this._database, {this.seedDemo = true});

  final AppDatabase _database;
  final bool seedDemo;

  static const demoCategories = <QuizCategory>[
    QuizCategory(
      id: 'eagle-eye-demo',
      slug: 'eagle-eye-demo',
      name: 'عين الصقر',
      description: 'تعرّف على القميص والشعار واللاعب',
      iconName: 'visibility',
      imageUrl: 'assets/visuals/eagle-eye-cover.png',
      accentColor: Color(0xFFB6FF3B),
      subcategories: ['القمصان', 'الشعارات', 'اللاعبون'],
      groupKey: 'visual',
      seasonLabel: 'تحدٍ بصري',
      questionFormats: ['image', 'image_crop', 'image_blur'],
      featured: true,
      freeRotation: true,
      tags: ['صور', 'قمصان', 'شعارات'],
      regionCodes: ['world'],
      audiences: ['general', 'family'],
      popularityScore: 98,
      recommended: true,
      gameplayInstructions: 'دقق في الصورة ثم سمّ اللاعب أو النادي.',
      mechanicType: 'image',
    ),
    QuizCategory(
      id: 'transfers-demo',
      slug: 'transfers-demo',
      name: 'سوق الانتقالات',
      description: 'مسيرة اللاعب وانتقالاته',
      iconName: 'swap_horiz',
      imageUrl: 'assets/visuals/player_11_stadium_hero.png',
      accentColor: Color(0xFFFFC857),
      subcategories: ['مسيرة لاعب', 'النادي السابق', 'ترتيب المسيرة'],
      groupKey: 'players',
      seasonLabel: 'الميركاتو',
      questionFormats: ['open_answer', 'ordering'],
      isNew: true,
      tags: ['لاعبون', 'انتقالات', 'مسيرة'],
      regionCodes: ['world', 'europe'],
      audiences: ['general', 'experts'],
      popularityScore: 91,
      recommended: true,
      gameplayInstructions: 'اربط اللاعب بمحطات مسيرته بالترتيب.',
      mechanicType: 'ordering',
    ),
    QuizCategory(
      id: 'competitions-demo',
      slug: 'competitions-demo',
      name: 'الدوريات والبطولات',
      description: 'أسئلة تجريبية عامة عن البطولات',
      iconName: 'emoji_events',
      imageUrl: 'assets/visuals/home-hero.png',
      accentColor: Color(0xFF77B8FF),
      subcategories: ['دوري روشن', 'دوري الأبطال', 'كأس العالم'],
      groupKey: 'competitions',
      seasonLabel: 'موسم 2026/27',
      questionFormats: ['open_answer', 'true_false'],
      featured: true,
      tags: ['بطولات', 'دوريات', 'كؤوس'],
      countryCodes: ['SA'],
      regionCodes: ['gcc', 'world'],
      audiences: ['general', 'family'],
      popularityScore: 96,
      recommended: true,
      gameplayInstructions: 'اختبر معلوماتك في البطولات المحلية والعالمية.',
    ),
    QuizCategory(
      id: 'locker-room-demo',
      slug: 'locker-room-demo',
      name: 'غرفة الملابس',
      description: 'مدربون وأرقام وتشكيلات',
      iconName: 'groups',
      imageUrl: 'assets/visuals/results-backdrop.png',
      accentColor: Color(0xFFC89BFF),
      subcategories: ['المدربون', 'أرقام القمصان', 'التشكيلات'],
      groupKey: 'tactics',
      seasonLabel: 'تكتيك',
      questionFormats: ['open_answer', 'ordering', 'drawing'],
      tags: ['مدربون', 'تشكيلات', 'أرقام'],
      regionCodes: ['world'],
      audiences: ['general', 'experts'],
      popularityScore: 84,
      gameplayInstructions: 'فكّر كمدرب واربط المعلومة بالتشكيلة.',
      mechanicType: 'tactics',
    ),
    QuizCategory(
      id: 'stadiums-demo',
      slug: 'stadiums-demo',
      name: 'الملاعب',
      description: 'الموقع والسعة والنادي',
      iconName: 'stadium',
      imageUrl: 'assets/visuals/eagle-eye-cover.png',
      accentColor: Color(0xFF50E3A4),
      subcategories: ['الموقع', 'السعة', 'مباريات تاريخية'],
      groupKey: 'stadiums',
      seasonLabel: 'حول العالم',
      questionFormats: ['image', 'numeric', 'open_answer'],
      tags: ['ملاعب', 'مدن', 'جماهير'],
      regionCodes: ['world', 'arab'],
      audiences: ['general', 'family'],
      popularityScore: 80,
      gameplayInstructions: 'تعرّف على الملعب من صورته أو سعته أو مدينته.',
      mechanicType: 'image',
    ),
    QuizCategory(
      id: 'awards-demo',
      slug: 'awards-demo',
      name: 'الجوائز الفردية',
      description: 'جوائز وهدافون — محتوى تجريبي',
      iconName: 'workspace_premium',
      imageUrl: 'assets/visuals/player_11_stadium_hero.png',
      accentColor: Color(0xFFFF8D75),
      subcategories: ['الكرة الذهبية', 'الحذاء الذهبي', 'الهدافون'],
      groupKey: 'history',
      seasonLabel: 'سجل الأبطال',
      questionFormats: ['open_answer', 'numeric', 'progressive_hints'],
      isNew: true,
      tags: ['جوائز', 'هدافون', 'تاريخ'],
      regionCodes: ['world'],
      audiences: ['general', 'experts'],
      popularityScore: 87,
      gameplayInstructions: 'استرجع أصحاب الجوائز والأرقام القياسية.',
      mechanicType: 'progressive_hints',
    ),
  ];

  @override
  Future<List<QuizCategory>> loadCategories({bool forceRefresh = false}) async {
    final cached = await _database.readCategories();
    if (cached.isNotEmpty) {
      final categories = cached
          .map(QuizCategory.fromJson)
          .where((category) => seedDemo || !category.id.endsWith('-demo'))
          .toList(growable: false);
      if (categories.isNotEmpty || !seedDemo) return categories;
    }
    if (!seedDemo) return const [];
    await _database.replaceCategories(
      demoCategories.map((category) => category.toJson()).toList(),
    );
    return demoCategories;
  }
}
