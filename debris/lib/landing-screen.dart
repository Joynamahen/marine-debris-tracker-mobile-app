import 'package:flutter/material.dart'; // Material library is the default file of dart language, contains all definition of widgets
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication library helps to authenticate users.
import 'package:firebase_core/firebase_core.dart'; // Firebase core contains the full structure of firebase backend.
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'app/user/dashboard-screen.dart';
import 'app/user/get-started-screen.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final Future<FirebaseApp> _initialization =
      Firebase.initializeApp(); //Firebase core initialization

  @override
  void initState() {
    super.initState();
  }

  routeDecider() {
    Firebase.initializeApp().whenComplete(() {
      if (_auth.currentUser != null) {
        // If the user is not equal to null that means logged in, then it executes.

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                DashboardPage(), // Open dashboard page
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                GetStartedPage(), // Open dashboard page
          ),
          (route) => false,
        );
      }
    });
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
