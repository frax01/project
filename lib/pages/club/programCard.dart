import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/club/programPage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProgramCard extends StatefulWidget {
  const ProgramCard(
      {super.key,
      required this.query,
      required this.isAdmin,
      required this.refreshList});

  final Query query;
  final bool isAdmin;
  final Function refreshList;

  @override
  _ProgramCardState createState() => _ProgramCardState();
}

class _ProgramCardState extends State<ProgramCard> {
  var _data = <String, dynamic>{};

  Future<void> _loadData() async {
    var snapshot = await widget.query.get();
    var doc = snapshot.docs.first;
    _data = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
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
    var title = _data['title'];
    var level = _data['selectedOption'];
    var startDate = _data['startDate'];
    var endDate = _data['endDate'];
    var imagePath = _data['imagePath'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: OpenContainer(
        clipBehavior: Clip.antiAlias,
        closedElevation: 5.0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        closedBuilder: (context, action) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 175,
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
                              height: 175,
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
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 7.0,
                            ),
                          ],
                        ),
                        child: endDate != ""
                            ? Text('$startDate ～ $endDate',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))
                            : Text('$startDate',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20.0)),
                        Text(
                          level == 'weekend'
                              ? 'Sabato'
                              : level == 'extra'
                                  ? 'Extra'
                                  : level == 'trip'
                                      ? 'Viaggio'
                                      : 'Torneo',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        openBuilder: (context, action) {
          return ProgramPage(
              documentId: _data['id'],
              selectedOption: _data['selectedOption'],
              isAdmin: widget.isAdmin,
              refreshList: widget.refreshList);
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
          child = _buildCard();
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
