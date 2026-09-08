import 'dart:io';

import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Party exposes exactly the five approved helper identifiers', () {
    expect(PartyHelperId.values.map((value) => value.name).toSet(), {
      'twoChances',
      'callFriend',
      'risk',
      'bench',
      'pass',
    });
    expect(
      defaultPartyHelperDefinitions.map((value) => value.id).toSet(),
      PartyHelperId.values.toSet(),
    );
  });

  test('call_friend has no phone, contacts, or tel URI platform behavior', () {
    final roots = ['lib', 'android', 'ios'];
    const textExtensions = {
      '.dart',
      '.yaml',
      '.xml',
      '.gradle',
      '.properties',
      '.plist',
      '.pbxproj',
      '.kt',
      '.java',
      '.swift',
    };
    final files = <File>[
      File('pubspec.yaml'),
      for (final root in roots)
        ...Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (file) =>
                  !file.path.contains(
                    '${Platform.pathSeparator}.gradle${Platform.pathSeparator}',
                  ) &&
                  textExtensions.any(file.path.endsWith),
            ),
    ];
    final source = files.map((file) => file.readAsStringSync()).join('\n');
    expect(source, isNot(contains('tel:')));
    expect(
      source,
      isNot(matches(RegExp(r'READ_CONTACTS|WRITE_CONTACTS|CALL_PHONE'))),
    );
    expect(source.toLowerCase(), isNot(contains('flutter_contacts')));
    expect(source.toLowerCase(), isNot(contains('permission.contacts')));
  });
}
