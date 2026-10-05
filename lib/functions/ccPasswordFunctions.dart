import 'package:cloud_functions/cloud_functions.dart';

enum CcPasswordResult { ok, wrong, locked, error }

/// Checks the Champions Club staff/tutor password on the server (Cloud
/// Function `verifyCcPassword`). The passwords used to be downloaded to every
/// phone from Firestore and compared there. [type] is 'staff' or 'tutor'.
Future<CcPasswordResult> verifyCcPassword({
  required String type,
  required String password,
}) async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('verifyCcPassword')
        .call({'type': type, 'password': password});
    final data = result.data;
    return data is Map && data['ok'] == true
        ? CcPasswordResult.ok
        : CcPasswordResult.wrong;
  } on FirebaseFunctionsException catch (e) {
    return e.code == 'resource-exhausted'
        ? CcPasswordResult.locked
        : CcPasswordResult.error;
  } catch (_) {
    return CcPasswordResult.error;
  }
}

/// Message for a failed check; [wrongMessage] is shown for a wrong password.
String ccPasswordErrorMessage(CcPasswordResult result, String wrongMessage) {
  switch (result) {
    case CcPasswordResult.locked:
      return 'Troppi tentativi, riprova tra qualche minuto';
    case CcPasswordResult.error:
      return 'Verifica non riuscita, controlla la connessione';
    default:
      return wrongMessage;
  }
}
