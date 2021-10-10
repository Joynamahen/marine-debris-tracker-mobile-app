import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'landing-screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MaterialApp(home: MainHomePage())); // Run the MainHomePage.
}

// Create a stateful widget
class MainHomePage extends StatefulWidget {
  const MainHomePage({Key? key}) : super(key: key);
  @override
  _MainHomePageState createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  @override
  Widget build(BuildContext context) {
    return LandingPage();
  }
}
