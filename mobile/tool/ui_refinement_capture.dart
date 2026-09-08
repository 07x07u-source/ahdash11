import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../test/visual/tournament_golden_test.dart' as tournament;
import '../test/visual/v10_phase_b_golden_test.dart' as party;
import '../test/visual/v10_phase_d_golden_test.dart' as discovery;
import '../test/visual/v10_phase_e_golden_test.dart' as account;

/// Exports actual Flutter pixels and still compares the existing baselines.
/// This diagnostic entry point never updates or replaces Golden files.
void main() {
  final original = LocalFileComparator(
    File('test/visual/review_anchor.dart').absolute.uri,
  );
  setUpAll(() => goldenFileComparator = _ReviewComparator(original));
  group('party review', party.main);
  group('tournament review', tournament.main);
  group('discovery review', discovery.main);
  group('account review', account.main);
}

final class _ReviewComparator extends GoldenFileComparator {
  _ReviewComparator(this.original);
  final GoldenFileComparator original;
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    const output = String.fromEnvironment(
      'UI_REVIEW_DIR',
      defaultValue: '../docs/v10_ui_refinement',
    );
    final path = golden.path;
    final folder = path.contains('v10_phase_b')
        ? 'party'
        : path.contains('v10_phase_c')
        ? 'tournament'
        : 'account';
    final file = File('$output/$folder/${golden.pathSegments.last}');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(imageBytes);
    return original.compare(imageBytes, golden);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      throw UnsupportedError(
        'Visual review does not approve or update Goldens.',
      );
}
