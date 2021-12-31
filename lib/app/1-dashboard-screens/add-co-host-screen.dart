import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';

final Color fontColor = Color(0xff07B1A1);
final Color buttonColor =
    Color(0xff04D3A8); // Define a color for button gradient
final Color primaryColor =
    Color(0xff04D3A8); // Define a color for button gradient
final Color secondaryColor =
    Color(0xff00B7B2); // Define a color for button gradient

var hostList = [];

String globalEventDataDocumentID = "";
String globalCurrentUserDocumentID = "";

class AddCoHostPage extends StatefulWidget {
  var eventDocumentID;

  AddCoHostPage({Key? key, this.eventDocumentID}) : super(key: key);

  @override
  _AddCoHostPageState createState() => _AddCoHostPageState(eventDocumentID);
}

class _AddCoHostPageState extends State<AddCoHostPage> {
  _AddCoHostPageState(eventDocumentID);

  @override
  void initState() {
    globalEventDataDocumentID = widget.eventDocumentID;
    globalCurrentUserDocumentID = UserAccountUtils.getUserDocumentID();
    hostList.clear();
    super.initState();
  }

  getHostDetailsFutureBuilderController(String documentID) async {
    var hostListProfileUrl = [];

    String creatorID = "";

    await FirebaseFirestore.instance
        .collection('event_data')
        .doc(documentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) async {
      creatorID = documentSnapshot['event_creator'];

      for (var hostID in documentSnapshot['host']) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(hostID)
            .get()
            .then((DocumentSnapshot documentSnapshot) {
          hostListProfileUrl.add([
            documentSnapshot['profile_picture_url'],
            documentSnapshot['name'],
            hostID,
            creatorID
          ]);
        });

        if (hostList.contains(hostID) == false) {
          hostList.add(hostID);
        }
      }
    });

    return hostListProfileUrl;
  }

  getHostDetailsFutureBuilderView(String documentID) {
    return FutureBuilder(
      future: getHostDetailsFutureBuilderController(documentID),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              for (var index = 0; index < snapshot.data.length; index++)
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(5),
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    child: snapshot.data[index][0] != '[SKIPPED]'
                        ? CachedNetworkImage(
                            imageUrl: snapshot.data[index][0],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.white,
                                ),
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                            width: 40,
                            height: 40, // this is the solution for border
                          )
                        : Image.asset(
                            "images/picture3.png",
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40, // this is the solution for border
                          ),
                  ),
                  title: Text(
                    snapshot.data[index][1],
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  trailing: globalCurrentUserDocumentID ==
                              snapshot.data[index][3] ||
                          globalCurrentUserDocumentID == snapshot.data[index][2]
                      ? globalCurrentUserDocumentID ==
                                  snapshot.data[index][3] &&
                              globalCurrentUserDocumentID ==
                                  snapshot.data[index][2]
                          ? Container(
                              width: MediaQuery.of(context).size.width * 0.25,
                              height: MediaQuery.of(context).size.width * 0.08,
                              alignment: Alignment.center,
                              child: SizedBox(
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text('Remove',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xffC4C4C4),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(34)),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0xff04D3A8),
                                    spreadRadius: 0,
                                    blurRadius: 2,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ), // Apply gradient to the button
                            )
                          : Container(
                              width: MediaQuery.of(context).size.width * 0.25,
                              height: MediaQuery.of(context).size.width * 0.08,
                              alignment: Alignment.center,
                              child: SizedBox(
                                child: TextButton(
                                  onPressed: () async {
                                    // Allows to remove all except Creator
                                    if (globalCurrentUserDocumentID ==
                                        snapshot.data[index][3]) {
                                      // Current creator ID matches with event creator ID (Removing ability).

                                      if (globalCurrentUserDocumentID !=
                                          snapshot.data[index][2]) {
                                        // Current creator ID does match with host ID from the list. This means, current ID is not same from host list, so we can remove other id.

                                        if (hostList.contains(
                                                snapshot.data[index][2]) ==
                                            true) {
                                          // If it has, remove it.
                                          hostList
                                              .remove(snapshot.data[index][2]);
                                        }

                                        await FirebaseFirestoreClass
                                            .updateDocumentData(
                                                'event_data',
                                                globalEventDataDocumentID,
                                                {'host': hostList});

                                        setState(() {});
                                      }
                                    } else {
                                      // Self remove, But NOT apply for creator

                                      if (globalCurrentUserDocumentID ==
                                          snapshot.data[index][2]) {
                                        // If current user ID match with id in the host list, they can remove themselves.

                                        if (hostList.contains(
                                                snapshot.data[index][2]) ==
                                            true) {
                                          // If it has, remove it.
                                          hostList
                                              .remove(snapshot.data[index][2]);
                                        }

                                        await FirebaseFirestoreClass
                                            .updateDocumentData(
                                                'event_data',
                                                globalEventDataDocumentID,
                                                {'host': hostList});

                                        setState(() {});
                                      }
                                    }
                                  },
                                  child: Text('Remove',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ),
                              ),
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(34)),
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
                            )
                      : Container(
                          width: MediaQuery.of(context).size.width * 0.25,
                          height: MediaQuery.of(context).size.width * 0.08,
                          alignment: Alignment.center,
                          child: SizedBox(
                            child: TextButton(
                              onPressed: () {},
                              child: Text('Remove',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xffC4C4C4),
                            borderRadius: BorderRadius.all(Radius.circular(34)),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Color(0xff04D3A8),
                                spreadRadius: 0,
                                blurRadius: 2,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ), // Apply gradient to the button
                        ),
                )
            ],
          );
        } else {
          return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(15),
              ),
              child: Shimmer.fromColors(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 4,
                    color: Colors.white,
                  ),
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100));
        }
      },
    );
  }

  getParticipantDetailsFutureBuilderController(String documentID) async {
    var participantsListProfileUrl = [];
    var tempHostList = [];

    await FirebaseFirestore.instance
        .collection('event_data')
        .doc(documentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) async {
      for (var host in documentSnapshot['host']) {
        tempHostList.add(host);
      }

      for (var participant in documentSnapshot['participants']) {
        String splitDocID = participant.toString().split("=")[0].trim();
        String status = participant.toString().split("=")[1].trim();
        String creatorID = documentSnapshot['event_creator'];

        if (tempHostList.contains(splitDocID) != true) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(splitDocID)
              .get()
              .then((documentSnapshot) {
            participantsListProfileUrl.add([
              documentSnapshot['profile_picture_url'],
              documentSnapshot['name'],
              splitDocID,
              creatorID
            ]);
          });
        }
      }
    });

    return participantsListProfileUrl;
  }

  getParticipantDetailsFutureBuilderView(String documentID) {
    return FutureBuilder(
      future: getParticipantDetailsFutureBuilderController(documentID),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              for (var index = 0; index < snapshot.data.length; index++)
                ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: snapshot.data[index][0],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                            child: Container(
                              width: 45,
                              height: 45,
                              color: Colors.white,
                            ),
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        width: 45,
                        height: 45, // this is the solution for border
                      ),
                    ),
                    title: Text(
                      snapshot.data[index][1],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    trailing: globalCurrentUserDocumentID ==
                            snapshot.data[index][3]
                        ? Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            height: MediaQuery.of(context).size.width * 0.08,
                            alignment: Alignment.center,
                            child: SizedBox(
                              child: TextButton(
                                onPressed: () async {
                                  if (globalCurrentUserDocumentID ==
                                      snapshot.data[index][3]) {
                                    // Only Creator can add co-hosts.

                                    if (hostList.contains(
                                            snapshot.data[index][2]) ==
                                        false) {
                                      hostList.add(snapshot.data[index][2]);
                                    }

                                    await FirebaseFirestoreClass
                                        .updateDocumentData(
                                            'event_data',
                                            globalEventDataDocumentID,
                                            {'host': hostList});

                                    setState(() {});
                                  }
                                },
                                child: Text('ADD',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(34)),
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
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            height: MediaQuery.of(context).size.width * 0.08,
                            alignment: Alignment.center,
                            child: SizedBox(
                              child: TextButton(
                                onPressed: () {},
                                child: Text('Add',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xffC4C4C4),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(34)),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Color(0xff04D3A8),
                                  spreadRadius: 0,
                                  blurRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ), // Apply gradient to the button
                          ))
            ],
          );
        } else {
          return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(15),
              ),
              child: Shimmer.fromColors(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 4,
                    color: Colors.white,
                  ),
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return contactWithoutSearchOption();
  }

  Widget contactWithoutSearchOption() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Color(0xffF3F0E6),
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
            Text("Add co-host",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.65))),
          ],
        ),
        centerTitle: true,
      ),
      //Scaffold widget will expand or occupy the whole device screen.
      body: Container(
        //Add gradient to background
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xffF3F0E6), Color(0xffFFFFFF)])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Divider(
              thickness: 1, // thickness of the line
              color: Colors.black26, // The color to use when painting the line.
              height: 20, // The divider's height extent.
            ),
            getHostDetailsFutureBuilderView(globalEventDataDocumentID),
            const Divider(
              thickness: 1, // thickness of the line
              color: Colors.black26, // The color to use when painting the line.
              height: 20, // The divider's height extent.
            ),
            getParticipantDetailsFutureBuilderView(globalEventDataDocumentID),
          ],
        ),
      ),
    );
  }
}
