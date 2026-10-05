import 'package:cloud_firestore/cloud_firestore.dart';

/// Puts [name] in (or takes it out of) the [field] array of [doc] with
/// arrayUnion/arrayRemove, which change only that person's entry on the
/// server. With [join] the person is also removed from [otherField]
/// (present <-> absent).
///
/// The whole arrays used to be rewritten from the local copy of the screen,
/// so two people answering at the same time overwrote each other.
Future<void> setPresence(
  DocumentReference<Map<String, dynamic>> doc, {
  required String name,
  required String field,
  String? otherField,
  required bool join,
}) {
  return doc.update(join
      ? {
          field: FieldValue.arrayUnion([name]),
          if (otherField != null) otherField: FieldValue.arrayRemove([name]),
        }
      : {field: FieldValue.arrayRemove([name])});
}

/// Writes the friends of [userName] in the [field] map ('amici' or
/// 'amiciPranzo') of [doc], touching only that user's entry. A FieldPath is
/// used so that names containing dots are not split into nested fields. An
/// empty list removes the entry.
///
/// The whole map used to be rewritten from the local copy, which wiped the
/// friends added meanwhile by everybody else.
Future<void> saveFriends(
  DocumentReference<Map<String, dynamic>> doc, {
  required String field,
  required String userName,
  required List<String> friends,
}) {
  return doc.update({
    FieldPath([field, userName]):
        friends.isEmpty ? FieldValue.delete() : friends,
  });
}
