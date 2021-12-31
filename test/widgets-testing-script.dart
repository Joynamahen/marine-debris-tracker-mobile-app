import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debristracker/app/0-first-time-user-screens/sign-up-with-mobile.dart';
import 'package:debristracker/app/0-first-time-user-screens/registration-screen.dart';
import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';
import 'package:debristracker/app/2-create-events-screens/event-creatation-main.dart';
import 'package:debristracker/app/landing-screen.dart';
import 'package:debristracker/main.dart';

widgetsTestingMethod() {
  testWidgets('MainHomePage Widget Testing', (WidgetTester tester) async {
    tester.pumpWidget(const MaterialApp(home: MainHomePage()));
  });

  testWidgets('LandingPage Widget Testing', (WidgetTester tester) async {
    tester.pumpWidget(const MaterialApp(home: LandingPage()));
  });

  testWidgets('SignUpWithMobile Widget Testing', (WidgetTester tester) async {
    tester.pumpWidget(const MaterialApp(home: SignUpWithMobile()));
  });

  testWidgets('GetUserInfo Widget Testing', (WidgetTester tester) async {
    Firebase.initializeApp().whenComplete(() {
      tester.pumpWidget(const MaterialApp(home: RegistrationPage()));
    });
  });

  testWidgets('DashboardPage Widget Testing', (WidgetTester tester) async {
    Firebase.initializeApp().whenComplete(() {
      tester.pumpWidget(MaterialApp(home: DashboardPage()));
    });
  });

  testWidgets('EventCreationMainScreen Widget Testing',
      (WidgetTester tester) async {
    Firebase.initializeApp().whenComplete(() {
      tester.pumpWidget(const MaterialApp(home: EventCreationMainScreen()));
    });
  });
}
