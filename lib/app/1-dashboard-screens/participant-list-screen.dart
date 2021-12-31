import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:debristracker/app/1-dashboard-screens/add-extra-participants-screen.dart';
import 'package:debristracker/app/1-dashboard-screens/contact-access-permission-screen.dart';

String globalEventDataDocumentID = "";
String globalCurrentUserDocumentID = "";

class ParticipantListPage extends StatefulWidget {
  var eventDocumentID;

  ParticipantListPage({Key? key, this.eventDocumentID}) : super(key: key);

  @override
  _ParticipantListPage createState() => _ParticipantListPage(eventDocumentID);
}

class _ParticipantListPage extends State<ParticipantListPage> {
  _ParticipantListPage(eventDocumentID);

  @override
  void initState() {
    globalEventDataDocumentID = widget.eventDocumentID;
    globalCurrentUserDocumentID = UserAccountUtils.getUserDocumentID();
    super.initState();
  }

  getPeopleStatusFutureBuilderController() async {
    String eventName = "";
    var goingPeopleData = [];
    var pendingPeopleData = [];
    var declinedPeopleData = [];

    await FirebaseFirestore.instance
        .collection('event_data')
        .doc(globalEventDataDocumentID)
        .get()
        .then((documentData) async {
      eventName = documentData['event_name'];

      for (final subData in documentData['participants']) {
        String status = subData.toString().split("=")[1].trim();
        String userID = subData.toString().split("=")[0].trim();

        if (status == "[GOING]") {
          if (userID != globalCurrentUserDocumentID) {
            DocumentSnapshot subDocumentData = await FirebaseFirestore.instance
                .collection('users')
                .doc(userID)
                .get();

            goingPeopleData.add(subDocumentData);
          }
        } else if (status == "[PENDING]") {
          DocumentSnapshot subDocumentData = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();
          pendingPeopleData.add(subDocumentData);
        } else if (status == "[DECLINED]") {
          DocumentSnapshot subDocumentData = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();
          declinedPeopleData.add(subDocumentData);
        }
      }
    });

    return [goingPeopleData, pendingPeopleData, declinedPeopleData, eventName];
  }

  getParticipantData() {
    return FutureBuilder(
      future: getPeopleStatusFutureBuilderController(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          var goingPeopleData = snapshot.data[0];
          var pendingPeopleData = snapshot.data[1];
          var declinedPeopleData = snapshot.data[2];
          String eventName = snapshot.data[3];

          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
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
                    Text("Social gathering",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.65))),
                    Text(eventName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1E90FF).withOpacity(0.65))),
                  ],
                ),
                centerTitle: true,
                backgroundColor: Color(0xffF3F0E6),
                bottom: TabBar(
                  tabs: [
                    Tab(
                      child: Text(
                        "going(" + goingPeopleData.length.toString() + ")",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Tab(
                      child: Text(
                        "pending(" + pendingPeopleData.length.toString() + ")",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Tab(
                      child: Text(
                        "declined(" +
                            declinedPeopleData.length.toString() +
                            ")",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  isScrollable: true,
                  indicatorColor: Color(0xff07B1A1),
                  indicatorWeight: 2,
                  unselectedLabelColor: Color(0xffC4C4C4),
                  labelColor: Color(0xff07B1A1),
                  labelStyle:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              body: Container(
                //Add gradient to background
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xffF3F0E6), Color(0xffFFFFFF)])),
                constraints:
                    BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width * 0.05,
                    0,
                    MediaQuery.of(context).size.width * 0.05,
                    0),
                child: TabBarView(
                  children: [
                    Container(
                        child: ListView(
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),
                        for (var index = 0;
                            index < goingPeopleData.length;
                            index++)
                          ListTile(
                            leading: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(10),
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                child: goingPeopleData[index]
                                            ['profile_picture_url'] ==
                                        "[SKIPPED]"
                                    ? Image.asset(
                                        "images/picture3.png",
                                        width: 45,
                                        height: 45,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: goingPeopleData[index]
                                            ['profile_picture_url'],
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
                                      )),
                            title: Text(
                              goingPeopleData[index]['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                      ],
                    )),
                    Container(
                        child: ListView(
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),
                        for (var index = 0;
                            index < pendingPeopleData.length;
                            index++)
                          ListTile(
                            leading: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(10),
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                child: pendingPeopleData[index]
                                            ['profile_picture_url'] ==
                                        "[SKIPPED]"
                                    ? Image.asset(
                                        "images/picture3.png",
                                        width: 45,
                                        height: 45,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: pendingPeopleData[index]
                                            ['profile_picture_url'],
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
                                      )),
                            title: Text(
                              pendingPeopleData[index]['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                      ],
                    )),
                    Container(
                        child: ListView(
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),
                        for (var index = 0;
                            index < declinedPeopleData.length;
                            index++)
                          ListTile(
                            leading: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(10),
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                child: declinedPeopleData[index]
                                            ['profile_picture_url'] ==
                                        "[SKIPPED]"
                                    ? Image.asset(
                                        "images/picture3.png",
                                        width: 45,
                                        height: 45,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: declinedPeopleData[index]
                                            ['profile_picture_url'],
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
                                      )),
                            title: Text(
                              declinedPeopleData[index]['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                      ],
                    ))
                  ],
                ),
              ),
              bottomNavigationBar: BottomAppBar(
                color: Color(0xffFFFFFF),
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.height * 0.025,
                      0,
                      MediaQuery.of(context).size.height * 0.025,
                      MediaQuery.of(context).size.height * 0.08),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 50,
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
                            colors: [secondaryColor, primaryColor])),
                    child: TextButton(
                      // If the done button is clicked, do the following things.
                      onPressed: () async {
                        var status = await Permission.contacts.status;

                        if (status.isGranted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AddExtraParticipantsPage(
                                      eventDocumentID:
                                          globalEventDataDocumentID)));
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ContactAccessPermissionScreen(
                                      eventDocumentID:
                                          globalEventDataDocumentID)));
                        }
                      },
                      child: Text(
                        '+ Invite Friends',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

  final Color fontColor =
      Color(0xff07B1A1); // Define a color for button gradient
  final Color primaryColor =
      Color(0xff04D3A8); // Define a color for button gradient
  final Color secondaryColor = Color(0xff00B7B2);

  @override
  Widget build(BuildContext context) {
    return getParticipantData();
  }
}
