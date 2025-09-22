import 'package:flutter/material.dart';
import 'description.dart';

class Info extends StatefulWidget {
  const Info(
      {super.key,
      required this.club,
      required this.role,
      required this.isAdmin});

  final String club;
  final String role;
  final bool isAdmin;

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: const Text('Chi siamo'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ), //
        body: widget.club == 'Tiber Club'
            ? Tiber(club: widget.club)
            : widget.club == 'Rampa Club'
            ? Rampa(club: widget.club, role: widget.role, isAdmin: widget.isAdmin)
            : Delta(club: widget.club, role: widget.role, isAdmin: widget.isAdmin));
  }
}
