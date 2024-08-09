import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:club/pages/club/programCard.dart';
import 'package:club/pages/club/addEditProgram.dart';
import 'package:club/pages/club/eventPage.dart';

class Calendar extends StatefulWidget {
  const Calendar({
    super.key,
    required this.isAdmin,
    required this.club,
    required this.name});

  final bool isAdmin;
  final String club;
  final String name;

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  bool today = true;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  String evento = '';
  List<dynamic> _selectedDayEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final querySnapshotEvent = await FirebaseFirestore.instance
        .collection('calendario')
        .where('club', isEqualTo: widget.club)
        .get();

    final events = <DateTime, List<Map<String, dynamic>>>{};
    final eventIds = <DateTime, List<String>>{};

    for (var doc in querySnapshotEvent.docs) {
      final data = doc.data();
      final date = (data['data'] as Timestamp).toDate();
      final event = data['titolo'] as String;

      final dateOnly = DateTime(date.year, date.month, date.day);

      if (events[dateOnly] == null) {
        events[dateOnly] = [];
        eventIds[dateOnly] = [];
      }
      events[dateOnly]!.add({'id': doc.id, 'titolo': event, 'tipo': 'evento'});
      eventIds[dateOnly]!.add(doc.id);
    }

    final querySnapshotBirthday = await FirebaseFirestore.instance
        .collection('user')
        .where('club', isEqualTo: widget.club)
        .where('role', whereIn: ['Ragazzo', 'Tutor'])
        .get();

    for (var doc in querySnapshotBirthday.docs) {
      final data = doc.data();

      final dateString = data['birthdate'];
      final date = DateFormat('dd-MM-yyyy').parse(dateString);
      Timestamp timestamp = Timestamp.fromDate(date);
      final resultDate = timestamp.toDate();

      final name = data['name'] + ' ' + data['surname'] as String;

      DateTime now = DateTime.now();
      DateTime dateOnlyThisYear = DateTime(now.year, resultDate.month, resultDate.day);
      DateTime dateOnlyNextYear = DateTime(now.year + 1, resultDate.month, resultDate.day);
      DateTime dateOnly = dateOnlyThisYear.isBefore(now) ? dateOnlyNextYear : dateOnlyThisYear;

      if (events[dateOnly] == null) {
        events[dateOnly] = [];
        eventIds[dateOnly] = [];
      }
      events[dateOnly]!.add({'id': doc.id, 'titolo': name, 'tipo': 'compleanno'});
      eventIds[dateOnly]!.add(doc.id);
    }

    setState(() {
      final selectedDayOnly = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
      _events = events;
      _selectedDayEvents = _events[selectedDayOnly] ?? [];
    });
  }

  final _listItems = <ProgramCard>[];
  refreshList() {
    setState(() {
      _listItems.clear();
    });
  }

  Future<void> _deleteEvent(String eventId) async {
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Conferma'),
            content: const Text('Sei sicuro di voler eliminare questo evento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Si'),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        try {
          await FirebaseFirestore.instance
              .collection('calendario')
              .doc(eventId)
              .delete();

          await _loadEvents();
        } catch (e) {
          print('Errore durante l\'eliminazione: $e');
        }
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
        child: Column(
          children: [
            TableCalendar(
              locale: 'it_IT',
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  today = isSameDay(selectedDay, DateTime.now());
                  _focusedDay = focusedDay;
                  final selectedDayOnly = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
                  _selectedDayEvents = _events[selectedDayOnly] ?? [];
                });
              },
              calendarBuilders: CalendarBuilders(
                todayBuilder: (context, date, _) {
                  return Container(
                    margin: const EdgeInsets.all(10.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2.0,
                      ),
                      color: today == true ? Theme.of(context).primaryColor : null,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: today == true ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, date, _) {
                  return Container(
                    margin: const EdgeInsets.all(10.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                markerBuilder: (context, date, events) {
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  final eventCount = _events[dateOnly]?.where((e) => e['tipo'] == 'evento').length ?? 0;
                  final birthdayCount = _events[dateOnly]?.where((e) => e['tipo'] == 'compleanno').length ?? 0;

                  return Stack(
                    children: [
                      if (eventCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                            decoration: const BoxDecoration(
                              color: Colors.grey, // Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$eventCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ),
                      if (birthdayCount > 0)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.cake,
                            color: Colors.black,
                            size: 15.0,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            const Center(child: Text("In programma", style: TextStyle(fontSize: 22))),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedDayEvents.isNotEmpty ? ListView.separated(
                itemCount: _selectedDayEvents.length,
                separatorBuilder: (context, index) => const Divider(height: 1.0),
                itemBuilder: (context, index) {
                  Map event = _selectedDayEvents[index];
                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: AutoSizeText(
                      event['titolo'],
                      style: const TextStyle(fontSize: 18.0),
                      maxLines: 3,
                      minFontSize: 15,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text("evento", style: TextStyle(fontSize: 12, color: Colors.grey[700]),),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    //trailing: widget.isAdmin ? IconButton(
                    //  icon: const Icon(Icons.delete),
                    //  onPressed: () => _deleteEvent(event['id']),
                    //) : null,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => EventPage(
                              club: widget.club,
                              documentId: event['id'],
                              selectedOption: 'evento',
                              isAdmin: widget.isAdmin,
                              refreshList: refreshList,
                              name: widget.name)));
                    },
                  );
                  },
              ) : const Center(child: Text('Nessun evento'))
            ),
          ],
        ),),
        floatingActionButton: widget.isAdmin
            ? SpeedDial(
          icon: Icons.add,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          activeIcon: Icons.close,
          overlayOpacity: 1,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.event),
              label: 'Programma',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddEditProgram(
                        club: widget.club,
                        refreshList: refreshList,
                        selectedOption: 'weekend',
                        name: widget.name)));
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.airplanemode_on),
              label: 'Convivenza',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddEditProgram(
                        club: widget.club,
                        refreshList: refreshList,
                        selectedOption: 'trip',
                        name: widget.name)));
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.cake),
              label: 'Compleanno',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddEditProgram(
                        club: widget.club,
                        refreshList: refreshList,
                        selectedOption: 'trip',
                        name: widget.name)));
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.check_circle_outline),
              label: 'Evento',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddEditProgram(
                        club: widget.club,
                        refreshList: refreshList,
                        selectedOption: 'evento',
                        name: widget.name,
                        focusedDay: _focusedDay,)));
              },
            ),
          ],
        ) : null,
    );
  }
}