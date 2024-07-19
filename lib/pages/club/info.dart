import 'package:flutter/material.dart';

class Info extends StatefulWidget {

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter, // Align children to the top center
                child: Image.asset(
                  'images/logo.png',
                  width: 150,
                ),
              ),
              const SizedBox(height: 10),
              const Text("Francesco Martignoni"),
            ]
          ),
        )
      )
    );
  }
}