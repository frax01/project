import 'package:cloud_firestore/cloud_firestore.dart';

Future<QueryDocumentSnapshot> data(String collection, String filter, String? field) async {
  CollectionReference reference = FirebaseFirestore.instance.collection(collection);
  QuerySnapshot querySnapshot = await reference.where(filter, isEqualTo: field).get();
  return querySnapshot.docs.first;
}