import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void deleteOldDocuments() async {
  // Errors are caught: this runs without await at every app start, also for
  // logged-out users, and a failure used to surface as an unhandled exception.
  try {
    final firestore = FirebaseFirestore.instance;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    final dateFieldByCollection = {
      'club_weekend': 'startDate',
      'club_trip': 'endDate',
    };
    for (final entry in dateFieldByCollection.entries) {
      final querySnapshot = await firestore.collection(entry.key).get();
      for (final document in querySnapshot.docs) {
        final dateString = document.data()[entry.value] as String?;
        if (dateString == null || dateString.isEmpty) continue;
        final date = DateTime.tryParse(dateString.split('-').reversed.join('-'));
        if (date != null && date.isBefore(yesterday)) {
          await document.reference.delete();
        }
      }
    }
  } catch (e) {
    print('Errore durante la pulizia dei documenti scaduti: $e');
  }
}

/// Deletes a program/trip document and then its files in Storage: the cover
/// image and the attachments of [files] (each `{path: <download url>}`).
/// Storage failures (file already gone, URL from another bucket) are ignored,
/// they must not report the deletion as failed.
Future<void> deleteDocument(String collection, String docId, String image,
    {List<dynamic> files = const []}) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  await firestore.collection(collection).doc(docId).delete();

  final List<String> urls = [
    image,
    for (final file in files)
      if (file is Map && file['path'] is String) file['path'] as String,
  ];
  for (final String url in urls) {
    if (url.isEmpty) continue;
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (e) {
      print('File non eliminato da Storage: $e');
    }
  }
}

String convertDateFormat(String date) {
  List<String> parts = date.split('-');
  return '${parts[0]}/${parts[1]}/${parts[2]}';
}
  