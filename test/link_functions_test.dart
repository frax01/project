import 'package:club/functions/linkFunctions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeUrl', () {
    test('adds https:// when the scheme is missing', () {
      expect(normalizeUrl('www.example.com/doc'), 'https://www.example.com/doc');
      expect(normalizeUrl('drive.google.com/file/d/1'),
          'https://drive.google.com/file/d/1');
      expect(normalizeUrl('www.example.com:8080/x'),
          'https://www.example.com:8080/x');
    });

    test('keeps URLs that already have a scheme', () {
      expect(normalizeUrl('https://example.com/a?b=c'),
          'https://example.com/a?b=c');
      expect(normalizeUrl('http://example.com'), 'http://example.com');
      expect(normalizeUrl('mailto:info@example.com'), 'mailto:info@example.com');
      expect(normalizeUrl('tel:+390212345678'), 'tel:+390212345678');
    });

    test('trims whitespace and rejects empty input', () {
      expect(normalizeUrl('  https://example.com  '), 'https://example.com');
      expect(normalizeUrl('   '), isNull);
      expect(normalizeUrl(''), isNull);
      expect(normalizeUrl(null), isNull);
    });
  });

  group('openLink', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final calls = <Map<Object?, Object?>>[];
    bool Function(Map<Object?, Object?> args) launchResult = (_) => true;

    setUp(() {
      calls.clear();
      launchResult = (_) => true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launch') {
          final args = Map<Object?, Object?>.from(call.arguments as Map);
          calls.add(args);
          return launchResult(args);
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('opens https links in the in-app browser (SFSafariViewController / Custom Tabs)',
        () async {
      final ok = await openLink('https://example.com/file.pdf');

      expect(ok, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single['url'], 'https://example.com/file.pdf');
      expect(calls.single['useSafariVC'], isTrue);
    });

    test('adds https:// to links typed without a scheme', () async {
      final ok = await openLink('www.example.com/programma');

      expect(ok, isTrue);
      expect(calls.single['url'], 'https://www.example.com/programma');
    });

    test('falls back to the external browser when the in-app one fails',
        () async {
      launchResult = (args) => args['useSafariVC'] != true;

      final ok = await openLink('https://example.com');

      expect(ok, isTrue);
      expect(calls, hasLength(2));
      expect(calls.last['useSafariVC'], isFalse);
    });

    test('non-http schemes go straight to the external app', () async {
      final ok = await openLink('mailto:info@example.com');

      expect(ok, isTrue);
      expect(calls.single['useSafariVC'], isFalse);
    });

    test('returns false for empty links without calling the platform',
        () async {
      expect(await openLink(''), isFalse);
      expect(await openLink(null), isFalse);
      expect(calls, isEmpty);
    });

    test('returns false (no throw) when every launch attempt fails', () async {
      launchResult = (_) => false;

      expect(await openLink('https://example.com'), isFalse);
    });
  });
}
