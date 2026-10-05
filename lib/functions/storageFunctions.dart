/// Storage path for a program/event attachment.
///
/// Attachments used to be stored as `uploads/<file name>`, so two programs
/// with a `programma.pdf` overwrote each other, and deleting one attachment
/// deleted the file of the other. The document id and a timestamp make the
/// path unique; it stays a single segment under `uploads/` so it still matches
/// the existing Storage rules.
String attachmentStoragePath({
  required String docId,
  required String fileName,
  DateTime? now,
}) {
  final int millis = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final String safeName = fileName.replaceAll(RegExp(r'[/\\]'), '_');
  return 'uploads/${docId}_${millis}_$safeName';
}
