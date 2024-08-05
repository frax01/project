import 'package:flutter/material.dart';
import 'description.dart';

class Info extends StatefulWidget {
  const Info({super.key, required this.club});

  final String club;

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {

  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(
      fontSize: 20.0,
      color: Colors.black,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );

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
      ),
      body: widget.club == 'Tiber Club' ? Tiber(club: widget.club) : Delta(club: widget.club)
    );
  }
}



