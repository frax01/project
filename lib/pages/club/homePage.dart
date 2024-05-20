import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/club/addEditProgram.dart';
import 'package:club/pages/club/programCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ms_undraw/ms_undraw.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.selectedClass,
    required this.section,
    required this.isAdmin,
  });

  final List selectedClass;
  final String section;
  final bool isAdmin;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _listItems = <ProgramCard>[];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  refreshList() {
    setState(() {
      _listItems.clear();
    });
  }

  _loadItems() async {
    var db = FirebaseFirestore.instance;
    for (final collection in ['club_weekend', 'club_trip', 'club_extra']) {
      await db.collection(collection).where('selectedClass', arrayContainsAny: widget.selectedClass)
          .get().then((docs) {
        for (var doc in docs.docs) {
          List<String> parts = doc["startDate"].split('-');
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          DateTime dateTime = DateTime(year, month, day);
          _listItems.add(ProgramCard(
            documentId: doc.id,
            selectedOption: collection.split('_')[1],
            selectedClass: widget.selectedClass,
            isAdmin: widget.isAdmin,
            refreshList: refreshList,
            startDate: dateTime,
          ));
          _listKey.currentState?.insertItem(_listItems.length - 1);
        }
      });
    }
    _listItems.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  _buildList() {
    return FutureBuilder(
      future: _loadItems(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          if (_listItems.isEmpty) {
            child = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200.0,
                  child: UnDraw(
                    illustration: UnDrawIllustration.biking,
                    placeholder: const SizedBox(
                      height: 200.0,
                      width: 200.0,
                    ),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Text(
                  'Nessun programma disponibile',
                  style: TextStyle(fontSize: 20.0, color: Colors.black54),
                ),
              ],
            );
          } else {
            child = AnimatedList(
              key: _listKey,
              initialItemCount: _listItems.length,
              itemBuilder: (context, index, animation) {
                try {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: _listItems[index],
                  );
                } catch (e) {
                  return const SizedBox();
                }
              },
            );
          }
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: child,
        );
      },
    );
  }

  _smallLayout() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          refreshList();
          return Future.value();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildList(),
        ),
      ),
      floatingActionButton: widget.isAdmin
          ? SpeedDial(
              icon: Icons.add,
              backgroundColor: Colors.white,
              activeIcon: Icons.close,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.calendar_today),
                  label: 'Sabato',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddEditProgram(
                            refreshList: refreshList,
                            selectedOption: 'weekend')));
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.airplanemode_on),
                  label: 'Viaggio',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddEditProgram(
                            refreshList: refreshList, selectedOption: 'trip')));
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.star),
                  label: 'Extra',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddEditProgram(
                            refreshList: refreshList,
                            selectedOption: 'extra')));
                  },
                ),
              ],
            )
          : null,
    );
  }

  _largeLayout() {
    return Container(
      child: Center(
        child: Text('Large Layout'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      smallLayout: _smallLayout(),
      largeLayout: _largeLayout(),
    );
  }
}
