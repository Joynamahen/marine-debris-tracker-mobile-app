import 'package:flutter/material.dart'; // Material library is the default file of dart language, contains all definition of widgets
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication library helps to authenticate users.
import 'package:firebase_core/firebase_core.dart'; // Firebase core contains the full structure of firebase backend.
import 'package:flutter_spinkit/flutter_spinkit.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Future<FirebaseApp> _initialization =
      Firebase.initializeApp(); //Firebase core initialization

  @override
  void initState() {
    super.initState();
  }

  //Widget that runs when the main executes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SpinKitFadingCircle(
          color: Colors.black,
        ),
      ),
    );
  }
}
