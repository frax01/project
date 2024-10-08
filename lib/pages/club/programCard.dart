import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/club/programPage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class ProgramCard extends StatefulWidget {
  const ProgramCard(
      {super.key,
      required this.club,
      required this.documentId,
      required this.selectedOption,
      required this.selectedClass,
      required this.isAdmin,
      required this.refreshList,
      required this.startDate,
      required this.name,
      required this.user,
      required this.role});

  final String club;
  final String documentId;
  final String selectedOption;
  final List selectedClass;
  final bool isAdmin;
  final Function refreshList;
  final DateTime startDate;
  final String name;
  final String user;
  final String role;

  @override
  _ProgramCardState createState() => _ProgramCardState();
}

class _ProgramCardState extends State<ProgramCard> {
  var data = <String, dynamic>{};
  var newData = <String, dynamic>{};

  Future<void> _loadData() async {
    newData = <String, dynamic>{};
    var doc = await FirebaseFirestore.instance
        .collection('club_${widget.selectedOption}')
        .doc(widget.documentId)
        .get();
    newData = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    if (widget.isAdmin) {
      data = newData;
    } else {
      for (String value in newData["selectedClass"]) {
        if (widget.selectedClass.contains(value)) {
          data = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          break;
        }
      }
    }
  }

  _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 175,
                width: double.infinity,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    color: Colors.grey[300],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 20,
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          height: 20,
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  _buildCard() {
    var title = data['title'];
    var level = data['selectedOption'];
    var start = data['startDate'];
    DateTime parsedStartDate = DateFormat("dd-MM-yyyy").parse(start);
    String startDate = DateFormat("dd/MM/yyyy").format(parsedStartDate);
    var endDate = data['endDate'];
    if (endDate != '') {
      DateTime parsedEndDate = DateFormat("dd-MM-yyyy").parse(endDate);
      endDate = DateFormat("dd/MM/yyyy").format(parsedEndDate);
    }
    var imagePath = data['imagePath'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: OpenContainer(
        clipBehavior: Clip.antiAlias,
        closedElevation: 12.0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        closedBuilder: (context, action) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                endDate != ""
                                    ? '$startDate - $endDate'
                                    : startDate,
                                style: const TextStyle(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ])),
                        const SizedBox(width: 10),
                        Text(
                          level == 'weekend' ? 'Programma' : 'Convivenza',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            return SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  color: Colors.grey[300],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        openBuilder: (context, action) {
          return ProgramPage(
            club: widget.club,
            documentId: data['id'],
            selectedOption: data['selectedOption'],
            isAdmin: widget.isAdmin,
            refreshList: widget.refreshList,
            name: widget.user,
            role: widget.role,
            classes: widget.selectedClass,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.done) {
          if (data.isNotEmpty) {
            child = _buildCard();
          } else {
            return Container();
          }
        } else {
          child = _buildShimmer();
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: child,
        );
      },
    );
  }
}
