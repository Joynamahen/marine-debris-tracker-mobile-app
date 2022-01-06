import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase auth library for authentication
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart'; // Import material dart file which contains full structure of flutter UI and others.
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker library to implement image picking functionalities.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debristracker/app-utils/firebase-storage-utils.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:path/path.dart';
import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';

String globalCurrentUserCellNumber = "";
String globalUserDocumentID = "";

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
final nameController =
    TextEditingController(); //Create a text-box controller to get the name of the user.
final FirebaseAuth _auth =
    FirebaseAuth.instance; //Create an instance(object) of firebase auth
final FirebaseFirestore _firestore = FirebaseFirestore
    .instance; //Create a firebase store instance(object) to do some firebase databsae things.

final _nameValidationKey = GlobalKey<FormState>();

bool isLoading = false;

//Create a stateful widget.
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPage createState() => _RegistrationPage();
}

class _RegistrationPage extends State<RegistrationPage> {
  void initState() {
    globalCurrentUserCellNumber = UserAccountUtils.getUserPhoneNumber();
    globalUserDocumentID = UserAccountUtils.getUserDocumentID();
    super.initState();
  }

  int nameTextFieldMaxLength = 40; //Max Length of name field
  Color nameFieldUnderlineColor =
      Color(0xff274D6C); // text-field underline color

  final Color fontColor = Color(0xff274D6C); // Define a color button gradient
  final Color primaryColor =
      Color(0xff274D6C); // Define a color button gradient
  final Color secondaryColor =
      Color(0xff00bfff); // Define a color button gradient

  var profileImagePath;

  // Build the widget here.
  @override
  Widget build(BuildContext context) {
    uploadUserProfileInfo(var profilePictureRefPath) async {
      String profilePictureURL = "";

      if (profilePictureRefPath != "") {
        profilePictureURL = await FirebaseStorage.instance
            .ref()
            .child(profilePictureRefPath)
            .getDownloadURL();
      }

      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'name': nameController.text.trim(),
        'phone_number': globalCurrentUserCellNumber,
        'profile_picture_ref_path':
            profilePictureRefPath == "" ? '[SKIPPED]' : profilePictureRefPath,
        'profile_picture_url':
            profilePictureURL == "" ? '[SKIPPED]' : profilePictureURL,
        'is_notification_available': "[FALSE]"
      }, SetOptions(merge: true)).then((value) {
        setState(() {
          isLoading = false;
        });

        profileImagePath = null;
        nameController.clear();
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => DashboardPage()));
      });
    }

    uploadProfilePicture() async {
      final fileName = basename(profileImagePath.toString());
      var fileExtension = extension(fileName).replaceAll("'", "");

      final destination = 'profile-picture/$globalUserDocumentID$fileExtension';

      await FirebaseStorageClass.uploadFile(destination, profileImagePath);

      uploadUserProfileInfo(destination);
    }

    return isLoading == false
        ? Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Color(0xffFFFFFF),
              elevation: 0,
            ),
            body: Form(
              key: _nameValidationKey,
              child: Container(
                color: Color(0xffFFFFFF),
                constraints:
                    BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width * 0.05,
                      0,
                      MediaQuery.of(context).size.width * 0.05,
                      0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Create User Profile",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: Color(0xff595959)),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0125),
                      GestureDetector(
                        child: (profileImagePath == null)
                            ? Icon(
                                Icons.add_photo_alternate,
                                color: fontColor,
                                size: 60,
                              )
                            : Center(
                                child: Image.file(profileImagePath,
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    height: MediaQuery.of(context).size.width *
                                        0.3)),
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery);

                          setState(() {
                            profileImagePath = File(pickedFile!.path);
                          });
                        },
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025),
                      TextFormField(
                        cursorColor: fontColor,
                        maxLength: nameTextFieldMaxLength,
                        controller: nameController,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff595959)),
                        onChanged: (value) {
                          if (value.length == nameTextFieldMaxLength) {
                            setState(() {
                              nameFieldUnderlineColor = Color(0xffff0000);
                            });
                          } else if (value.length ==
                              nameTextFieldMaxLength - 1) {
                            setState(() {
                              nameFieldUnderlineColor = fontColor;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'name',
                          hintStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff595959)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: nameFieldUnderlineColor, width: 2.0),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: nameFieldUnderlineColor, width: 2.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 50,
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
                child: TextButton(
                  // If the done button is clicked, do the following things.
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });

                    if (_nameValidationKey.currentState!.validate()) {
                      if (profileImagePath != null) {
                        uploadProfilePicture();
                      } else {
                        uploadUserProfileInfo("");
                      }
                    }
                  },
                  child: Text(
                    'DONE',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                )),
            bottomSheet: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.1)),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          )
        : Scaffold(
            body: Center(
              child: SpinKitFadingCircle(
                color: Colors.black,
              ),
            ),
          );
  }
}
