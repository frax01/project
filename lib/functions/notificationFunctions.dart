import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks the server to send a push notification (Cloud Function
/// `sendClubNotification`). The server checks who is calling and decides who
/// receives it, so the app no longer downloads any FCM credential: it used to
/// get an OAuth token from a public endpoint and call FCM itself.
///
/// [category]:
///  * 'new_event' / 'modified_event': an admin notifies the users of
///    [classes] of their own club; needs [title], [docId] and
///    [selectedOption] ('weekend' | 'trip' | 'evento'), [body] is optional;
///  * 'new_user': a new user notifies the admins of their club (once);
///  * 'accepted': an admin notifies [userEmail] that the account was accepted.
///
/// Errors are logged, not thrown: a failed notification must not fail the
/// action that triggered it.
Future<void> sendClubNotification({
  required String category,
  List<String> classes = const [],
  String? title,
  String? body,
  String? docId,
  String? selectedOption,
  String? userEmail,
}) async {
  try {
    // The profile keeps the email as typed at sign-up; the server also tries it
    // (only if it is the same address as the logged-in account).
    final String? email =
        (await SharedPreferences.getInstance()).getString('email');
    await FirebaseFunctions.instance.httpsCallable('sendClubNotification').call({
      'email': email,
      'category': category,
      'classes': classes,
      'title': title,
      'body': body,
      'docId': docId,
      'selectedOption': selectedOption,
      'userEmail': userEmail,
    });
  } catch (e) {
    print('Errore nell\'invio della notifica: $e');
  }
}
