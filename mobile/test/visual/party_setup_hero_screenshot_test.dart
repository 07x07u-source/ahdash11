import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/visual_test_variant.dart';
import 'v10_phase_b_golden_test.dart' as phase_b;

// Render current widgets for human review without replacing approved goldens.
void main() {
  for (final size in const [Size(390, 844), Size(360, 800)]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      final variant = VisualTestVariant(size, scale);
      group(variant.label, () {
        phase_b.registerVisualTests(
          variant: variant,
          screenPrefixes: const {'08_', '09_', '10_', '11_'},
        );
      });
    }
  }
}
