import 'package:club/functions/storageFunctions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('attachmentStoragePath', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1790000000000);

    test('two programs uploading the same file name get different paths', () {
      final a = attachmentStoragePath(
          docId: 'prog1', fileName: 'programma.pdf', now: now);
      final b = attachmentStoragePath(
          docId: 'prog2', fileName: 'programma.pdf', now: now);

      expect(a, isNot(b));
    });

    test('same program uploading the same name twice gets different paths', () {
      final a = attachmentStoragePath(
          docId: 'prog1', fileName: 'programma.pdf', now: now);
      final b = attachmentStoragePath(
          docId: 'prog1',
          fileName: 'programma.pdf',
          now: now.add(const Duration(milliseconds: 1)));

      expect(a, isNot(b));
    });

    test('stays directly under uploads/ (single path segment)', () {
      final path = attachmentStoragePath(
          docId: 'prog1', fileName: 'a/b\\c.pdf', now: now);

      expect(path.startsWith('uploads/'), isTrue);
      expect(path.substring('uploads/'.length).contains('/'), isFalse);
      expect(path.endsWith('c.pdf'), isTrue);
    });

    test('keeps the original file name (and extension) readable', () {
      final path = attachmentStoragePath(
          docId: 'prog1', fileName: 'Programma Gita.pdf', now: now);

      expect(path.endsWith('Programma Gita.pdf'), isTrue);
    });
  });
}
