import 'package:ahdash_11/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'registered Thmanyah Sans OTF faces are packaged and readable',
    () async {
      const weights = ['Regular', 'Medium', 'Bold', 'Black'];
      for (final weight in weights) {
        final data = await rootBundle.load(
          'assets/fonts/thmanyah/thmanyahsans-$weight.otf',
        );
        expect(data.lengthInBytes, greaterThan(200000));
      }
    },
  );

  test('product type roles use only the Thmanyah family', () {
    expect(AppTypography.displayFamily, 'ThmanyahSans');
    expect(AppTypography.bodyFamily, 'ThmanyahSans');
    expect(AppTypography.editorialDisplayFamily, 'ThmanyahSans');
    expect(AppTypography.editorialTextFamily, 'ThmanyahSans');
    expect(AppTypography.displayXl.letterSpacing, 0);
  });
}
