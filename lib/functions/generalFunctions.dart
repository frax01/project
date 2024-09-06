import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void deleteOldDocuments() async {
  final firestore = FirebaseFirestore.instance;
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  final oneDateCollections = [
    'club_weekend',
  ];
  for (final collection in oneDateCollections) {
    final querySnapshot = await firestore.collection(collection).get();
    for (final document in querySnapshot.docs) {
      final startDateString = document.data()['startDate'] as String;
      final startDate =
          DateTime.parse(startDateString.split('-').reversed.join('-'));
      if (startDate.isBefore(yesterday)) {
        await document.reference.delete();
      }
    }
  }

  final twoDateCollections = [
    'club_trip',
  ];
  for (final collection in twoDateCollections) {
    final querySnapshot = await firestore.collection(collection).get();
    for (final document in querySnapshot.docs) {
      final startDateString = document.data()['endDate'] as String;
      final startDate =
          DateTime.parse(startDateString.split('-').reversed.join('-'));
      if (startDate.isBefore(yesterday)) {
        await document.reference.delete();
      }
    }
  }
}

Future<void> deleteDocument(String collection, String docId, String image) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  await firestore.collection(collection).doc(docId).delete();

  final storageRef = FirebaseStorage.instance.refFromURL(image);
  await storageRef.delete();
}

String convertDateFormat(String date) {
  List<String> parts = date.split('-');
  return '${parts[0]}/${parts[1]}/${parts[2]}';
}
  