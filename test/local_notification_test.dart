import 'package:club/services/local_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notification payload', () {
    test('round-trips the data needed to open the right screen', () {
      final data = {
        'category': 'new_event',
        'docId': 'abc123',
        'selectedOption': 'trip',
        'role': 'Tutor',
        'notTitle': 'Nuovo programma!',
      };

      final decoded = LocalNotificationService.decodePayload(
          LocalNotificationService.encodePayload(data));

      expect(decoded, data);
    });

    test('a missing or broken payload gives null instead of throwing', () {
      expect(LocalNotificationService.decodePayload(null), isNull);
      expect(LocalNotificationService.decodePayload(''), isNull);
      expect(LocalNotificationService.decodePayload('not json'), isNull);
      expect(LocalNotificationService.decodePayload('[1,2]'), isNull);
    });

    test('an old payload that is only the category is ignored safely', () {
      // Notifications shown by older app versions had payload == category.
      expect(LocalNotificationService.decodePayload('new_event'), isNull);
    });
  });
}
