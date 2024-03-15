import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> loadData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('email') ?? '';
}

Future<List<Map<String, dynamic>>> fetchData(
    List<Map<String, dynamic>> allDocuments, String selectedClass) async {
  List<String> clubCollections = ['club_weekend', 'club_trip', 'club_extra'];

  for (String collectionName in clubCollections) {
    CollectionReference collection =
        FirebaseFirestore.instance.collection(collectionName);

    QuerySnapshot querySnapshot =
        await collection.where('selectedClass', isEqualTo: selectedClass).get();

    if (querySnapshot.docs.isNotEmpty) {
      List<Map<String, dynamic>> documents = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      allDocuments.addAll(documents);
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
