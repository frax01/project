import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/club/programCard.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.club,
    required this.selectedClass,
    required this.section,
    required this.isAdmin,
    required this.name,
    required this.role,
  });

  final String club;
  final List selectedClass;
  final String section;
  final bool isAdmin;
  final String name;
  final String role;

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
    refreshList();
    var db = FirebaseFirestore.instance;
    for (final collection in ['club_weekend', 'club_trip']) {
      if (widget.isAdmin && selectedOptions[0] == 'Tutti i programmi') {
        await db
            .collection(collection)
            .where('club', isEqualTo: widget.club)
            .get()
            .then((docs) {
          for (var doc in docs.docs) {
            List<String> parts = doc["startDate"].split('-');
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            DateTime dateTime = DateTime(year, month, day);
            _listItems.add(ProgramCard(
                club: widget.club,
                documentId: doc.id,
                selectedOption: collection.split('_')[1],
                selectedClass: widget.selectedClass,
                isAdmin: widget.isAdmin,
                refreshList: refreshList,
                startDate: dateTime,
                name: doc['creator'],
                user: widget.name,
                role: widget.role));
            _listKey.currentState?.insertItem(_listItems.length - 1);
          }
        });
      } else {
        await db
            .collection(collection)
            .where('selectedClass', arrayContainsAny: widget.selectedClass)
            .where('club', isEqualTo: widget.club)
            .get()
            .then((docs) {
          for (var doc in docs.docs) {
            List<String> parts = doc["startDate"].split('-');
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            DateTime dateTime = DateTime(year, month, day);
            _listItems.add(ProgramCard(
                club: widget.club,
                documentId: doc.id,
                selectedOption: collection.split('_')[1],
                selectedClass: widget.selectedClass,
                isAdmin: widget.isAdmin,
                refreshList: refreshList,
                startDate: dateTime,
                name: doc['creator'],
                user: widget.name,
                role: widget.role));
            _listKey.currentState?.insertItem(_listItems.length - 1);
          }
        });
      }
    }
    _listItems.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  _buildList(String section) {
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
            child = const Center(
              child: Text(
                'Nessun programma disponibile',
                style: TextStyle(fontSize: 20.0, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
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

  @override
  void initState() {
    super.initState();
  }

  final List<String> options = [
    'Le tue classi',
    'Tutti i programmi',
  ];
  List<String> selectedOptions = ['Le tue classi'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          refreshList();
          return Future.value();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
          child: widget.isAdmin
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
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
                        }).toList()),
                    Expanded(
                      child: _buildList(selectedOptions[0]),
                    ),
                  ],
                )
              : _buildList('Le tue classi'),
        ),
      ),
    );
  }
}
