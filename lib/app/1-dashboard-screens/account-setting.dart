import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app-utils/firebase-storage-utils.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';
import '../../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

String profileUrl = "";

String globalUserCellNumber = "";
String globalUserDocumentID = "";

bool isProfileImageUploading = false;
bool isProfileImageUploaded = false;
var profileImageUploadedURL;

class AccountSettingScreen extends StatefulWidget {
  const AccountSettingScreen({Key? key}) : super(key: key);

  @override
  _AccountSettingScreen createState() => _AccountSettingScreen();
}

class _AccountSettingScreen extends State<AccountSettingScreen> {
  @override
  void initState() {
    globalUserCellNumber = UserAccountUtils.getUserPhoneNumber();
    globalUserDocumentID = UserAccountUtils.getUserDocumentID();
    super.initState();
  }

  uploadProfileImageMainFunction(
      String imageRefPath, var localImagePath) async {
    String remoteProfileImageRefPath =
        ""; // Create a variable to store Profile_image_ref_path value from database sucj as [SKIPEED] or other string data.

    //Contact the firebase
    await FirebaseFirestore.instance
        .collection('users')
        .doc(globalUserDocumentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      remoteProfileImageRefPath =
          documentSnapshot['profile_picture_ref_path']; // Get the data.
    });

    // When starting uploading, we change these parameters.
    setState(() {
      profileImageUploadedURL = null;
      isProfileImageUploaded = false;
      isProfileImageUploading = true;
    });

    String imageURLPath = ""; // Image URL PATH

    // If remoteProfileImageRefPath is [SKIPPED], We need to delete the previous image.
    if (remoteProfileImageRefPath == '[SKIPPED]') {
      await FirebaseStorageClass()
          .deleteFile(remoteProfileImageRefPath); //Delete Profile image.
    }

    final fileName =
        path.basename(localImagePath.toString()); // Only get the basename.
    var fileExtension =
        path.extension(fileName).replaceAll("'", ""); //  Get file extension

    final destination =
        "profile-picture/$imageRefPath$fileExtension"; //Define the destination
    await FirebaseStorageClass.uploadFile(
        destination, localImagePath); // Upload image

    final ref =
        FirebaseStorage.instance.ref().child(destination); //Download the url
    await ref.getDownloadURL().then((generatedUrl) {
      imageURLPath = generatedUrl;
    });

    // Update to firestore.
    await FirebaseFirestoreClass.updateDocumentData(
        "users", globalUserDocumentID, {
      'profile_picture_ref_path': destination,
      'profile_picture_url': imageURLPath
    });

    // Reset the parameter values.
    setState(() {
      profileImageUploadedURL = localImagePath;
      isProfileImageUploaded = true;
      isProfileImageUploading = false;
    });
  }

  eventProfileImageUploaderInitialFunction() async {
    String profileImageRefPath = '$globalUserDocumentID';

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    //We use try and catch to sort out not image selected issue.
    try {
      var profileImageLocalPath = File(pickedFile!.path);
      await uploadProfileImageMainFunction(
          profileImageRefPath, profileImageLocalPath); // Uploading function

    } catch (e) {}
  }

  getUserAccountDataForAccountSettingsFutureBuilderController() async {
    var data;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(globalUserDocumentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      data = documentSnapshot;
    });

    return data;
  }

  getUserAccountDataForAccountSettingsFutureBuilderView() {
    return FutureBuilder(
      future: getUserAccountDataForAccountSettingsFutureBuilderController(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Stack(
            children: [
              Container(
                //Add gradient to background
                height: MediaQuery.of(context).size.height,
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
                    InkWell(
                      onTap: () async {
                        eventProfileImageUploaderInitialFunction();
                      },
                      child: Stack(
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(
                                left: 0,
                                top: 0,
                                right:
                                    MediaQuery.of(context).size.width * 0.025,
                                bottom:
                                    MediaQuery.of(context).size.width * 0.025),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(5),
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                              child: isProfileImageUploaded == false
                                  ? isProfileImageUploading == false
                                      ? snapshot.data['profile_picture_url'] !=
                                              '[SKIPPED]'
                                          ? CachedNetworkImage(
                                              imageUrl: snapshot
                                                  .data['profile_picture_url'],

                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Shimmer.fromColors(
                                                      child: Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.3,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.3,
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
                                                  0.3,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3, // this is the solution for border
                                            )
                                          : Image.asset(
                                              "images/picture3.png",
                                              fit: BoxFit.cover,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3, // this is the solution for border
                                            )
                                      : Shimmer.fromColors(
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                            color: Colors.white,
                                          ),
                                          baseColor: Colors.grey.shade300,
                                          highlightColor: Colors.grey.shade100)
                                  : Image.file(
                                      profileImageUploadedURL,
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.3,
                                    ),
                            ),
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
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.black.withOpacity(0.65),
                                size: 25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.025,
                    ),
                    Text(
                      'Name',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xffC4C4C4)),
                    ),
                    TextFormField(
                      initialValue: snapshot.data['name'],
                      cursorColor: Color(0xffC4C4C4),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.65)),
                      onChanged: (value) {
                        if (value != "") {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(globalUserDocumentID)
                              .update({'name': value});
                        } else {
                          // If they try empty the name, it will update the previous name.
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(globalUserDocumentID)
                              .update({'name': snapshot.data["name"]});
                        }
                      },
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xffC4C4C4)),
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
                      'Phone',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xffC4C4C4)),
                    ),
                    TextFormField(
                      initialValue: snapshot.data['phone_number'],
                      cursorColor: Color(0xffC4C4C4),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.65)),
                      onChanged: (value) {
                        if (value != "") {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(globalUserDocumentID)
                              .update({'phone_number': value});
                        } else {
                          // If they try empty the name, it will update the previous name.
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(globalUserDocumentID)
                              .update({
                            'phone_number': snapshot.data['phone_number']
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xffC4C4C4)),
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
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Divider(),
                        TextButton(
                          onPressed: () {
                            final FirebaseAuth _auth = FirebaseAuth
                                .instance; // Create Firebase Auth instance
                            _auth.signOut().then((value) =>
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            MainHomePage())));
                          },
                          child: const Text(
                            "Log Out",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Color(0xffF1454A),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Divider(),
                        TextButton(
                          onPressed: () {
                            slideSheet();
                          },
                          child: const Text(
                            "Delete Account",
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
            ],
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

  final Color fontColor =
      Color(0xff07B1A1); // Define a color for button gradient
  final Color primaryColor =
      Color(0xff04D3A8); // Define a color for button gradient
  final Color secondaryColor =
      Color(0xff00B7B2); // Define a color for button gradient

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                builder: (context) => DashboardPage(),
              ),
            );
          },
        ),
        title: Column(
          children: [
            Text("ACCOUNT",
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
      body: getUserAccountDataForAccountSettingsFutureBuilderView(),
    );
  }

  deleteUserData() {
    //FirebaseFirestore.instance.collection('users').doc(globalUserDocumentID).collection("event_data").doc(globalEventDataDocumentID).delete().then((_) => Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardPage())));
  }

  void slideSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              children: [
                Container(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  height: MediaQuery.of(context).size.height * 0.15,
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
                        'Are you sure that you want to delete your account?',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Color(0xffD8833A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'We won’t be able to resore your account afterwards.',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Color(0xffD8833A),
                          fontWeight: FontWeight.w400,
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
                        onTap: () async {},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.undo,
                              color: Color(0xff07B1A1),
                            ),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Color(0xff07B1A1),
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
                          deleteUserData();
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

clearVariableValues() {
  isProfileImageUploaded = false;
  isProfileImageUploading = false;
  profileImageUploadedURL = null;
}
