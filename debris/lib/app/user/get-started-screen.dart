import 'package:flutter/material.dart'; // Material library is the default file of dart language, contains all definition of widgets
import 'package:flutter_spinkit/flutter_spinkit.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({Key? key}) : super(key: key);

  @override
  _GetStartedPageState createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
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
