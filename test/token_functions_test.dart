import 'package:club/functions/tokenFunctions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('upsertDeviceToken', () {
    test('adds the device to an empty list', () {
      expect(upsertDeviceToken([], 'iPhone-ab12cd', 'tok'), [
        {'iPhone-ab12cd': 'tok'}
      ]);
    });

    test('keeps tokens of the user other devices', () {
      final result = upsertDeviceToken([
        {'iPad-0f0f0f': 'tok-ipad'}
      ], 'iPhone-ab12cd', 'tok-iphone');
      expect(result, [
        {'iPad-0f0f0f': 'tok-ipad'},
        {'iPhone-ab12cd': 'tok-iphone'},
      ]);
    });

    test('replaces the old token of the same device', () {
      final result = upsertDeviceToken([
        {'iPhone-ab12cd': 'old'}
      ], 'iPhone-ab12cd', 'new');
      expect(result, [
        {'iPhone-ab12cd': 'new'}
      ]);
    });

    test('drops the same token stored under an older key or as a string', () {
      final result = upsertDeviceToken([
        'tok',
        {'iPhone': 'tok'},
        {'iPad-0f0f0f': 'other'},
      ], 'iPhone-ab12cd', 'tok');
      expect(result, [
        {'iPad-0f0f0f': 'other'},
        {'iPhone-ab12cd': 'tok'},
      ]);
    });

    test('a null token leaves the list unchanged', () {
      final original = [
        {'iPad-0f0f0f': 'other'}
      ];
      expect(upsertDeviceToken(original, 'iPhone-ab12cd', null), original);
    });
  });

  group('removeDeviceToken', () {
    test('removes string and map entries holding the token', () {
      final result = removeDeviceToken([
        'tok',
        {'iPhone': 'tok'},
        {'iPad': 'other'},
      ], 'tok');
      expect(result, [
        {'iPad': 'other'}
      ]);
    });

    test('a null token leaves the list unchanged', () {
      expect(removeDeviceToken([
        {'iPad': 'other'}
      ], null), [
        {'iPad': 'other'}
      ]);
    });
  });
}
