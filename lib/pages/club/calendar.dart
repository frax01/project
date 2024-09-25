import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:club/pages/club/programCard.dart';
import 'package:club/pages/club/addEditProgram.dart';
import 'package:club/pages/club/eventPage.dart';
import 'package:club/pages/club/programPage.dart';

class Calendar extends StatefulWidget {
  const Calendar(
      {super.key,
      required this.isAdmin,
      required this.club,
      required this.name,
      required this.email,
      required this.selectedClass,
      required this.role});

  final bool isAdmin;
  final String club;
  final String name;
  final String email;
  final List selectedClass;
  final String role;

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;

  bool today = true;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  String evento = '';
  List<dynamic> _selectedDayEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  final Map<String, Color> _convivenzaColors = {};
  final List<Color> _colors = [
    const Color(0xFFBB1614),
    const Color(0xFF00296B),
    Colors.green
  ];

  Color _getConvivenzaColor(String id) {
    if (!_convivenzaColors.containsKey(id)) {
      _convivenzaColors[id] =
          _colors[_convivenzaColors.length % _colors.length];
    }
    return _convivenzaColors[id]!;
  }

  final Map<String, int> _convivenzaRows = {};

  int _getConvivenzaRow(String id) {
    if (!_convivenzaRows.containsKey(id)) {
      _convivenzaRows[id] = _convivenzaRows.length;
    }
    return _convivenzaRows[id]!;
  }

  Map<String, bool> _selectedTutors = {};

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    //tutor
    final querySnapshotTutor = await FirebaseFirestore.instance
        .collection('user')
        .where('club', isEqualTo: widget.club)
        .where('role', isEqualTo: 'Tutor')
        .get();

    for (var doc in querySnapshotTutor.docs) {
      var data = doc.data();
      _selectedTutors[data['email']] = true;
    }

    //calendario
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
      events[dateOnly]!.add({
        'id': doc.id,
        'titolo': event,
        'tipo': 'evento',
        'utenti': data['utenti']
      });
      eventIds[dateOnly]!.add(doc.id);
    }

    // compleanno
    final querySnapshotBirthday = await FirebaseFirestore.instance
        .collection('user')
        .where('club', isEqualTo: widget.club)
        .where('role', whereIn: ['Ragazzo', 'Tutor']).get();

    for (var doc in querySnapshotBirthday.docs) {
      final data = doc.data();

      final dateString = data['birthdate'];
      final date = DateFormat('dd-MM-yyyy').parse(dateString);
      Timestamp timestamp = Timestamp.fromDate(date);
      final resultDate = timestamp.toDate();

      final name = data['name'] + ' ' + data['surname'] as String;

      final DateTime firstDay = DateTime.utc(2020, 1, 1);
      final DateTime lastDay = DateTime.utc(2030, 12, 31);

      for (int year = firstDay.year; year <= lastDay.year; year++) {
        DateTime dateOnlyThisYear =
            DateTime(year, resultDate.month, resultDate.day);

        if (events[dateOnlyThisYear] == null) {
          events[dateOnlyThisYear] = [];
          eventIds[dateOnlyThisYear] = [];
        }
        events[dateOnlyThisYear]!
            .add({'id': doc.id, 'titolo': name, 'tipo': 'compleanno'});
        eventIds[dateOnlyThisYear]!.add(doc.id);
      }
    }

    //programma
    final querySnapshotProgram = await FirebaseFirestore.instance
        .collection('club_weekend')
        .where('club', isEqualTo: widget.club)
        .get();

    for (var doc in querySnapshotProgram.docs) {
      final data = doc.data();

      final dateString = data['startDate'];
      final date = DateFormat('dd-MM-yyyy').parse(dateString);
      Timestamp timestamp = Timestamp.fromDate(date);
      final resultDate = timestamp.toDate();

      final dateOnly =
          DateTime(resultDate.year, resultDate.month, resultDate.day);

      if (events[dateOnly] == null) {
        events[dateOnly] = [];
        eventIds[dateOnly] = [];
      }
      events[dateOnly]!.add({
        'id': doc.id,
        'titolo': data['title'],
        'tipo': 'programma',
        'classi': data['selectedClass']
      });
      eventIds[dateOnly]!.add(doc.id);
    }

    //convivenza
    final querySnapshotTrip = await FirebaseFirestore.instance
        .collection('club_trip')
        .where('club', isEqualTo: widget.club)
        .get();

    for (var doc in querySnapshotTrip.docs) {
      final data = doc.data();

      final startDateString = data['startDate'];
      final startDate = DateFormat('dd-MM-yyyy').parse(startDateString);
      Timestamp startTimestamp = Timestamp.fromDate(startDate);
      final startResultDate = startTimestamp.toDate();
      final startDateOnly = DateTime(
          startResultDate.year, startResultDate.month, startResultDate.day);

      final endDateString = data['endDate'];
      final endDate = DateFormat('dd-MM-yyyy').parse(endDateString);
      Timestamp endTimestamp = Timestamp.fromDate(endDate);
      final endResultDate = endTimestamp.toDate();
      final endDateOnly =
          DateTime(endResultDate.year, endResultDate.month, endResultDate.day);

      List<DateTime> dateList = [];

      DateTime currentDate = startDateOnly;
      while (currentDate.isBefore(endDateOnly) ||
          currentDate.isAtSameMomentAs(endDateOnly)) {
        dateList.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      for (DateTime startDateOnly in dateList) {
        if (events[startDateOnly] == null) {
          events[startDateOnly] = [];
          eventIds[startDateOnly] = [];
        }
        events[startDateOnly]!.add({
          'id': doc.id,
          'titolo': data['title'],
          'tipo': 'convivenza',
          'classi': data['selectedClass']
        });
        eventIds[startDateOnly]!.add(doc.id);
      }
    }

    setState(() {
      final selectedDayOnly =
          DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      _events = events;
      _selectedDayEvents = _events[selectedDayOnly] ?? [];
      _isLoading = false;
    });
  }

  final _listItems = <ProgramCard>[];
  refreshList() {
    setState(() {
      _listItems.clear();
    });
  }

  final List<String> options = [
    'Le tue classi',
    'Tutti i programmi',
  ];
  List<String> selectedOptions = ['Le tue classi'];

  @override
  Widget build(BuildContext context) {
    List validEvents = _selectedDayEvents.where((event) {
      if ((event['tipo'] == 'evento' &&
              !event['utenti'].contains(widget.email) &&
              !widget.isAdmin) ||
          (event['tipo'] == 'programma' &&
              !widget.selectedClass.any(
                  (selectedClass) => event['classi'].contains(selectedClass))
              //&& !widget.isAdmin
              &&
              selectedOptions[0] != 'Tutti i programmi') ||
          (event['tipo'] == 'convivenza' &&
              !widget.selectedClass.any(
                  (selectedClass) => event['classi'].contains(selectedClass))
              //&& !widget.isAdmin
              &&
              selectedOptions[0] != 'Tutti i programmi')) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.isAdmin
                  ? Wrap(
                      spacing: 10,
                      children: options.map((e) {
                        return ChoiceChip(
                          label: Text(e),
                          selected: selectedOptions.contains(e),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedOptions.clear();
                                selectedOptions.add(e);
                                refreshList();
                              }
                            });
                          },
                        );
                      }).toList())
                  : Container(),
              TableCalendar(
                locale: 'it_IT',
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) async {
                  setState(() {
                    _selectedDay = selectedDay;
                    today = isSameDay(selectedDay, DateTime.now());
                    _focusedDay = focusedDay;
                    final selectedDayOnly = DateTime(_selectedDay.year,
                        _selectedDay.month, _selectedDay.day);
                    _selectedDayEvents = _events[selectedDayOnly] ?? [];
                  });
                },
                onFormatChanged: (format) {},
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mese',
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
                        color: today == true
                            ? Theme.of(context).primaryColor
                            : null,
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
                    final bool isPastDate = dateOnly.isBefore(
                        DateTime.now().subtract(const Duration(days: 1)));

                    int eventCount = 0;
                    for (var elem in _events[dateOnly] ?? []) {
                      if (elem['tipo'] == 'evento' && widget.isAdmin) {
                        eventCount++;
                      } else if (elem['tipo'] == 'evento' &&
                          elem['utenti'].contains(widget.email)) {
                        eventCount++;
                      }
                    }

                    final birthdayCount = _events[dateOnly]
                            ?.where((e) => e['tipo'] == 'compleanno')
                            .length ??
                        0;

                    int programCount = 0;
                    for (var elem in _events[dateOnly] ?? []) {
                      if (elem['tipo'] == 'programma' &&
                          widget.isAdmin &&
                          selectedOptions[0] == 'Tutti i programmi') {
                        programCount++;
                      } else if (elem['tipo'] == 'programma') {
                        for (String value in elem['classi']) {
                          if (widget.selectedClass.contains(value)) {
                            programCount++;
                            break;
                          }
                        }
                      }
                    }

                    final tripEvents = [];
                    for (var elem in _events[dateOnly] ?? []) {
                      if (elem['tipo'] == 'convivenza' &&
                          widget.isAdmin &&
                          selectedOptions[0] == 'Tutti i programmi') {
                        tripEvents.add(elem);
                      } else if (elem['tipo'] == 'convivenza') {
                        for (String value in elem['classi']) {
                          if (widget.selectedClass.contains(value) &&
                              !tripEvents.contains(elem)) {
                            tripEvents.add(elem);
                            break;
                          }
                        }
                      }
                    }

                    final total = eventCount + programCount;

                    final Color markerColor = isPastDate
                        ? Colors.grey
                        : Theme.of(context).primaryColor;

                    return Stack(
                      children: [
                        if (total > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$total',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ),
                        if (birthdayCount > 0)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            top: 1,
                            child: Image.asset(
                              'images/birthday_cake.png',
                              width: 17,
                              height: 17,
                            ),
                          ),
                        for (var tripEvent in tripEvents)
                          Container(
                            padding: EdgeInsets.only(
                              bottom: 8.0 * _getConvivenzaRow(tripEvent['id']),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: MediaQuery.of(context).size.width / 9,
                                height: 5,
                                color: _getConvivenzaColor(tripEvent['id']),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              validEvents.isNotEmpty
                  ? const Center(
                      child:
                          Text("In programma", style: TextStyle(fontSize: 22)))
                  : Container(),
              const SizedBox(height: 10),
              Expanded(
                  child: Stack(children: [
                if (!_isLoading)
                  //child:
                  validEvents.isNotEmpty
                      ? ListView.separated(
                          itemCount: validEvents.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1.0),
                          itemBuilder: (context, index) {
                            Map event = validEvents[index];
                            return ListTile(
                              leading: event['tipo'] == 'compleanno'
                                  ? Image.asset(
                                      'images/birthday_cake.png',
                                      width: 24,
                                      height: 24,
                                    )
                                  : event['tipo'] == 'evento'
                                      ? const Icon(Icons.check_circle_outline)
                                      : event['tipo'] == 'convivenza'
                                          ? Column(
                                              children: [
                                                const SizedBox(height: 10),
                                                const Icon(
                                                    Icons.airplanemode_active),
                                                const SizedBox(height: 4),
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      20,
                                                  height: 5.0,
                                                  color: _getConvivenzaColor(
                                                      event['id']),
                                                ),
                                              ],
                                            )
                                          : const Icon(Icons.event),
                              title: AutoSizeText(
                                event['titolo'],
                                style: const TextStyle(fontSize: 18.0),
                                maxLines: 3,
                                minFontSize: 15,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                event['tipo'],
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                              trailing: event['tipo'] != 'compleanno'
                                  ? const Icon(Icons.arrow_forward_ios,
                                      size: 20)
                                  : null,
                              onTap: event['tipo'] == 'evento'
                                  ? () async {
                                      await Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) => EventPage(
                                                  club: widget.club,
                                                  documentId: event['id'],
                                                  isAdmin: widget.isAdmin,
                                                  name: widget.name,
                                                  focusedDay: _focusedDay,
                                                  role: widget.role)));
                                      await _loadEvents();
                                    }
                                  : event['tipo'] == 'programma'
                                      ? () async {
                                          await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProgramPage(
                                                          club: widget.club,
                                                          documentId:
                                                              event['id'],
                                                          selectedOption:
                                                              'weekend',
                                                          isAdmin:
                                                              widget.isAdmin,
                                                          refreshList:
                                                              refreshList,
                                                          name: widget.name,
                                                          role: widget.role)));
                                          await _loadEvents();
                                        }
                                      : event['tipo'] == 'convivenza'
                                          ? () async {
                                              await Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          ProgramPage(
                                                              club: widget.club,
                                                              documentId:
                                                                  event['id'],
                                                              selectedOption:
                                                                  'trip',
                                                              isAdmin: widget
                                                                  .isAdmin,
                                                              refreshList:
                                                                  refreshList,
                                                              name: widget
                                                                  .name,
                                                                  role: widget.role)));
                                              await _loadEvents();
                                            }
                                          : null,
                            );
                          },
                        )
                      : const Center(
                          child: Text('Nessun evento in programma',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 17))),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ])),
            ],
          )),
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
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddEditProgram(
                            club: widget.club,
                            refreshList: refreshList,
                            selectedOption: 'weekend',
                            name: widget.name,
                            focusedDay: _focusedDay,
                            role: widget.role)));
                    await _loadEvents();
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.airplanemode_on),
                  label: 'Convivenza',
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddEditProgram(
                            club: widget.club,
                            refreshList: refreshList,
                            selectedOption: 'trip',
                            name: widget.name,
                            focusedDay: _focusedDay,
                            role: widget.role)));
                    await _loadEvents();
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.check_circle_outline),
                  label: 'Evento',
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddEditProgram(
                            club: widget.club,
                            refreshList: refreshList,
                            selectedOption: 'evento',
                            name: widget.name,
                            focusedDay: _focusedDay,
                            visibility: _selectedTutors,
                            role: widget.role)));
                    await _loadEvents();
                  },
                ),
              ],
            )
          : null,
    );
  }
}
