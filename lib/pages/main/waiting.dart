import 'package:flutter/material.dart';

class Waiting extends StatelessWidget {
  const Waiting({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          "images/Tiber.jpg",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        Center(
          child: SizedBox(
            height: 600,
            width: 620,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 10.0,
                shadowColor: Colors.black,
                surfaceTintColor: Colors.white54,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("images/logo.png", width: 150),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          "Please wait for your account to be approved",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                            "Your account needs to be approved by a monitor.\nThis might take a few hours.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.0)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
