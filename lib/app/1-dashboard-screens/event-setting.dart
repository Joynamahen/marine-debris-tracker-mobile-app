import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app-utils/firebase-storage-utils.dart';
import 'package:debristracker/app/1-dashboard-screens/location-search.dart';
import 'package:uuid/uuid.dart';
import 'add-co-host-screen.dart';
import 'dashboard-main-screen.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

final Color fontColor = Color(0xff274D6C); // Define a color button gradient
final Color primaryColor = Color(0xff274D6C); // Define a color button gradient
final Color secondaryColor =
    Color(0xff00bfff); // Define a color button gradient

bool dateTimeAllDaysStatus = false;
bool allowGuestInviteStatus = false;

bool dateTimeAllDaysFirstTimeSelectedStatus = false;

String globalEventDataDocumentID = "";

String startDate = "";
String endDate = "";
String startTime = "";
String endTime = "";

bool isBannerImageUploading = false;
bool isBannerImageUploaded = false;
var bannerImageUploadedURL;

class EventSettingScreen extends StatefulWidget {
  var eventDocumentID;

  EventSettingScreen({Key? key, this.eventDocumentID}) : super(key: key);

  _EventSettingScreen createState() => _EventSettingScreen(eventDocumentID);
}

class _EventSettingScreen extends State<EventSettingScreen> {
  _EventSettingScreen(eventDocumentID);

  @override
  void initState() {
    globalEventDataDocumentID = widget.eventDocumentID;
    super.initState();
  }

  // Date Picker Method
  DateTime dateTime = DateTime.now();

  Widget buildDatePicker() => SizedBox(
        height: 180,
        child: CupertinoDatePicker(
          minimumYear: DateTime.now().year,
          maximumYear: DateTime.now().year + 5,
          initialDateTime: dateTime,
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (dateTime) =>
              setState(() => this.dateTime = dateTime),
        ),
      );

  Widget buildTimePicker() => SizedBox(
        height: 180,
        child: CupertinoDatePicker(
          initialDateTime: dateTime,
          mode: CupertinoDatePickerMode.time,
          use24hFormat: true,
          onDateTimeChanged: (dateTime) =>
              setState(() => this.dateTime = dateTime),
        ),
      );

  getEventDataForEventSettingsFutureBuilderController() async {
    var data;

    await FirebaseFirestore.instance
        .collection('event_data')
        .doc(globalEventDataDocumentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      data = documentSnapshot;
    });

    return data;
  }

  getEventDataForEventSettingsFutureBuilderView() {
    void switchChangerForDateTimeAllDaysStatus(bool value) {
      setState(() {
        dateTimeAllDaysStatus = value;
      });
    }

    void switchChangerForAllowGuestInviteStatus(bool value) {
      setState(() {
        allowGuestInviteStatus = value;
      });
    }

    uploadBannerImageMainFunction(
        String imageRefPath, var localImagePath) async {
      String remoteBannerImageRefPath =
          ""; // Create a variable to store banner_image_ref_path value from database sucj as [SKIPEED] or other string data.

      //Contact the firebase
      await FirebaseFirestore.instance
          .collection('event_data')
          .doc(globalEventDataDocumentID)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        remoteBannerImageRefPath =
            documentSnapshot['banner_image_ref_path']; // Get the data.
      });

      // When starting uploading, we change these parameters.
      setState(() {
        bannerImageUploadedURL = null;
        isBannerImageUploaded = false;
        isBannerImageUploading = true;
      });

      String imageURLPath = ""; // Image URL PATH

      // If remoteBannerImageRefPath is [SKIPPED], We need to delete the previous image.
      if (remoteBannerImageRefPath == '[SKIPPED]') {
        await FirebaseStorageClass()
            .deleteFile(remoteBannerImageRefPath); //Delete banner image.

      }

      final fileName =
          path.basename(localImagePath.toString()); // Only get the basename.
      var fileExtension =
          path.extension(fileName).replaceAll("'", ""); //  Get file extension

      final destination =
          "event-banner/$imageRefPath$fileExtension"; //Define the destination
      await FirebaseStorageClass.uploadFile(
          destination, localImagePath); // Upload image

      final ref =
          FirebaseStorage.instance.ref().child(destination); //Download the url
      await ref.getDownloadURL().then((generatedUrl) {
        imageURLPath = generatedUrl;
      });

      // Update to firestore.
      await FirebaseFirestoreClass.updateDocumentData(
          "event_data", globalEventDataDocumentID, {
        'banner_image_ref_path': destination,
        'banner_image_url': imageURLPath
      });

      // Reset the parameter values.
      setState(() {
        bannerImageUploadedURL = localImagePath;
        isBannerImageUploaded = true;
        isBannerImageUploading = false;
      });
    }

    eventBannerImageUploaderInitialFunction() async {
      var uuid = Uuid();
      String generatedUUID = uuid.v1();

      String bannerImageRefPath = '$generatedUUID-$globalEventDataDocumentID';

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      //We use try and catch to sort out not image selected issue.
      try {
        var bannerImageLocalPath = File(pickedFile!.path);
        await uploadBannerImageMainFunction(
            bannerImageRefPath, bannerImageLocalPath); // Uploading function

      } catch (e) {}
    }

    return FutureBuilder(
      future: getEventDataForEventSettingsFutureBuilderController(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          // If it is a all day event, then gray out the start_time and end_time.
          if (snapshot.data["start_time"] == "[ALLDAY]" &&
              snapshot.data["end_time"] == "[ALLDAY]") {
            // When we switch the all day button, it also run the setState() method, Therefore, We need to make sure this block of code once.
            if (dateTimeAllDaysFirstTimeSelectedStatus == false) {
              // To fix before widget loading issue
              SchedulerBinding.instance!.addPostFrameCallback((_) {
                switchChangerForDateTimeAllDaysStatus(true); // Switch to true
                dateTimeAllDaysFirstTimeSelectedStatus =
                    true; // Make it as true to not to run again when setState() calls.
              });
            }
          }

          return SingleChildScrollView(
            child: Container(
              //Add gradient to background
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
              padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width * 0.05,
                  0,
                  MediaQuery.of(context).size.width * 0.05,
                  0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.025,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {},
                        child: Stack(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(
                                  left: 0, top: 0, right: 0, bottom: 5),
                              child: InkWell(
                                  onTap: () {
                                    eventBannerImageUploaderInitialFunction();
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(34),
                                    child: isBannerImageUploaded == false
                                        ? isBannerImageUploading == false
                                            ? snapshot.data[
                                                        "banner_image_url"] ==
                                                    "[SKIPPED]"
                                                ? Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.25,
                                                    color: Colors.white,
                                                    child: Image.asset(
                                                      "images/default-event-banner-image.png",
                                                    ),
                                                  )
                                                : CachedNetworkImage(
                                                    imageUrl: snapshot.data[
                                                        'banner_image_url'],
                                                    fit: BoxFit.cover,
                                                    placeholder: (context,
                                                            url) =>
                                                        Shimmer.fromColors(
                                                            child: Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.4,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.25,
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            34),
                                                                boxShadow: <
                                                                    BoxShadow>[
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .grey
                                                                        .withOpacity(
                                                                            0.5), //color of shadow
                                                                    spreadRadius:
                                                                        1, //spread radius
                                                                    blurRadius:
                                                                        3, // blur radius
                                                                    offset:
                                                                        Offset(
                                                                            0,
                                                                            2),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            baseColor: Colors
                                                                .grey.shade300,
                                                            highlightColor:
                                                                Colors.grey
                                                                    .shade100),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(Icons.error),
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.25,
                                                    // this is the solution for border
                                                  )
                                            : Shimmer.fromColors(
                                                child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.25,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              34),
                                                      boxShadow: <BoxShadow>[
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(
                                                                  0.5), //color of shadow
                                                          spreadRadius:
                                                              1, //spread radius
                                                          blurRadius:
                                                              3, // blur radius
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                    )),
                                                baseColor: Colors.grey.shade300,
                                                highlightColor:
                                                    Colors.grey.shade100)
                                        : Image.file(
                                            bannerImageUploadedURL,
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.4,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.25,
                                          ),
                                  )),
                            ),
                            new Positioned(
                              right: 0,
                              bottom: 0,
                              child: new Container(
                                decoration: new BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Color(0xffC4C4C4),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: 40,
                                  maxHeight: 40,
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    eventBannerImageUploaderInitialFunction();
                                  },
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.black.withOpacity(0.65),
                                    size: 25,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Moment Name',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: fontColor),
                  ),
                  TextFormField(
                    controller: TextEditingController()
                      ..text = snapshot.data["event_name"],
                    cursorColor: Color(0xffC4C4C4),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.65)),
                    onChanged: (value) {
                      if (value != "") {
                        FirebaseFirestore.instance
                            .collection('event_data')
                            .doc(globalEventDataDocumentID)
                            .update({'event_name': value});
                      } else {
                        // If they try empty the name, it will update the previous name.
                        FirebaseFirestore.instance
                            .collection('event_data')
                            .doc(globalEventDataDocumentID)
                            .update(
                                {'event_name': snapshot.data["event_name"]});
                      }
                    },
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.65)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xffC4C4C4), width: 2.0),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xffC4C4C4), width: 2.0),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.025,
                  ),
                  Text(
                    'date & time',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: fontColor),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "All day",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff595959)),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.025,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Transform.scale(
                                scale: 1.5,
                                child: Switch.adaptive(
                                  activeColor: Color(0xfffffff),
                                  activeTrackColor: Color(0xff07B1A1),
                                  inactiveThumbColor: Color(0xffffffff),
                                  inactiveTrackColor: Color(0xffC4C4C4),
                                  value: dateTimeAllDaysStatus,
                                  onChanged: (bool value) {
                                    if (dateTimeAllDaysStatus == false) {
                                      // Update as full day event, if it has start_date and end_date
                                      if (snapshot.data['start_date'] !=
                                              "[SKIPPED]" &&
                                          snapshot.data['end_date'] !=
                                              "[SKIPPED]") {
                                        FirebaseFirestore.instance
                                            .collection('event_data')
                                            .doc(globalEventDataDocumentID)
                                            .update({
                                          'start_time': '[ALLDAY]',
                                          'end_time': '[ALLDAY]'
                                        });
                                      }

                                      switchChangerForDateTimeAllDaysStatus(
                                          true);
                                    } else {
                                      switchChangerForDateTimeAllDaysStatus(
                                          false);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.0125,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "start date",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff274D6C)),
                              ),
                              InkWell(
                                onTap: () {
                                  Utils.showSheet(
                                    context,
                                    child: buildDatePicker(),
                                    onClicked: () {
                                      final valueOfStartDate =
                                          DateFormat('EEEE, MMMM d, y')
                                              .format(dateTime);

                                      FirebaseFirestore.instance
                                          .collection('event_data')
                                          .doc(globalEventDataDocumentID)
                                          .update(
                                              {'start_date': valueOfStartDate});

                                      setState(() {
                                        startDate = valueOfStartDate;
                                      });

                                      Navigator.pop(context);
                                    },
                                  );
                                },
                                child: snapshot.data['start_date'] !=
                                        '[SKIPPED]'
                                    ? Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.05,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(34)),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: Color(0xffC4C4C4),
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
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(snapshot.data['start_date'],
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xffffffff)))
                                          ],
                                        ))
                                    : Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.05,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.all(Radius.circular(34)),
                                            color: Color(0xffC4C4C4)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text("select now",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xffffffff)))
                                          ],
                                        )),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.025,
                              ),
                              Text(
                                "end date",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff274D6C)),
                              ),
                              InkWell(
                                  onTap: () {
                                    Utils.showSheet(
                                      context,
                                      child: buildDatePicker(),
                                      onClicked: () {
                                        final valueOfEndDate =
                                            DateFormat('EEEE, MMMM d, y')
                                                .format(dateTime);

                                        FirebaseFirestore.instance
                                            .collection('event_data')
                                            .doc(globalEventDataDocumentID)
                                            .update(
                                                {'end_date': valueOfEndDate});

                                        setState(() {
                                          endDate = valueOfEndDate;
                                        });

                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                  child: snapshot.data['end_date'] !=
                                          '[SKIPPED]'
                                      ? Container(
                                          width: MediaQuery.of(context).size.width *
                                              0.5,
                                          height:
                                              MediaQuery.of(context).size.height *
                                                  0.05,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(34)),
                                              boxShadow: <BoxShadow>[
                                                BoxShadow(
                                                  color: Color(0xffC4C4C4),
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
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(snapshot.data['end_date'],
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xffffffff)))
                                            ],
                                          ))
                                      : Container(
                                          width: MediaQuery.of(context).size.width *
                                              0.5,
                                          height:
                                              MediaQuery.of(context).size.height *
                                                  0.05,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.all(Radius.circular(34)),
                                              color: Color(0xffC4C4C4)),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text("select now",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xffffffff)))
                                            ],
                                          ))),
                            ],
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.025,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "time (optional)",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff274D6C)),
                              ),
                              InkWell(
                                  onTap: () {
                                    if (dateTimeAllDaysStatus == false) {
                                      Utils.showSheet(
                                        context,
                                        child: buildTimePicker(),
                                        onClicked: () {
                                          final valueOfStartTime =
                                              DateFormat('HH:mm')
                                                  .format(dateTime);

                                          FirebaseFirestore.instance
                                              .collection('event_data')
                                              .doc(globalEventDataDocumentID)
                                              .update({
                                            'start_time': valueOfStartTime
                                          });

                                          setState(() {
                                            startTime = valueOfStartTime;
                                          });

                                          Navigator.pop(context);
                                        },
                                      );
                                    }
                                  },
                                  child: dateTimeAllDaysStatus == false
                                      ? Container(
                                          width:
                                              MediaQuery.of(context).size.width *
                                                  0.2,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.05,
                                          decoration: snapshot.data['start_time'] !=
                                                  '[SKIPPED]'
                                              ? BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(34)),
                                                  boxShadow: <BoxShadow>[
                                                    BoxShadow(
                                                      color: Color(0xffC4C4C4),
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
                                                      ]))
                                              : BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(34)),
                                                  color: Color(0xffC4C4C4),
                                                ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              snapshot.data['start_time'] !=
                                                      '[SKIPPED]'
                                                  ? snapshot.data['start_time'] ==
                                                          '[ALLDAY]'
                                                      ? dateTimeAllDaysStatus ==
                                                              true
                                                          ? Text("")
                                                          : Text("select",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: Color(
                                                                      0xffffffff)))
                                                      : Text(snapshot.data['start_time'],
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Color(
                                                                  0xffffffff)))
                                                  : Text("select",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                              0xffffffff))),
                                            ],
                                          ))
                                      : Container(
                                          width:
                                              MediaQuery.of(context).size.width *
                                                  0.2,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.05,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(34)),
                                            color: Color(0xffC4C4C4),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [Text("")],
                                          ))),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.025,
                              ),
                              Text(
                                "time (optional)",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff274D6C)),
                              ),
                              InkWell(
                                  onTap: () {
                                    if (dateTimeAllDaysStatus == false) {
                                      Utils.showSheet(
                                        context,
                                        child: buildTimePicker(),
                                        onClicked: () {
                                          final valueOfEndTime =
                                              DateFormat('HH:mm')
                                                  .format(dateTime);

                                          FirebaseFirestore.instance
                                              .collection('event_data')
                                              .doc(globalEventDataDocumentID)
                                              .update(
                                                  {'end_time': valueOfEndTime});

                                          setState(() {
                                            endTime = valueOfEndTime;
                                          });

                                          Navigator.pop(context);
                                        },
                                      );
                                    }
                                  },
                                  child: dateTimeAllDaysStatus == false
                                      ? Container(
                                          width:
                                              MediaQuery.of(context).size.width *
                                                  0.2,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.05,
                                          decoration: snapshot.data['end_time'] !=
                                                  '[SKIPPED]'
                                              ? BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(34)),
                                                  boxShadow: <BoxShadow>[
                                                    BoxShadow(
                                                      color: Color(0xffC4C4C4),
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
                                                      ]))
                                              : BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(34)),
                                                  color: Color(0xffC4C4C4),
                                                ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              snapshot.data['end_time'] !=
                                                      '[SKIPPED]'
                                                  ? snapshot.data['end_time'] ==
                                                          '[ALLDAY]'
                                                      ? dateTimeAllDaysStatus ==
                                                              true
                                                          ? Text("")
                                                          : Text("select",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: Color(
                                                                      0xffffffff)))
                                                      : Text(
                                                          snapshot
                                                              .data['end_time'],
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Color(
                                                                  0xffffffff)))
                                                  : Text("select",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xffffffff))),
                                            ],
                                          ))
                                      : Container(
                                          width:
                                              MediaQuery.of(context).size.width *
                                                  0.2,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.05,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(34)),
                                            color: Color(0xffC4C4C4),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [Text("")],
                                          ))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.025,
                  ),
                  Text(
                    'Moment description',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: fontColor),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.multiline,
                    initialValue: snapshot.data['event_intro'] != "[SKIPPED]"
                        ? snapshot.data['event_intro']
                        : "",
                    minLines: 1,
                    maxLines: 3,
                    cursorColor: Color(0xffC4C4C4),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withOpacity(0.65)),
                    onChanged: (value) {
                      FirebaseFirestore.instance
                          .collection('event_data')
                          .doc(globalEventDataDocumentID)
                          .update({'event_intro': value});
                    },
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black.withOpacity(0.65)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xffC4C4C4), width: 2.0),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xffC4C4C4), width: 2.0),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.025,
                  ),
                  Text(
                    "location",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: fontColor,
                    ),
                  ),
                  snapshot.data['location'] == "[SKIPPED]"
                      ? Text(
                          "no location selected yet. set location now",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withOpacity(0.65)),
                        )
                      : InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SearchLocation(
                                          eventDocumentID:
                                              widget.eventDocumentID,
                                        )));
                          },
                          child: Text(
                            snapshot.data['location'],
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black.withOpacity(0.65)),
                          )),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.0125,
                  ),
                  if (snapshot.data['location'] == "[SKIPPED]")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            height: 30,
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
                                    colors: [secondaryColor, primaryColor])),
                            child: TextButton(
                              // If the done button is clicked, do the following things.
                              onPressed: () async {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => SearchLocation(
                                              eventDocumentID:
                                                  widget.eventDocumentID,
                                            )));
                              },
                              child: Text(
                                'Add Location',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            )),
                      ],
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.025,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Divider(),
                      TextButton(
                        onPressed: () {
                          slideSheet();
                        },
                        child: const Text(
                          "Delete Moment",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color(0xffF1454A),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Divider(),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return Shimmer.fromColors(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.white,
              ),
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.navigate_before,
              size: 30, color: Color(0xff595959)),
          onPressed: () {
            clearVariableValues();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DashboardPage(documentID: globalEventDataDocumentID),
              ),
            );
          },
        ),
        title: Column(
          children: [
            Text("Moment Settings",
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
      body: getEventDataForEventSettingsFutureBuilderView(),
    );
  }

  void slideSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              children: [
                Container(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  height: MediaQuery.of(context).size.height * 0.1,
                  decoration: BoxDecoration(
                    color: Color(0xff3B455C),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Are you sure that you want to delete your moment?',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Color(0xffD8833A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.15,
                  decoration: BoxDecoration(
                    color: Color(0xffFFFFFF),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Spacer(flex: 2),
                      InkWell(
                        onTap: () async {
                          Navigator.of(context).pop();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.undo,
                              color: Color(0xff274D6C),
                            ),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Color(0xff274D6C),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(flex: 2),
                      VerticalDivider(
                        color: Color(0xffC4C4C4),
                        thickness: 2,
                      ),
                      Spacer(flex: 1),
                      InkWell(
                        onTap: () async {
                          await FirebaseFirestoreClass.updateDocumentData(
                              "event_data",
                              globalEventDataDocumentID,
                              {'event_status': "[INACTIVE]"});
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DashboardPage()));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.delete,
                              color: Color(0xffC4C4C4),
                            ),
                            Text(
                              'Delete anyways',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Color(0xffC4C4C4),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(flex: 1),
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

clearVariableValues() {
  dateTimeAllDaysStatus = false;
  allowGuestInviteStatus = false;
  dateTimeAllDaysFirstTimeSelectedStatus = false;

  startDate = "";
  endDate = "";
  startTime = "";
  endTime = "";

  isBannerImageUploaded = false;
  isBannerImageUploading = false;
  bannerImageUploadedURL = null;
}
