import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/bookingFunctions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DocumentReference<Map<String, dynamic>> meal;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    meal = firestore.collection('pasti').doc('lunedi');
    await meal.set({
      'prenotazioni': <String>[],
      'assenze': <String>[],
    });
  });

  Future<Map<String, dynamic>> read() async => (await meal.get()).data()!;

  group('setPresence', () {
    test('two people answering from the same stale screen both end up booked',
        () async {
      // Both screens were loaded when the list was still empty. The old code
      // rewrote the whole list from that copy, so the second write erased the
      // first booking.
      await Future.wait([
        setPresence(meal, name: 'Anna Rossi', field: 'prenotazioni', join: true),
        setPresence(meal, name: 'Luca Bianchi', field: 'prenotazioni', join: true),
      ]);

      expect((await read())['prenotazioni'],
          unorderedEquals(['Anna Rossi', 'Luca Bianchi']));
    });

    test('leaving removes only that person', () async {
      await meal.update({
        'prenotazioni': ['Anna Rossi', 'Luca Bianchi']
      });

      await setPresence(meal,
          name: 'Anna Rossi', field: 'prenotazioni', join: false);

      expect((await read())['prenotazioni'], ['Luca Bianchi']);
    });

    test('joining present takes the person out of the absent list', () async {
      await meal.update({
        'assenze': ['Anna Rossi', 'Luca Bianchi']
      });

      await setPresence(meal,
          name: 'Anna Rossi',
          field: 'prenotazioni',
          otherField: 'assenze',
          join: true);

      final data = await read();
      expect(data['prenotazioni'], ['Anna Rossi']);
      expect(data['assenze'], ['Luca Bianchi']);
    });

    test('answering twice does not duplicate the person', () async {
      await setPresence(meal,
          name: 'Anna Rossi', field: 'prenotazioni', join: true);
      await setPresence(meal,
          name: 'Anna Rossi', field: 'prenotazioni', join: true);

      expect((await read())['prenotazioni'], ['Anna Rossi']);
    });
  });

  group('saveFriends', () {
    test("one user's friends do not wipe another user's (regression)",
        () async {
      // The old code rewrote the whole `amici` map from the local copy.
      await saveFriends(meal,
          field: 'amici', userName: 'Anna Rossi', friends: ['Marco']);
      await saveFriends(meal,
          field: 'amici', userName: 'Luca Bianchi', friends: ['Sara', 'Gio']);

      expect((await read())['amici'], {
        'Anna Rossi': ['Marco'],
        'Luca Bianchi': ['Sara', 'Gio'],
      });
    });

    test('creates the map when the document has none', () async {
      expect((await read()).containsKey('amici'), isFalse);

      await saveFriends(meal,
          field: 'amici', userName: 'Anna Rossi', friends: ['Marco']);

      expect((await read())['amici'], {
        'Anna Rossi': ['Marco']
      });
    });

    test('an empty list removes the user entry only', () async {
      await meal.update({
        'amici': {
          'Anna Rossi': ['Marco'],
          'Luca Bianchi': ['Sara'],
        }
      });

      await saveFriends(meal,
          field: 'amici', userName: 'Anna Rossi', friends: []);

      expect((await read())['amici'], {
        'Luca Bianchi': ['Sara']
      });
    });

    test('works for the lunch map of a program too', () async {
      await saveFriends(meal,
          field: 'amiciPranzo', userName: 'Anna Rossi', friends: ['Marco']);

      expect((await read())['amiciPranzo'], {
        'Anna Rossi': ['Marco']
      });
    });
  });
}
