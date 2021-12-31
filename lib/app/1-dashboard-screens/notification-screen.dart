import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';

import 'dashboard-main-screen.dart';

String globalCurrentUserDocumentID = "";

streamNotificationData() {
  final Color primaryColor =
      Color(0xff274D6C); // Define a color button gradient
  final Color secondaryColor =
      Color(0xff00bfff); // Define a color button gradient

  return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notification_data')
          .where("notification_status", isEqualTo: "[ACTIVE]")
          .where('targeted_user_ids',
              arrayContainsAny: [globalCurrentUserDocumentID]).snapshots(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.data != null && snapshot.hasData) {
          return Container(
            //Add gradient to background
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
            child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: snapshot.data!.docs
                    .length, // Give the length of the streaming data.
                itemBuilder: (context, index) {
                  // Iterate the data

                  DocumentSnapshot documentSnapshot = snapshot
                      .data!.docs[index]; // Get data as list from streaming

                  // If notification_status is [ACTIVE], If the notification_category is [EVENT_REQUEST], If globalCurrentUserDocumentID exits in thetargeted_user_ids list, then execute this block.

                  if (documentSnapshot.get('notification_category') ==
                          "[EVENT_REQUEST]" &&
                      documentSnapshot
                          .get('targeted_user_ids')
                          .toList()
                          .contains(globalCurrentUserDocumentID)) {
                    // Check whether the current user id exit in the targeted user list.

                    getUsernameFutureBuilderController() async {
                      // Get name of the main user (invitorName)

                      String username = "";

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(documentSnapshot.get('main_user'))
                          .get()
                          .then((DocumentSnapshot documentSnapshot) {
                        username = documentSnapshot['name'].toString();
                      });

                      return username;
                    }

                    // Future Builder View
                    return FutureBuilder(
                        future: getUsernameFutureBuilderController(),
                        builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            String invitorName = snapshot.data;

                            return InkWell(
                                // When the user taps the button, show a snackbar.
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DashboardPage(
                                          documentID:
                                              globalEventDataDocumentID),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                    child: documentSnapshot.get(
                                                'notification_banner_image') ==
                                            "[SKIPPED]"
                                        ? Image.asset(
                                            "images/default-event-banner-image.png",
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.1,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.1,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: documentSnapshot.get(
                                                'notification_banner_image'),
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                      color: Colors.white,
                                                    ),
                                                    baseColor:
                                                        Colors.grey.shade300,
                                                    highlightColor:
                                                        Colors.grey.shade100),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.1,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.1, // this is the solution for border
                                          ),
                                  ),
                                  title: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            documentSnapshot
                                                .get('notification_name'),
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black
                                                    .withOpacity(0.65)),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.025,
                                          ),
                                          Text(
                                            documentSnapshot
                                                    .get('notification_date') +
                                                " at " +
                                                documentSnapshot
                                                    .get('notification_time'),
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black
                                                    .withOpacity(0.65)),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        invitorName,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.italic,
                                            color:
                                                Colors.black.withOpacity(0.65)),
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.0125,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.2,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: Color(0xffC4C4C4),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(34)),
                                                boxShadow: <BoxShadow>[
                                                  BoxShadow(
                                                    color: Color(0xff274D6C),
                                                    spreadRadius: 0,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: TextButton(
                                                // If the done button is clicked, do the following things.
                                                onPressed: () async {
                                                  String eventID =
                                                      documentSnapshot.get(
                                                          'notification_event_id'); // event id that we want to make pending as going.
                                                  String notificationID =
                                                      documentSnapshot
                                                          .id; // Current notification id

                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('event_data')
                                                      .doc(documentSnapshot.get(
                                                          'notification_event_id'))
                                                      .get()
                                                      .then((DocumentSnapshot
                                                          documentSnapshot) {
                                                    var data = documentSnapshot[
                                                        'participants'];
                                                    int index = data.indexOf(
                                                        globalCurrentUserDocumentID +
                                                            " = [PENDING]"); //Get index of pending

                                                    if (index != -1) {
                                                      // If it finds the index.

                                                      data[index] =
                                                          globalCurrentUserDocumentID +
                                                              " = [DECLINED]"; // change pending as going

                                                      FirebaseFirestoreClass
                                                          .updateDocumentData(
                                                              "event_data",
                                                              eventID, {
                                                        'participants': data
                                                      }); // Update pending as going in the event data.
                                                      FirebaseFirestoreClass
                                                          .updateDocumentData(
                                                              "notification_data",
                                                              notificationID, {
                                                        'notification_status':
                                                            '[INACTIVE]'
                                                      }); // Change inactive to delete.

                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              DashboardPage(
                                                            statusType:
                                                                "[EVENT_DECLINED]",
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  });
                                                },
                                                child: Text(
                                                  'DECLINE',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white),
                                                ),
                                              )),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.025,
                                          ),
                                          Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.2,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(34)),
                                                  boxShadow: <BoxShadow>[
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.25),
                                                      spreadRadius: 0,
                                                      blurRadius: 2,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                  gradient: LinearGradient(
                                                      begin: Alignment
                                                          .bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        secondaryColor,
                                                        primaryColor
                                                      ])),
                                              child: TextButton(
                                                // If the done button is clicked, do the following things.
                                                onPressed: () async {
                                                  String eventID =
                                                      documentSnapshot.get(
                                                          'notification_event_id'); // event id that we want to make pending as going.
                                                  String notificationID =
                                                      documentSnapshot
                                                          .id; // Current notification id

                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('event_data')
                                                      .doc(documentSnapshot.get(
                                                          'notification_event_id'))
                                                      .get()
                                                      .then((DocumentSnapshot
                                                          documentSnapshot) {
                                                    var data = documentSnapshot[
                                                        'participants'];
                                                    int index = data.indexOf(
                                                        globalCurrentUserDocumentID +
                                                            " = [PENDING]"); //Get index of pending

                                                    if (index != -1) {
                                                      // If it finds the index.

                                                      data[index] =
                                                          globalCurrentUserDocumentID +
                                                              " = [GOING]"; // change pending as going

                                                      FirebaseFirestoreClass
                                                          .updateDocumentData(
                                                              "event_data",
                                                              eventID, {
                                                        'participants': data
                                                      }); // Update pending as going in the event data.
                                                      FirebaseFirestoreClass
                                                          .updateDocumentData(
                                                              "notification_data",
                                                              notificationID, {
                                                        'notification_status':
                                                            '[INACTIVE]'
                                                      }); // Change inactive to delete.

                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              DashboardPage(
                                                            documentID: eventID,
                                                            statusType:
                                                                "[EVENT_ACCEPTED]",
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  });
                                                },
                                                child: Text(
                                                  'ACCEPT',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white),
                                                ),
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ));
                          } else {
                            return Text(""); // Third If

                          }
                        });
                  } else {
                    return Text(""); // Second If
                  }
                }),
          );
        } else {
          return Text(""); // First If
        }
      });
}

class NotificationScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NotificationScreen();
  }
}

class _NotificationScreen extends State<NotificationScreen> {
  void initState() {
    globalCurrentUserDocumentID = UserAccountUtils.getUserDocumentID();

    super.initState();
  }

  final Color fontColor =
      Color(0xff07B1A1); // Define a color for button gradient
  final Color primaryColor =
      Color(0xff04D3A8); // Define a color for button gradient
  final Color secondaryColor =
      Color(0xff00B7B2); // Define a color for button gradient

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          shape: Border(
              bottom:
                  BorderSide(color: Colors.black.withOpacity(0.2), width: 1)),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.navigate_before,
                size: 30, color: Color(0xff595959)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Column(
            children: [
              Text("Notifications",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.65))),
            ],
          ),
          centerTitle: true,
          backgroundColor: Color(0xffFFFFFF),
        ),
        body: streamNotificationData(),
      ),
    );
  }
}
