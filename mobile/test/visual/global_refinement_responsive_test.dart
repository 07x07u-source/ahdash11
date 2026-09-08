import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/visual_test_variant.dart';
import 'tournament_golden_test.dart' as tournament;
import 'v10_phase_b_golden_test.dart' as party;
import 'v10_phase_d_golden_test.dart' as discovery;
import 'v10_phase_e_golden_test.dart' as account;

void main() {
  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.2, 1.3]) {
      final variant = VisualTestVariant(size, scale);
      group(variant.label, () {
        group('party', () => party.registerVisualTests(variant: variant));
        group(
          'tournament',
          () => tournament.registerVisualTests(variant: variant),
        );
        group(
          'discovery',
          () => discovery.registerVisualTests(variant: variant),
        );
        group('account', () => account.registerVisualTests(variant: variant));
      });
    }
  }
}
