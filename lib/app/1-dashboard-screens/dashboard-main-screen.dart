import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:debristracker/app/1-dashboard-screens/account-setting.dart';
import 'package:debristracker/app/1-dashboard-screens/notification-screen.dart';
import 'package:debristracker/app/1-dashboard-screens/participant-list-screen.dart';
import 'package:debristracker/app/2-create-events-screens/event-creatation-main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'add-extra-participants-screen.dart';
import 'event-setting.dart';

final Color fontColor = Color(0xff274D6C); // Define a color button gradient
final Color primaryColor = Color(0xff274D6C); // Define a color button gradient
final Color secondaryColor =
    Color(0xff00bfff); // Define a color button gradient
final FirebaseAuth _auth =
    FirebaseAuth.instance; // Create Firebase Auth instance

//Chat
String currentDate = DateFormat("yyyy/MM/dd").format(DateTime.now());
String currentTime = DateFormat("hh:mm a").format(DateTime.now());
final messageController =
    TextEditingController(); //Create a text-box controller to get the message from the user.
String profilePictureURL = "";
var globalCurrentUserName = "";
String currentChatId = "";
String chatDate = "";
String chatTime = "";

String globalEventDataDocumentID = "";
var globalCurrentUserDocumentID = "";

int selectedMainIndex = 0;
int selectedSubIndex = 0;
int selectedSuperSubIndex = 0;

bool detectFirstTime = false;

var acceptedPeopleUIDList = [];

class DashboardPage extends StatefulWidget {
  var documentID;
  var statusType;

  DashboardPage({Key? key, this.documentID, this.statusType}) : super(key: key);

  @override
  _DashboardPageState createState() =>
      _DashboardPageState(documentID, statusType);
}

getUserName() async {
  globalCurrentUserName = await UserAccountUtils.getCurrentUserUsername();
}

class _DashboardPageState extends State<DashboardPage> {
  PanelController _panelController = PanelController();
  _DashboardPageState(documentID, statusType);

  void initState() {
    globalCurrentUserDocumentID = UserAccountUtils.getUserDocumentID();
    getUserName();

    if (widget.documentID == null) {
      detectFirstTime = false;

      if (widget.statusType == "[EVENT_DECLINED]") {
        WidgetsBinding.instance!
            .addPostFrameCallback((_) => eventDeclinedTopBar());
      }
    } else if (widget.documentID == "[FIRST_TIME]") {
      detectFirstTime = true;
    } else {
      // After Insertion or Deeplink

      detectFirstTime = false;

      if (widget.statusType == "[EVENT_ACCEPTED]") {
        WidgetsBinding.instance!
            .addPostFrameCallback((_) => eventAcceptedTopBar());
      }

      globalEventDataDocumentID = widget
          .documentID; //Assign documentID which is passed after the event-creation.
      getEventDataIndicatorIndex();
    }

    super.initState();
  }

  void togglePanel() => _panelController.isPanelOpen
      ? _panelController.close()
      : _panelController.open();
  // Main Build function
  @override
  Widget build(BuildContext context) {
    notificationCheckerStreamer();
    return decideScreenFutureBuilderView();
  }

  eventAcceptedTopBar() {
    try {
      Flushbar(
        flushbarStyle: FlushbarStyle.FLOATING,
        flushbarPosition: FlushbarPosition.TOP,
        messageText: Text(
          "Event accepted",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12.0, color: Colors.white, fontFamily: "Montserrat"),
        ),
        margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.25, 0,
            MediaQuery.of(context).size.width * 0.25, 0),
        borderRadius: BorderRadius.circular(15),
        backgroundGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffD8833A), Color(0xffD8AC3A)]),
        duration: Duration(seconds: 3),
        isDismissible: true,
      )..show(context);
    } catch (e) {}
  }

  eventDeclinedTopBar() {
    try {
      Flushbar(
        flushbarStyle: FlushbarStyle.FLOATING,
        flushbarPosition: FlushbarPosition.TOP,
        messageText: Text(
          "Event declined",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12.0, color: Colors.white, fontFamily: "Montserrat"),
        ),
        margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.25, 0,
            MediaQuery.of(context).size.width * 0.25, 0),
        borderRadius: BorderRadius.circular(15),
        backgroundGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffD8833A), Color(0xffD8AC3A)]),
        duration: Duration(seconds: 3),
        isDismissible: true,
      )..show(context);
    } catch (e) {}
  }

  getEventBannerInitialDataStreamBuilderView() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('event_data')
            .where('participants', arrayContainsAny: [
              "$globalCurrentUserDocumentID = [GOING]",
              "$globalCurrentUserDocumentID = [PENDING]"
            ])
            .where("event_status", isEqualTo: "[ACTIVE]")
            .orderBy("start_date_time", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            bool isNoDateAvailable = false;
            var noDateEventData = [];
            var availableYears = [];
            var availableYearsMonths = [];

            snapshot.data!.docs.forEach((event) {
              if (event["start_date"] != "[SKIPPED]") {
                String year =
                    event["start_date"].toString().split(" ")[3].trim();
                String monthName =
                    event["start_date"].toString().split(" ")[1].trim();

                if (!availableYears.contains(year)) {
                  availableYears.add(year);
                }

                if (!availableYearsMonths.contains(year + "|" + monthName)) {
                  availableYearsMonths.add(year + "|" + monthName);
                }
              } else {
                noDateEventData.add(event);
                isNoDateAvailable = true;
              }
            });

            int viewLength = 0;

            if (availableYears.length > 0) {
              viewLength = availableYears.length;
            } else if (availableYears.length == 0 &&
                noDateEventData.length > 0) {
              viewLength = 1;
            }

            return ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: viewLength,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.0125,
                      ),
                      if (availableYears.length > 0) ...[
                        GradientText(
                          availableYears[index],
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          colors: [
                            Color(0xff3B455C),
                            Color(0xff00B7B2),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0125,
                        ),
                        for (var xm = 0;
                            xm < availableYearsMonths.length;
                            xm++) ...[
                          if (availableYearsMonths[xm]
                                  .toString()
                                  .split("|")[0]
                                  .trim() ==
                              availableYears[index]) ...[
                            Text(
                              availableYearsMonths[xm]
                                  .toString()
                                  .split("|")[1]
                                  .trim()
                                  .substring(0, 3),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff04D3A8)),
                            ),
                            for (var ed = 0;
                                ed < snapshot.data!.docs.length;
                                ed++) ...[
                              if (snapshot.data!.docs[ed]["start_date"] !=
                                  "[SKIPPED]") ...[
                                if (snapshot.data!.docs[ed]["start_date"]
                                            .toString()
                                            .split(" ")[3]
                                            .trim() ==
                                        availableYears[index] &&
                                    snapshot.data!.docs[ed]["start_date"]
                                            .toString()
                                            .split(" ")[1]
                                            .trim() ==
                                        availableYearsMonths[xm]
                                            .toString()
                                            .split("|")[1]
                                            .trim())
                                  GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.0125),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 200),
                                            height: (selectedMainIndex ==
                                                        index &&
                                                    selectedSubIndex == xm &&
                                                    selectedSuperSubIndex == ed)
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.1
                                                : 0,
                                            width: 3,
                                            color: Color(0xffFF6348),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.015,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.1,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.1,
                                            alignment: Alignment.center,
                                            child: InkWell(
                                                onTap: () async {
                                                  setState(() {
                                                    selectedMainIndex = index;
                                                    selectedSubIndex = xm;
                                                    selectedSuperSubIndex = ed;

                                                    globalEventDataDocumentID =
                                                        snapshot
                                                            .data!.docs[ed].id;
                                                  });
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(15),
                                                    topRight:
                                                        Radius.circular(5),
                                                    bottomLeft:
                                                        Radius.circular(15),
                                                    bottomRight:
                                                        Radius.circular(15),
                                                  ),
                                                  child: snapshot.data!.docs[ed]
                                                              [
                                                              'banner_image_url'] ==
                                                          "[SKIPPED]"
                                                      ? Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                          color: Colors.white,
                                                          child: Image.asset(
                                                            "images/default-event-banner-image.png",
                                                            fit: BoxFit.cover,
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.1,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.1,
                                                          ),
                                                        )
                                                      : CachedNetworkImage(
                                                          imageUrl: snapshot
                                                                  .data!
                                                                  .docs[ed][
                                                              "banner_image_url"],
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Shimmer
                                                              .fromColors(
                                                                  child:
                                                                      Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.1,
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.1,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                  baseColor: Colors
                                                                      .grey
                                                                      .shade300,
                                                                  highlightColor:
                                                                      Colors
                                                                          .grey
                                                                          .shade100),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.1, // this is the solution for border
                                                        ),
                                                )),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                              ]
                            ]
                          ]
                        ]
                      ],
                      if ((isNoDateAvailable == true &&
                              index == availableYears.length - 1) ||
                          (isNoDateAvailable == true &&
                              availableYears.length == 0)) ...[
                        Text(
                          "No Date",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff04D3A8)),
                        ),
                        for (var en = 0; en < noDateEventData.length; en++) ...[
                          GestureDetector(
                            child: Container(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.width *
                                      0.0125),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    height: (selectedMainIndex == index &&
                                            selectedSubIndex == en &&
                                            selectedSuperSubIndex == -1)
                                        ? MediaQuery.of(context).size.width *
                                            0.1
                                        : 0,
                                    width: 3,
                                    color: Color(0xffFF6348),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.015,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                    height:
                                        MediaQuery.of(context).size.width * 0.1,
                                    alignment: Alignment.center,
                                    child: InkWell(
                                        onTap: () async {
                                          setState(() {
                                            selectedSuperSubIndex = -1;
                                            selectedMainIndex = index;
                                            selectedSubIndex = en;
                                            globalEventDataDocumentID =
                                                noDateEventData[en].id;
                                          });
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(15),
                                            topRight: Radius.circular(5),
                                            bottomLeft: Radius.circular(15),
                                            bottomRight: Radius.circular(15),
                                          ),
                                          child: noDateEventData[en]
                                                      ['banner_image_url'] ==
                                                  "[SKIPPED]"
                                              ? Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.1,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.1,
                                                  color: Colors.white,
                                                  child: Image.asset(
                                                    "images/default-event-banner-image.png",
                                                    fit: BoxFit.cover,
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
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: noDateEventData[en]
                                                      ['banner_image_url'],
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Shimmer.fromColors(
                                                          child: Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.1,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.1,
                                                            color: Colors.white,
                                                          ),
                                                          baseColor: Colors
                                                              .grey.shade300,
                                                          highlightColor: Colors
                                                              .grey.shade100),
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
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ]
                      ]
                    ],
                  );
                });
          } else {
            return Scaffold(
                body: Shimmer.fromColors(
                    child: Container(
                      color: Colors.white,
                    ),
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100));
          }
        });
  }

  messageNotificationFutureBuilderView() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('event_data')
          .doc(globalEventDataDocumentID)
          .get(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return Container(
            decoration: new BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xff04D3A8),
                      Color(0xff00B7B2),
                    ])),
            constraints: BoxConstraints(
              minWidth: 8,
              minHeight: 8,
            ),
          );
        } else {
          return Text("");
        }
      },
    );
  }

  detectTheFirstUpComingEvent() async {
    //Month Index
    Map months = {
      'January': '1',
      'February': '2',
      'March': '3',
      'April': '4',
      'May': '5',
      'June': '6',
      'July': '7',
      'August': '8',
      'September': '9',
      'October': '10',
      'November': '11',
      'December': '12'
    };

    final DateTime now = DateTime.now();
    final DateFormat formatter =
        DateFormat('yyyy-MM-dd HH-mm'); // Get current Date & Time.
    final String currentDateString = formatter
        .format(now); //  Convert the current date to the above formatter.
    DateTime currentDate = formatter
        .parse(currentDateString); //   Convert string data as date format.

    String storeFirstDocIDForAllSkippedSituation =
        ""; // Create a variable to capture documentID if all event date are skipped.
    bool isUnexpiredEventFound =
        false; // Become true, if any Unexpired Event found
    bool isExpiredEventFound = false; // Become true, if any Expired Event found

    List<int> minutesListUnexpiredEvents =
        []; // Difference time in minutes (List) Unexpired.
    List<String> documentIDSListUnexpiredEvents =
        []; //  DocumentIDs that matches the difference time in minutesList Unexpired.

    List<int> minutesListExpiredEvents =
        []; // Difference time in minutes (List) Unexpired.
    List<String> documentIDSListExpiredEvents =
        []; //  DocumentIDs that matches the difference time in minutesList Unexpired.

    // Get all event_data where the globalCurrentDocument ID matches.
    await FirebaseFirestore.instance
        .collection('event_data')
        .where('participants', arrayContainsAny: [
          "$globalCurrentUserDocumentID = [GOING]",
          "$globalCurrentUserDocumentID = [PENDING]"
        ])
        .get()
        .then((QuerySnapshot querySnapshot) async {
          //Loop each documents
          querySnapshot.docs.forEach((doc) {
            if (doc["start_date"] != '[SKIPPED]') {
              // If start_date is not equal [SKIPPED],

              var eventDateList = doc["start_date"]
                  .toString()
                  .split(" "); // Split by SPACE to separate year, month, day.
              String year = eventDateList[3]; //  Get year
              String month = months[eventDateList[1]]; //   Get month
              String day = eventDateList[2].replaceAll(",", ""); //    Get day

              var eventTimeList =
                  []; // Create a list to store time as hour and minute

              if (doc["start_time"] != '[SKIPPED]' &&
                  doc["start_time"] != '[ALLDAY]') {
                eventTimeList = doc["start_time"]
                    .toString()
                    .split(":"); //Split time as hour and minute

              } else {
                eventTimeList =
                    "00:00".toString().split(":"); //Store the time as 00:00
              }

              //Convert the eventDateTime as date type.
              DateTime eventDateTime = formatter.parse(year +
                  "-" +
                  month +
                  '-' +
                  day +
                  " " +
                  eventTimeList[0] +
                  "-" +
                  eventTimeList[1]);

              // For unexpired events
              if (eventDateTime.isAfter(currentDate) ||
                  eventDateTime.isAtSameMomentAs(currentDate)) {
                // If eventDateTime is after the currentDateTime or If eventDateTime is equal to currentDateTime

                isUnexpiredEventFound = true;

                final differenceInMinutes = eventDateTime
                    .difference(currentDate)
                    .inMinutes; // Calculate the difference in minutes.

                minutesListUnexpiredEvents.add(
                    differenceInMinutes); // Add the difference to the list.
                documentIDSListUnexpiredEvents
                    .add(doc.id); //  Add corresponding documentID to the list.

              } else {
                // For expired events

                isExpiredEventFound = true;

                final differenceInMinutes = eventDateTime
                    .difference(currentDate)
                    .inMinutes; // Calculate the difference in minutes.

                minutesListExpiredEvents.add(
                    differenceInMinutes); // Add the difference to the list.
                documentIDSListExpiredEvents
                    .add(doc.id); //  Add corresponding documentID to the list.

              }
            } else {
              // if all event's date & and time are skipped
              if (storeFirstDocIDForAllSkippedSituation == "") {
                //Get first docID, if all are skipped, then it will be used to open the event.
                storeFirstDocIDForAllSkippedSituation = doc.id;
              }
            }
          });

          if (isUnexpiredEventFound == false && isExpiredEventFound == true) {
            // Only Expired event found

            // If unexpired event not found. But, expired events found. It should give to priority to expired events that is finished last time.

            int indexPosition = minutesListExpiredEvents.indexOf(
                minutesListExpiredEvents.reduce(
                    min)); // Get minimum value from minutesList & get it's index position
            var upComingEventDocID = documentIDSListExpiredEvents[
                indexPosition]; //match that index position with documentIDSList to get the document ID

            setState(() {
              globalEventDataDocumentID =
                  upComingEventDocID; //Assign the documentID to the globalEventDataDocumentID that will be opened when starting the app
            });
            await getEventDataIndicatorIndex();
          } else if (isUnexpiredEventFound == true &&
              isExpiredEventFound == false) {
            // Only Unexpired event found

            // If unexpired event found. But, not expired events. It should give to priority to unexpired events.

            int indexPosition = minutesListUnexpiredEvents.indexOf(
                minutesListUnexpiredEvents.reduce(
                    min)); // Get minimum value from minutesList & get it's index position
            var upComingEventDocID = documentIDSListUnexpiredEvents[
                indexPosition]; //match that index position with documentIDSList to get the document ID

            setState(() {
              globalEventDataDocumentID =
                  upComingEventDocID; //Assign the documentID to the globalEventDataDocumentID that will be opened when starting the app
            });
            await getEventDataIndicatorIndex();
          } else if (isUnexpiredEventFound == true &&
              isExpiredEventFound == true) {
            // If both of them are true. It should give to priority to unexpired events.

            int indexPosition = minutesListUnexpiredEvents.indexOf(
                minutesListUnexpiredEvents.reduce(
                    min)); // Get minimum value from minutesList & get it's index position
            var upComingEventDocID = documentIDSListUnexpiredEvents[
                indexPosition]; //match that index position with documentIDSList to get the document ID

            setState(() {
              globalEventDataDocumentID =
                  upComingEventDocID; //Assign the documentID to the globalEventDataDocumentID that will be opened when starting the app
            });
            await getEventDataIndicatorIndex();
          } else if (isUnexpiredEventFound == false &&
              isExpiredEventFound == false) {
            // If no expired events & no unexpired events found, It should select the first documentID from the skipped events.

            setState(() {
              globalEventDataDocumentID = storeFirstDocIDForAllSkippedSituation;
            });
            await getEventDataIndicatorIndex();
          }
        });

    return "[TRUE]";
  }

  returnDashboardFutureBuilderView() {
    return FutureBuilder(
      future: detectTheFirstUpComingEvent(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData && snapshot.data.toString() == "[TRUE]") {
          detectFirstTime = false;

          return returnDashboard();
        } else {
          return Scaffold(
            body: Center(
              child: SpinKitFadingCircle(
                color: Colors.black,
              ),
            ),
          );
        }
      },
    );
  }

  decideScreenFutureBuilderView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('event_data')
          .where('participants', arrayContainsAny: [
            "$globalCurrentUserDocumentID = [GOING]",
            "$globalCurrentUserDocumentID = [PENDING]"
          ])
          .where("event_status", isEqualTo: "[ACTIVE]")
          .orderBy("start_date_time", descending: true)
          .snapshots(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.length == 0) {
            return returnFirstTimeDashboard();
          } else if (snapshot.data!.docs.length > 0) {
            if (detectFirstTime == true) {
              return returnDashboardFutureBuilderView();
            } else {
              return returnDashboard();
            }
          } else {
            return Scaffold(
              body: Center(
                child: SpinKitFadingCircle(
                  color: Colors.black,
                ),
              ),
            );
          }
        } else {
          return Scaffold(
            body: Center(
              child: SpinKitFadingCircle(
                color: Colors.black,
              ),
            ),
          );
        }
      },
    );
  }

  notificationCheckerStreamer() {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(globalCurrentUserDocumentID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!['is_notification_available'] == "[TRUE]") {
              return Positioned(
                right: 5,
                top: 5,
                child: new Container(
                  decoration: new BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xffD8AC3A).withOpacity(0.8),
                            Color(0xffD8833A),
                          ])),
                  constraints: BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              );
            } else {
              return Text("");
            }
          } else {
            return Text("");
          }
        });
  }

  getEventDataIndicatorIndex() async {
    int mainIndex = 0;
    int subIndex = 0;
    int superSubIndex = 0;

    bool isNoDateAvailable = true;

    var allDataEventIDs = [];
    var availableYears = [];
    var availableYearsMonths = [];

    QuerySnapshot<Map<String, dynamic>> allData =
        await FirebaseFirestore.instance
            .collection('event_data')
            .where('participants', arrayContainsAny: [
              "$globalCurrentUserDocumentID = [GOING]",
              "$globalCurrentUserDocumentID = [PENDING]"
            ])
            .where("event_status", isEqualTo: "[ACTIVE]")
            .orderBy("start_date_time", descending: true)
            .get();

    allData.docs.forEach((event) {
      allDataEventIDs.add(event);

      if (event["start_date"] != "[SKIPPED]") {
        if (isNoDateAvailable == true) {
          isNoDateAvailable = false;
        }

        String year = event["start_date"].toString().split(" ")[3].trim();
        String monthName = event["start_date"].toString().split(" ")[1].trim();

        if (!availableYears.contains(year)) {
          availableYears.add(year);
        }

        if (!availableYearsMonths.contains(year + "|" + monthName)) {
          availableYearsMonths.add(year + "|" + monthName);
        }
      }
    });

    bool isIDFound = false;

    if (isNoDateAvailable == false) {
      for (var x = 0; x < availableYears.length; x++) {
        mainIndex++;

        for (var y = 0; y < availableYearsMonths.length; y++) {
          if (availableYearsMonths[y].toString().split("|")[0].trim() ==
              availableYears[x]) {
            subIndex++;

            for (var z = 0; z < allDataEventIDs.length; z++) {
              if (allDataEventIDs[z]["start_date"] != "[SKIPPED]") {
                if (allDataEventIDs[z]["start_date"]
                            .toString()
                            .split(" ")[3]
                            .trim() ==
                        availableYears[x] &&
                    allDataEventIDs[z]["start_date"]
                            .toString()
                            .split(" ")[1]
                            .trim() ==
                        availableYearsMonths[y]
                            .toString()
                            .split("|")[1]
                            .trim()) {
                  superSubIndex++;

                  if (globalEventDataDocumentID == allDataEventIDs[z].id) {
                    selectedMainIndex = mainIndex - 1;
                    selectedSubIndex = subIndex - 1;
                    selectedSuperSubIndex = superSubIndex - 1;

                    isIDFound = true;
                  }
                }
              }

              if (isIDFound == true) {
                break;
              }
            }

            if (isIDFound == true) {
              break;
            }
          }

          if (isIDFound == true) {
            break;
          }
        }
      }
    } else {
      selectedMainIndex = 0;
      selectedSubIndex = 0;
      selectedSuperSubIndex = 0;
    }
  }

  uploadChatDataToDatabase() async {
    var currentTimestamp = DateTime.now().millisecondsSinceEpoch;

    chatDate = DateFormat("yyyy/MM/dd").format(DateTime.now());
    chatTime = DateFormat("hh:mm a").format(DateTime.now());
    DocumentReference ref = FirebaseFirestore.instance
        .collection("chat_data")
        .doc(); // Get the next docID
    String currentChatId = ref.id;

    Map<String, dynamic> chatData = {
      "chat_id": currentChatId,
      "event_id": globalEventDataDocumentID,
      "user_id": globalCurrentUserDocumentID,
      "message": messageController.text,
      "chat_date": chatDate,
      "chat_time": chatTime,
      "timestamp": currentTimestamp,
    };

    await FirebaseFirestoreClass.insertMapDataWithCustomDocumentID(
        chatData, "chat_data", currentChatId);
    messageController.clear(); //clear TextBox

    // Add a field to the event document.

    FirebaseFirestore.instance
        .collection('event_data')
        .doc(globalEventDataDocumentID)
        .update({
      'target_message_notification_uids':
          FieldValue.arrayUnion(acceptedPeopleUIDList)
    });
  }

  getProfileDataFutureBuilderController(String userID) async {
    var profileData = [];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      profileData.add(documentSnapshot['name'].toString());
      profileData.add(documentSnapshot['profile_picture_url'].toString());
    });

    return profileData;
  }

  getProfileDataFutureBuilderView(var basicChatData) {
    return FutureBuilder(
      future: getProfileDataFutureBuilderController(basicChatData[3]),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              Card(
                margin: EdgeInsets.only(top: 15),
                elevation: 0,
                color: Color(0xff3B455C),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(5),
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      child: snapshot.data[1] == "[SKIPPED]"
                          ? Image.asset(
                              "images/default-profile-picture.png",
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width *
                                  0.1, // this is the solution for border
                            )
                          : CachedNetworkImage(
                              imageUrl: snapshot.data[1],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                    height:
                                        MediaQuery.of(context).size.width * 0.1,
                                    color: Colors.white,
                                  ),
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width *
                                  0.1, // this is the solution for border
                            ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                snapshot.data[0],
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xffffffff),
                                ),
                              ),
                              Text(
                                basicChatData[0] + " at " + basicChatData[1],
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xffffffff).withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            basicChatData[2],
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xffffffff),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              /*ListTile(
                onLongPress: () {},
                enabled: true,
                dense: true,
                contentPadding: EdgeInsets.all(0),
                visualDensity: VisualDensity(horizontal: 0, vertical: 0),
                minVerticalPadding: 0,
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(5),
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      child: snapshot.data[1] == "[SKIPPED]"
                          ? Image.asset(
                              "images/default-profile-picture.png",
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width *
                                  0.1, // this is the solution for border
                            )
                          : CachedNetworkImage(
                              imageUrl: snapshot.data[1],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                    height:
                                        MediaQuery.of(context).size.width * 0.1,
                                    color: Colors.white,
                                  ),
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width *
                                  0.1, // this is the solution for border
                            ),
                    ),
                  ],
                ),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      snapshot.data[0],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xffffffff),
                      ),
                    ),
                    Text(
                      basicChatData[0] + " at " + basicChatData[1],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xffffffff).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  basicChatData[2],
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xffffffff),
                  ),
                ),
              ),*/
            ],
          );
        } else {
          return Text("");
        }
      },
    );
  }

  ScrollController _scrollController = ScrollController();

  streamChatData() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_data')
            .where("event_id", isEqualTo: globalEventDataDocumentID)
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.data != null && snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WELCOME. This is the start of your event chat.",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xffffffff),
                  ),
                ),
                Container(
                  child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot documentSnapshot =
                            snapshot.data!.docs[index];
                        var basicChatData = [
                          documentSnapshot.get('chat_date'),
                          documentSnapshot.get('chat_time'),
                          documentSnapshot.get('message'),
                          documentSnapshot.get('user_id')
                        ];
                        return getProfileDataFutureBuilderView(basicChatData);
                      }),
                ),
              ],
            );
          } else {
            return Text("");
          }
        });
  }

  getUserProfilePictureFutureBuilderController() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(globalCurrentUserDocumentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      profilePictureURL = documentSnapshot['profile_picture_url'].toString();
    });

    return profilePictureURL;
  }

  getUserProfilePictureFutureBuilderView() {
    return FutureBuilder(
      future: getUserProfilePictureFutureBuilderController(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return InkWell(
            onTap: () async {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AccountSettingScreen()));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: snapshot.data.toString() != '[SKIPPED]'
                  ? CachedNetworkImage(
                      imageUrl: snapshot.data.toString(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                          child: Container(
                            width: 40,
                            height: 40,
                            color: Colors.white,
                          ),
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      width: 40,
                      height: 40, // this is the solution for border
                    )
                  : Image.asset(
                      "images/default-profile-picture.png",
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40, // this is the solution for border
                    ),
            ),
          );
        } else {
          return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: Shimmer.fromColors(
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.white,
                  ),
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100));
        }
      },
    );
  }

  invitationMessageFutureBuilderController(String eventCreatorID) async {
    var data;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(eventCreatorID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      data = documentSnapshot;
    });

    return data;
  }

  invitationMessageFutureBuilderView(String eventCreatorID) {
    return FutureBuilder(
      future: invitationMessageFutureBuilderController(eventCreatorID),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Text(
            "Let " +
                snapshot.data['name'].toString() +
                " know if you can make it to “Birthday Reunion Lio&Tim”",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xffc4c4c4)),
          );
        } else {
          return Text("");
        }
      },
    );
  }

  getEventDataFutureBuilderController() async {
    var data;

    if (globalEventDataDocumentID != "" && globalEventDataDocumentID != null) {
      await FirebaseFirestore.instance
          .collection('event_data')
          .doc(globalEventDataDocumentID)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        data = documentSnapshot;
      });

      return data;
    }
  }

  getEventDataFutureBuilderView() {
    return FutureBuilder(
      future: getEventDataFutureBuilderController(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final String currentYear = DateFormat('yyyy').format(DateTime.now());
          String displayDateTime = "";

          if (snapshot.data['start_date'] != '[SKIPPED]' &&
              snapshot.data['end_date'] != '[SKIPPED]') {
            // If start date and end date are not equal to skipped.

            if (snapshot.data['start_date'] == snapshot.data['end_date']) {
              // If start Date and end Date are on the same day, don't show the end date agiain.

              var startDateSplitArray = snapshot.data['start_date']
                  .toString()
                  .split(" "); // Split by SPACE to separate year, month, day.

              String startYear = startDateSplitArray[3]; //   Get year
              String startMonth = startDateSplitArray[1]; //   Get month
              startMonth =
                  startMonth.substring(0, 3); //   Get 3 letters of month.

              String startDay = startDateSplitArray[0].replaceAll(",", "");
              String startDate = startDateSplitArray[2].replaceAll(",", "");

              if (snapshot.data['start_time'] != "[ALLDAY]" &&
                  snapshot.data['end_time'] != "[ALLDAY]") {
                // If start_time and end_time is NOT equal to [ALLDAY].

                if (startYear == currentYear) {
                  // If the start year is equal to the current year. Dont need to show the year

                  if (snapshot.data['start_time'] == "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    // If both start and end time are skipped, don't need to show start time and end time.

                    displayDateTime =
                        startDay + ", " + startDate + ". " + startMonth;
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] != "[SKIPPED]") {
                    // If start time and end time are not skipped, show both time.

                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        snapshot.data['start_time'] +
                        " - " +
                        snapshot.data['end_time'];
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    // If start_time is NOT equal to skipped but, end time is skipped, show only  start time with the date.

                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        snapshot.data['start_time'];
                  }
                } else if (startYear != currentYear) {
                  //If the current year is not same as the selected year, we need the start year. Ex: Event creates on dec month that will be held next year of jan.

                  if (snapshot.data['start_time'] == "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    // If both start and end time are skipped, don't need to show start time and end time.

                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        startYear;
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] != "[SKIPPED]") {
                    // If start time and end time are not skipped, show both time.

                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        startYear +
                        ", " +
                        snapshot.data['start_time'] +
                        " - " +
                        snapshot.data['end_time'];
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    // If start_time is NOT equal to skipped but, end time is skipped, show only  start time with the date.

                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        startYear +
                        ", " +
                        snapshot.data['start_time'];
                  }
                }
              } else {
                // If it is a all day event

                if (startYear == currentYear) {
                  // If current is same as start year, don't need to show year

                  displayDateTime = startDay +
                      ", " +
                      startDate +
                      ". " +
                      startMonth +
                      ", 00:00 - 23:59";
                } else {
                  // Otherwise, It is important to show the year.

                  displayDateTime = startDay +
                      ", " +
                      startDate +
                      ". " +
                      startMonth +
                      ", " +
                      startYear +
                      ", 00:00 - 23:59";
                }
              }
            } else {
              // If start date and end date not same.

              var startDateSplitArray = snapshot.data['start_date']
                  .toString()
                  .split(" "); // Split by SPACE to separate year, month, day.
              String startYear = startDateSplitArray[3];
              String startMonth =
                  startDateSplitArray[1].substring(0, 3); //   Get month
              String startDay = startDateSplitArray[0].replaceAll(",", "");
              String startDate =
                  startDateSplitArray[2].replaceAll(",", ""); //    Get day

              var endDateSplitArray = snapshot.data['end_date']
                  .toString()
                  .split(" "); // Split by SPACE to separate year, month, day.
              String endYear = endDateSplitArray[3];
              String endMonth =
                  endDateSplitArray[1].substring(0, 3); //   Get month
              String endDay = endDateSplitArray[0].replaceAll(",", "");
              String endDate =
                  endDateSplitArray[2].replaceAll(",", ""); //    Get day

              if (snapshot.data['start_time'] != "[ALLDAY]" &&
                  snapshot.data['end_time'] != "[ALLDAY]") {
                // If start and end time not euql to allday.

                if (endYear == currentYear) {
                  if (snapshot.data['start_time'] == "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    // If start time and end time skipped. don't need to show start and time time.

                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        " - " +
                        endDay +
                        ", " +
                        endDate +
                        ". " +
                        endMonth;
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] != "[SKIPPED]") {
                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        snapshot.data['start_time'] +
                        " - " +
                        endDay +
                        ", " +
                        endDate +
                        ". " +
                        endMonth +
                        ", " +
                        snapshot.data['end_time'];
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        snapshot.data['start_time'] +
                        " - " +
                        endDay +
                        ", " +
                        endDate +
                        ". " +
                        endMonth;
                  }
                } else {
                  // If end year is not same as current year.

                  if (snapshot.data['start_time'] == "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    // If start time and end time skipped. don't need to show start and time time.

                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        startYear +
                        " - " +
                        endDay +
                        ", " +
                        endDate +
                        ". " +
                        endMonth +
                        ", " +
                        endYear;
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] != "[SKIPPED]") {
                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        startYear +
                        ", " +
                        snapshot.data['start_time'] +
                        " - " +
                        endDay +
                        ", " +
                        endDate +
                        ". " +
                        endMonth +
                        ", " +
                        endYear +
                        ", " +
                        snapshot.data['end_time'];
                  } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        startYear +
                        ", " +
                        snapshot.data['start_time'] +
                        " - " +
                        endDay +
                        ", " +
                        endDate +
                        ". " +
                        endMonth +
                        ", " +
                        endYear;
                  }
                }
              } else {
                // If this is a all day event.
                if (endYear == currentYear) {
                  // If endYear and current year same

                  displayDateTime = startDay +
                      ", " +
                      startDate +
                      ". " +
                      startMonth +
                      ", " +
                      "00:00" +
                      " - " +
                      endDay +
                      ", " +
                      endDate +
                      ". " +
                      endMonth +
                      ", " +
                      "23:59";
                } else {
                  // If endYear and Current year are not same, show year with it.

                  displayDateTime = startDay +
                      ", " +
                      startDate +
                      ". " +
                      startMonth +
                      ", " +
                      startYear +
                      ", " +
                      "00:00" +
                      " - " +
                      endDay +
                      ", " +
                      endDate +
                      ". " +
                      endMonth +
                      ", " +
                      endYear +
                      ", " +
                      "23:59";
                }
              }
            }
          } else {
            if (snapshot.data['start_date'] != '[SKIPPED]' &&
                snapshot.data['end_date'] == '[SKIPPED]') {
              var startDateSplitArray = snapshot.data['start_date']
                  .toString()
                  .split(" "); // Split by SPACE to separate year, month, day.

              String startYear = startDateSplitArray[3]; //   Get month
              String startMonth = startDateSplitArray[1]; //   Get month
              startMonth = startMonth.substring(0, 3); //   Get month
              String startDay = startDateSplitArray[0].replaceAll(",", "");
              String startDate = startDateSplitArray[2].replaceAll(",", ""); //

              if (snapshot.data['start_time'] != "[ALLDAY]" &&
                  snapshot.data['end_time'] != "[ALLDAY]") {
                if (startYear == currentYear) {
                  if (snapshot.data['start_time'] == "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    displayDateTime =
                        startDay + ", " + startDate + ". " + startMonth;
                  } else {
                    if (snapshot.data['start_time'] != "[SKIPPED]" &&
                        snapshot.data['end_time'] == "[SKIPPED]") {
                      displayDateTime = startDay +
                          ", " +
                          startDate +
                          ". " +
                          startMonth +
                          ", " +
                          snapshot.data['start_time'];
                    } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                        snapshot.data['end_time'] != "[SKIPPED]") {
                      displayDateTime = startDay +
                          ", " +
                          startDate +
                          ". " +
                          startMonth +
                          ", " +
                          snapshot.data['start_time'] +
                          " - " +
                          snapshot.data['end_time'];
                    }
                  }
                } else {
                  if (snapshot.data['start_time'] == "[SKIPPED]" &&
                      snapshot.data['end_time'] == "[SKIPPED]") {
                    displayDateTime = startDay +
                        ", " +
                        startDate +
                        ". " +
                        startMonth +
                        ", " +
                        startYear;
                  } else {
                    if (snapshot.data['start_time'] != "[SKIPPED]" &&
                        snapshot.data['end_time'] == "[SKIPPED]") {
                      displayDateTime = startDay +
                          ", " +
                          startDate +
                          ". " +
                          startMonth +
                          ", " +
                          startYear +
                          ", " +
                          snapshot.data['start_time'];
                    } else if (snapshot.data['start_time'] != "[SKIPPED]" &&
                        snapshot.data['end_time'] != "[SKIPPED]") {
                      displayDateTime = startDay +
                          ", " +
                          startDate +
                          ". " +
                          startMonth +
                          ", " +
                          startYear +
                          ", " +
                          snapshot.data['start_time'] +
                          " - " +
                          snapshot.data['end_time'];
                    }
                  }
                }
              } else {
                // If  it is a all day event.
                if (startYear == currentYear) {
                  displayDateTime = startDay +
                      ", " +
                      startDate +
                      ". " +
                      startMonth +
                      ", 00:00 - 23:59";
                } else {
                  displayDateTime = startDay +
                      ", " +
                      startDate +
                      ". " +
                      startMonth +
                      ", " +
                      startYear +
                      ", 00:00 - 23:59";
                }
              }
            }
          }

          bool isRequestAccepted = false;
          bool isHostAccess = false;

          // Loop the participant list
          for (final id in snapshot.data['participants'].toList()) {
            if (globalCurrentUserDocumentID + " = [GOING]" == id) {
              // Check if globalCurrentUserDocumentID is in the list.
              isRequestAccepted = true;
            }
          }

          if (isRequestAccepted == true) {
            if (snapshot.data['guest_as_host'] == "[TRUE]") {
              isHostAccess = true;
            } else if (snapshot.data['host']
                .contains(globalCurrentUserDocumentID)) {
              isHostAccess = true;
            } else {
              isHostAccess = false;
            }
          }

          return SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width -
                  MediaQuery.of(context).size.width * 0.15,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xffF3F0E6), Color(0xffFFFFFF)])),
              constraints: BoxConstraints(
                  maxWidth: 600,
                  minHeight: MediaQuery.of(context).size.height,
                  maxHeight: double.infinity),
              padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.025),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.data['event_name'],
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff595959)),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.0125,
                  ),
                  Text(
                    displayDateTime,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff000000).withOpacity(0.43)),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.0125,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: snapshot.data['banner_image_url'] == '[SKIPPED]'
                        ? ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            child: Image.asset(
                              "images/default-event-banner-image.png",
                              width: MediaQuery.of(context).size.width * 0.4,
                              height:
                                  MediaQuery.of(context).size.height * 0.225,
                              fit: BoxFit.cover,
                            ))
                        : ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: snapshot.data['banner_image_url'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                    color: Colors.white,
                                  ),
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.25,
                              // this is the solution for border
                            ),
                          ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.025,
                  ),
                  if (snapshot.data['event_intro'] != '[SKIPPED]')
                    Text(
                      "description",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff04D3A8)),
                    ),
                  if (snapshot.data['event_intro'] != '[SKIPPED]')
                    Text(
                      snapshot.data['event_intro'],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff000000).withOpacity(0.63)),
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.0125,
                  ),
                  if (snapshot.data['location'] != "[SKIPPED]")
                    Text(
                      "Location",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff04D3A8)),
                    ),
                  if (snapshot.data['location'] != "[SKIPPED]")
                    Text(
                      snapshot.data['location'],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff000000).withOpacity(0.65)),
                    ),
                  if (snapshot.data['location'] != "[SKIPPED]")
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.0125,
                    ),
                  InkWell(
                    onTap: () {},
                    child: Text(
                      "participants",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff04D3A8)),
                    ),
                  ),
                  getInvitedParticipantsProfileFutureBuilderView(
                      snapshot.data['participants']),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.0125,
                  ),
                  if (isRequestAccepted == true && isHostAccess == true)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: MediaQuery.of(context).size.height * 0.04,
                      alignment: Alignment.center,
                      child: TextButton(
                        // If the done button is clicked, do the following things.
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AddExtraParticipantsPage(
                                  eventDocumentID: globalEventDataDocumentID,
                                  eventName: snapshot.data['event_name'])));
                        },
                        child: Text(
                          'Invite friends',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(34)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              spreadRadius: 0,
                              blurRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                          gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                secondaryColor,
                                primaryColor
                              ])), // Apply gradient to the button
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.0125,
                  ),
                  if (isRequestAccepted == false)
                    Column(
                      children: [
                        Divider(
                          color: Color(0xffc4c4c4),
                          endIndent: MediaQuery.of(context).size.width * 0.025,
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width * 0.025),
                          child: Column(
                            children: [
                              invitationMessageFutureBuilderView(
                                  snapshot.data['event_creator']),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.0125,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Color(0xffC4C4C4),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(34)),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: Color(0xff04D3A8),
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
                                              globalEventDataDocumentID; // event id that we want to make pending as going.

                                          String notificationID = snapshot.data[
                                              'notification_id']; // Current notification id

                                          await FirebaseFirestore.instance
                                              .collection('event_data')
                                              .doc(globalEventDataDocumentID)
                                              .get()
                                              .then((DocumentSnapshot
                                                  documentSnapshot) {
                                            var data =
                                                snapshot.data['participants'];
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
                                                      "event_data", eventID, {
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
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
                                        ),
                                      )),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.025,
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      height: 30,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
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
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                secondaryColor,
                                                primaryColor
                                              ])),
                                      child: TextButton(
                                        // If the done button is clicked, do the following things.
                                        onPressed: () async {
                                          String eventID =
                                              globalEventDataDocumentID; // event id that we want to make pending as going.

                                          String notificationID = snapshot.data[
                                              'notification_id']; // Current notification id

                                          await FirebaseFirestore.instance
                                              .collection('event_data')
                                              .doc(globalEventDataDocumentID)
                                              .get()
                                              .then((DocumentSnapshot
                                                  documentSnapshot) async {
                                            var data =
                                                snapshot.data['participants'];
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
                                                      "event_data", eventID, {
                                                'participants': data
                                              }); // Update pending as going in the event data.
                                              await FirebaseFirestoreClass
                                                  .updateDocumentData(
                                                      "notification_data",
                                                      notificationID, {
                                                'notification_status':
                                                    '[INACTIVE]'
                                              }); // Change inactive to delete.

                                              FirebaseFirestore.instance
                                                  .collection(
                                                      'notification_data')
                                                  .where("notification_status",
                                                      isEqualTo: "[ACTIVE]")
                                                  .where('targeted_user_ids',
                                                      arrayContainsAny: [
                                                        globalCurrentUserDocumentID
                                                      ])
                                                  .get()
                                                  .then((data) async {
                                                    if (data.docs.length == 0) {
                                                      UserAccountUtils
                                                          .updateNotificationAvailableAsFalse(
                                                              globalCurrentUserDocumentID);
                                                    }
                                                  });

                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DashboardPage(
                                                    documentID:
                                                        globalEventDataDocumentID,
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
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
                                        ),
                                      )),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  Container(
                    //Add gradient to background
                    width: MediaQuery.of(context).size.width -
                        MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.width * 0.25,
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container(
            //Add gradient to background
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width -
                MediaQuery.of(context).size.width * 0.15,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xffF3F0E6), Color(0xffFFFFFF)])),
            constraints: BoxConstraints(maxWidth: 600),
            padding:
                EdgeInsets.all(MediaQuery.of(context).size.height * 0.0125),
          );
        }
      },
    );
  }

  settingsModuleFutureBuilderController() async {
    bool isHostAccess = false; // Check host access.
    bool isRequestAccepted = false; // Check requested accept.

    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('event_data')
        .doc(globalEventDataDocumentID)
        .get(); // Get eventData based on current globalEventDataDocumentID.

    if (documentSnapshot['host'].contains(globalCurrentUserDocumentID)) {
      // If documentSnapshot['host'] contains current ID

      isHostAccess = true;
    } else {
      // Otherwise

      isHostAccess = false;
    }

    if (isHostAccess == true) {
      // If no HostAccess, don't need to check the request accept

      // Check if request accepted.
      for (final id in documentSnapshot['participants'].toList()) {
        if (globalCurrentUserDocumentID + " = [GOING]" == id) {
          // Check if globalCurrentUserDocumentID is in the list.
          isRequestAccepted = true;
        }
      }
    }

    if (isHostAccess == true && isRequestAccepted == true) {
      return true;
    } else {
      return false;
    }
  }

  settingsModuleFutureBuilderView() {
    return FutureBuilder(
        future: settingsModuleFutureBuilderController(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == true) {
              return IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EventSettingScreen(
                                eventDocumentID: globalEventDataDocumentID)));
                  },
                  icon: Icon(
                    Icons.settings,
                    color: Colors.black.withOpacity(0.65),
                    size: 36,
                  ));
            } else {
              return Text("");
            }
          } else {
            return Text("");
            // Return nothing

          }
        });
  }

  getInvitedParticipantsProfileFutureBuilderController(
      participantsDocumentIds) async {
    var invitedPeopleProfilePictureURLS = [];

    for (var docID in participantsDocumentIds) {
      String splitDocID = docID.toString().split("=")[0].trim();
      String status = docID
          .toString()
          .split("=")[1]
          .trim(); // Remove the status from id to get the profile url from users table.

      if (status == "[GOING]") {
        if (splitDocID != globalCurrentUserDocumentID) {
          //Skipping current uid

          DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(splitDocID)
              .get();
          invitedPeopleProfilePictureURLS
              .add(documentSnapshot['profile_picture_url']);
        }
      }
    }

    return invitedPeopleProfilePictureURLS;
  }

  getInvitedParticipantsProfileFutureBuilderView(participantsUserIDS) {
    return FutureBuilder(
        future: getInvitedParticipantsProfileFutureBuilderController(
            participantsUserIDS),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            int balanceProfile = snapshot.data.length - 4;

            int howManyProfilePictureToShow = 0;

            if (snapshot.data.length > 4) {
              howManyProfilePictureToShow = 4;
            } else {
              howManyProfilePictureToShow = snapshot.data.length;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0;
                      index < howManyProfilePictureToShow;
                      index++)
                    Padding(
                      padding: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.0125),
                      child: InkWell(
                          onTap: () async {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ParticipantListPage(
                                    eventDocumentID:
                                        globalEventDataDocumentID)));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(5),
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                            child: snapshot.data[index] == "[SKIPPED]"
                                ? Image.asset(
                                    "images/default-profile-picture.png",
                                    fit: BoxFit.cover,
                                    width: 45,
                                    height: 45,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: snapshot.data[index],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                            child: Container(
                                              width: 45,
                                              height: 45,
                                              color: Colors.white,
                                            ),
                                            baseColor: Colors.grey.shade300,
                                            highlightColor:
                                                Colors.grey.shade100),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                    width: 45,
                                    height:
                                        45, // this is the solution for border
                                  ),
                          )),
                    ),
                  if (snapshot.data.length > 4)
                    Text("+ " + balanceProfile.toString())
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(5),
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      child: Shimmer.fromColors(
                          child: Container(
                            width: 160,
                            height: 40,
                            color: Colors.white,
                          ),
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100))
                ],
              ),
            );
          }
        });
  }

  getChatDataFutureBuilderController() async {
    bool isRequestAccepted = false;

    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('event_data')
        .doc(globalEventDataDocumentID)
        .get();

    for (final id in documentSnapshot['participants'].toList()) {
      if (globalCurrentUserDocumentID + " = [GOING]" == id) {
        // Check if globalCurrentUserDocumentID is in the list.
        isRequestAccepted = true;
      } else {
        if (id.toString().split("=")[1].trim() == "[GOING]") {
          // Check the status

          acceptedPeopleUIDList.add(id.toString().split("=")[0].trim());
        }
      }
    }

    return [isRequestAccepted];
  }

  getChatDataFutureBuilderView() {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(15.0),
      topRight: Radius.circular(15.0),
    );

    return FutureBuilder(
        future: getChatDataFutureBuilderController(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data[0] == true) {
              return SlidingUpPanel(
                controller: _panelController,
                parallaxEnabled: true,
                minHeight: MediaQuery.of(context).size.height * 0.1,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                onPanelClosed: () {
                  setState(() {});
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                panel: Container(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.05,
                      right: MediaQuery.of(context).size.width * 0.05),
                  decoration: BoxDecoration(
                      color: Color(0xff3B455C), borderRadius: radius),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: togglePanel,
                          child: Container(
                            margin: EdgeInsets.all(5),
                            color: Color(0xffFF6348),
                            height: 5,
                            width: 40,
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025),
                      Text(
                        "Chat",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xffD8833A),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          controller: _scrollController,
                          child: streamChatData(),
                        ),
                      ),
                    ],
                  ),
                ),
                footer: Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.05,
                      right: MediaQuery.of(context).size.width * 0.05,
                      bottom: MediaQuery.of(context).size.width * 0.025),
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Color(0xffffffff),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                textCapitalization:
                                    TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                minLines: 1,
                                maxLines: 2,
                                cursorColor: Color(0xff595959),
                                controller: messageController,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                  hintText: 'Start typing...',
                                  contentPadding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width *
                                          0.05),
                                  hintStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff555555)),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff595959)),
                                onTap: () {},
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send, color: Color(0xff595959)),
                              onPressed: () async {
                                if (messageController.text != "") {
                                  await uploadChatDataToDatabase();
                                  FocusScope.of(context).unfocus();

                                  final double maxScroll = _scrollController
                                      .position.maxScrollExtent;
                                  _scrollController.animateTo(maxScroll,
                                      duration: Duration(seconds: 1),
                                      curve: Curves.ease);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                collapsed: Container(
                  decoration: BoxDecoration(
                      color: Color(0xff3B455C), borderRadius: radius),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: togglePanel,
                          child: Container(
                            margin: EdgeInsets.all(5),
                            color: Color(0xffFF6348),
                            height: 5,
                            width: 40,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                MediaQuery.of(context).size.width * 0.05,
                                10,
                                MediaQuery.of(context).size.width * 0.05,
                                0),
                            child: Text(
                              "Gathering Chat",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xffD8833A),
                              ),
                            ),
                          ),
                          //messageNotificationFutureBuilderView()
                        ],
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                MediaQuery.of(context).size.width * 0.05,
                                0,
                                MediaQuery.of(context).size.width * 0.05,
                                10),
                            child: Text(
                              "Start your conversation",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xffD8833A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                borderRadius: radius,
              );
            } else {
              return Text("");
            }
          } else {
            return Text("");
            // Return nothing
          }
        });
  }

  Widget returnFirstTimeDashboard() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffFFFFFF),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Container(
        color: Color(0xffFFFFFF),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset("images/marine-debris.png",
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.3),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 50,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.symmetric(vertical: 5),
        alignment: Alignment.center,
        child: SizedBox(
          width: MediaQuery.of(context).size.width -
              MediaQuery.of(context).size.width * 0.2,
          height: 40,
          child: TextButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EventCreationMainScreen()));
            },
            child: Text(
              'CREATE A MOMENT',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                spreadRadius: 0,
                blurRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [secondaryColor, primaryColor])),
      ),
      bottomSheet: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.05)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget returnDashboard() {
    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
              backgroundColor: Color(0xffF3F0E6),
              automaticallyImplyLeading: false,
              elevation: 0,
              actions: [
                settingsModuleFutureBuilderView(),
                Stack(
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => NotificationScreen()));
                        UserAccountUtils.updateNotificationAvailableAsFalse(
                            globalCurrentUserDocumentID);
                      },
                      icon: Icon(
                        Icons.notifications,
                        color: Colors.black.withOpacity(0.65),
                        size: 36,
                      ),
                    ),
                    notificationCheckerStreamer(),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: getUserProfilePictureFutureBuilderView(),
                ),
              ]),
          body: Stack(
            children: [
              Container(
                //Add gradient to background
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xffF3F0E6), Color(0xffFFFFFF)])),
                constraints: BoxConstraints(maxWidth: 600),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    //Create a sidebar container
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width * 0.15,
                    decoration: BoxDecoration(color: Color(0xfff3f0e6)),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.width * 0.1,
                                  width:
                                      MediaQuery.of(context).size.width * 0.1,
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  EventCreationMainScreen()));
                                    },
                                    icon: Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(5),
                                        bottomLeft: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          spreadRadius: 0,
                                          blurRadius: 2,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                      gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            secondaryColor,
                                            primaryColor
                                          ])),
                                ),
                              ],
                            ),
                            Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                width: double.maxFinite,
                                child:
                                    getEventBannerInitialDataStreamBuilderView()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  getEventDataFutureBuilderView(),
                ],
              ),
            ],
          ),
        ));
  }

  void slideSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.1,
            decoration: BoxDecoration(
              color: Color(0xffFFFFFF),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                InkWell(
                  onTap: () async {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.edit,
                        color: Color(0xff595959),
                      ),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Color(0xff595959),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.reply,
                        color: Color(0xff595959),
                      ),
                      Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Color(0xff595959),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.copy,
                        color: Color(0xff595959),
                      ),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Color(0xff595959),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.delete,
                        color: Color(0xffF1454A),
                      ),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Color(0xffF1454A),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class Utils {
  static List<Widget> modelBuilder<M>(
          List<M> models, Widget Function(int index, M model) builder) =>
      models
          .asMap()
          .map<int, Widget>(
              (index, model) => MapEntry(index, builder(index, model)))
          .values
          .toList();

  static void showSheet(
    BuildContext context, {
    required Widget child,
    required VoidCallback onClicked,
  }) =>
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            child,
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Done'),
            onPressed: onClicked,
          ),
        ),
      );
}
