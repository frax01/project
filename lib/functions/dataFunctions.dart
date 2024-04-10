import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> loadData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('email') ?? '';
}

Future<IterableZip> countDocuments() async {
  var collections = ['club_weekend', 'club_trip', 'club_extra'];
  var counts = [];
  var db = FirebaseFirestore.instance;

  for (String collectionName in collections) {
    await db.collection(collectionName).count().get().then((value) {
      counts.add(value.count!);
    });
  }

  return IterableZip([collections, counts]);
}

Future<List<Map<String, dynamic>>> fetchData(
    List<Map<String, dynamic>> allDocuments, List selectedClass) async {
  List<String> clubCollections = ['club_weekend', 'club_trip', 'club_extra'];

  for (String collectionName in clubCollections) {
    CollectionReference collection =
        FirebaseFirestore.instance.collection(collectionName);

    for (String value in selectedClass) {
      QuerySnapshot querySnapshot =
          await collection.where('selectedClass', arrayContains: value).get();

      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          Map<String, dynamic> documentData =
              {'id': doc.id, ...doc.data() as Map<String, dynamic>};

          bool isUniqueId = allDocuments.every((map) => map['id'] != doc.id);

          if (isUniqueId) {
            allDocuments.add(documentData);
          }
        }
      }
    }
  }

  return allDocuments;
}

Future<Map> loadBoxData(String id, String level, String section) async {
  DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
      .collection('${section}_$level')
      .doc(id)
      .get();

  Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;

  return data;
}
