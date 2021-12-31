/*

 * Date:            07/25/2021
 * Organization:    DreamSpace Academy
 * Website:         https://dreamspace.academy/
 * Author:          Gunarakulan Gunaratnam
 * Author Email:    gunarakulan@gmail.com
 * Contributors :   Abitharani Jeyachandran


  File Info
  ---------
  This is the landing page where the user lands on, it decides where to route the user. If the user is logged in already,
  it will redirect to the dashboard page. Otherwise, it will take the user for registration / login process.

 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart'; // Material library is the default file of dart language, contains all definition of widgets
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication library helps to authenticate users.
import 'package:firebase_core/firebase_core.dart'; // Firebase core contains the full structure of firebase backend.
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:debristracker/app/0-first-time-user-screens/get-started-screen.dart';
import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';

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

    initDynamicLinks();
  }

  void dispose() {
    super.dispose();
  }

  routeDecider(String deepLinkDocumentID) async {
    Firebase.initializeApp().whenComplete(() async {
      if (_auth.currentUser != null) {
        // If the user is not equal to null that means logged in, then it executes.

        if (deepLinkDocumentID == "[NONE]") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => DashboardPage()));
        } else {
          String currentUserDocumentID =
              await UserAccountUtils.getUserDocumentID();

          await FirebaseFirestore.instance
              .collection('event_data')
              .doc(deepLinkDocumentID)
              .get()
              .then((DocumentSnapshot documentSnapshot) async {
            var tempUserIDs = []; // Store userID wit Status
            bool isCurrentUserIDFound =
                false; // To check whether isCurrentUserIDFound already found in tempUserIDs list.

            for (var userID in documentSnapshot['participants'].toList()) {
              // Looping userIDS

              tempUserIDs.add(userID); // Add userIDS with status to this list.

              if (currentUserDocumentID ==
                  userID.toString().split("=")[0].trim()) {
                // Split only ID and match with current user id

                isCurrentUserIDFound = true; // Update as true, if it is found
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DashboardPage(
                            documentID:
                                deepLinkDocumentID))); // Navigate to the event, if it is found.
                break; // Break the loop.

              }
            }

            if (isCurrentUserIDFound == false) {
              // If it is false, means currentUserDocumentID is not found in the tempUserIDs list.

              tempUserIDs.add(currentUserDocumentID +
                  " = [PENDING]"); // Add the currentUserDocumentID to the list as pending.

              await FirebaseFirestoreClass.updateDocumentData(
                  "event_data", deepLinkDocumentID, {
                'participants': tempUserIDs
              }); // Update participants withe the currentUserDocumentID

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DashboardPage(
                          documentID: deepLinkDocumentID))); // Then, navigate.

            }
          });
        }
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => GetStartedPage()));
      }
    });
  }

  Future<void> initDynamicLinks() async {
    // Click deeplink when the app runs on background.
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        routeDecider(deepLink.toString().split("=")[1].trim());
      } else {
        routeDecider('[NONE]');
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    // Click deeplink when the app is completely down.
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;

    if (deepLink != null) {
      routeDecider(deepLink.toString().split("=")[1].trim());
    } else {
      routeDecider('[NONE]');
    }
  }

  // ### END FORM CONTROL ###

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
