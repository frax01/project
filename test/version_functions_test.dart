import 'package:club/functions/versionFunctions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isVersionOlder', () {
    test('older installed version needs the update dialog', () {
      expect(isVersionOlder('3.0.6', '3.0.7'), isTrue);
      expect(isVersionOlder('2.9.9', '3.0.0'), isTrue);
      expect(isVersionOlder('3.0.9', '3.0.10'), isTrue);
    });

    test('same or newer installed version (TestFlight, review) is not blocked',
        () {
      expect(isVersionOlder('3.0.7', '3.0.7'), isFalse);
      expect(isVersionOlder('3.0.8', '3.0.7'), isFalse);
      expect(isVersionOlder('3.0.10', '3.0.9'), isFalse);
      expect(isVersionOlder('4.0.0', '3.9.9'), isFalse);
    });

    test('missing or malformed values never block the user', () {
      expect(isVersionOlder('3.0.7', ''), isFalse);
      expect(isVersionOlder('3.0.7+307', '3.0.7'), isFalse);
      expect(isVersionOlder('3.0', '3.0.1'), isTrue);
    });
  });
}
