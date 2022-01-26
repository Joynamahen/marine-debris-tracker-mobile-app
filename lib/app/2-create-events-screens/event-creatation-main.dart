import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_place/google_place.dart';
import 'package:path/path.dart' as path;
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:debristracker/app-utils/common-utils.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app-utils/firebase-storage-utils.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class EventCreationMainScreen extends StatefulWidget {
  const EventCreationMainScreen({Key? key}) : super(key: key);

  @override
  _EventCreationMainScreenState createState() =>
      _EventCreationMainScreenState();
}

String address = "";
String globalCurrentUserCellNumber = "";
String globalCurrentUserDocumentID = "";

String screenState = "NameScreen";
bool isLoadingDataEntering = false;

var bannerImageLocalPath;
String bannerImageRefPath = "";
String bannerImageURL = "";

String startDate = "";
String endDate = "";
String startTime = "";
String endTime = "";

String deepLink = "";
String eventCustomDocumentID = "";

final eventNameController = TextEditingController();
final eventIntroController = TextEditingController();
final bottleCountController = TextEditingController();
final bagCountController = TextEditingController();
final containerCountController = TextEditingController();
final otherCountController = TextEditingController();

final Color fontColor = Color(0xff274D6C); // Define a color button gradient
final Color primaryColor = Color(0xff274D6C); // Define a color button gradient
final Color secondaryColor =
    Color(0xff00bfff); // Define a color button gradient

final FirebaseAuth _auth =
    FirebaseAuth.instance; //Create an instance(object) of firebase auth

var hostList = [];
var addedParticipantsList = [];
var invitedViaSMSParticipantsList = [];
final Map<String, String> alreadyRegisteredUsersList = {};

List<Contact> contacts = [];
List<Contact> contactsFiltered = [];

bool isGetAllContactsExecuted = false;

Map<String, Color> contactsColorMap = new Map();
TextEditingController contactSearchController = new TextEditingController();

bool dateTimeAllDaysStatus = false;

deeplinkURLMaker(String eventID, String eventName, String bannerImageURL,
    String startDate, String endDate, String startTime, String endTime) async {
  String localBannerURl = "";

  if (bannerImageURL == "") {
    localBannerURl = '[SKIPPED]';
  } else {
    localBannerURl = bannerImageURL;
  }

  String baseDataInsertionURL =
      "https://joinsingsing.com/insert-deeplink-data.php";

  // Encode Banner Image URL
  String encodedURL = CommonUtils.encodeURL(localBannerURl);

  // Get username & replace empty space with %20
  String nameOfInvitor = await UserAccountUtils.getCurrentUserUsername();
  nameOfInvitor = nameOfInvitor.replaceAll(" ", "%20");

  // Replace start&end time's space with %20
  String localStartDate = startDate.replaceAll(" ", "%20");
  String localEndDate = endDate.replaceAll(" ", "%20");

  String dataInsertionLink =
      "$baseDataInsertionURL?event_id=$eventID&event_name=$eventName&invitor_name=$nameOfInvitor&start_date=$localStartDate&end_date=$localEndDate&start_time=$startTime&end_time=$endTime&banner_url=$encodedURL";

  return dataInsertionLink;
}

getNextFriday() {
  // Define a day number and day name in a map.
  Map<String, int> dayWithNumber = {
    "Monday": 1,
    "Tuesday": 2,
    "Wednesday": 3,
    "Thursday": 4,
    "Friday": 5,
    "Saturday": 6,
    "Sunday": 7
  };

  final DateTime now = DateTime.now(); // Date object
  final DateFormat formatter =
      DateFormat('EEEE, MMMM dd, yyyy'); // Define the format of the date
  final String currentDate =
      formatter.format(now); // Get current date Ex: Wednesday, October 13, 2021

  var splitDateList = currentDate.split(" ");

  String dayName = splitDateList[0].replaceAll(",", "").trim();
  String monthName = splitDateList[1].replaceAll(",", "").trim();
  int dateNo = int.parse(splitDateList[2]
      .replaceAll(",", "")
      .trim()); // Convert the string date into number to do calculation.
  String year = splitDateList[3].replaceAll(",", "").trim();

  int? numberOfTheGivenDayFromTheList =
      dayWithNumber[dayName]; // Get the number of the current day from the map.

  int additionalIncrementMove = 5 -
      numberOfTheGivenDayFromTheList!; // Subtract the current number of the day from the number of friday (5) to get the number of movement that we need to make.

  if (additionalIncrementMove == -1) {
    // If it is Saturday, it should increment by 6

    dateNo = dateNo + 6;
  } else if (additionalIncrementMove == -2) {
    // If it is Sunday, it should increment by 5

    dateNo = dateNo + 5;
  } else {
    // Otherwise increment by additionalIncrementMove.

    dateNo = dateNo + additionalIncrementMove;
  }

  startDate = "";
  endDate = "";
  startTime = "";
  endTime = "";
}

class _EventCreationMainScreenState extends State<EventCreationMainScreen> {
  Future<void> createDynamicLink() async {
    DocumentReference ref = FirebaseFirestore.instance
        .collection("event_data")
        .doc(); // Get the next docID
    eventCustomDocumentID = ref.id;

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://joinsingsing.page.link',
      link: Uri.parse(
          'https://joinsingsing.com/deeplink-page.php?event_id=$eventCustomDocumentID'),
      androidParameters: AndroidParameters(
        fallbackUrl: Uri.parse(
            'https://joinsingsing.com/deeplink-page.php?event_id=$eventCustomDocumentID'),
        packageName: 'com.example.singsing',
        minimumVersion: 21,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        fallbackUrl: Uri.parse(
            'https://joinsingsing.com/deeplink-page.php?event_id=$eventCustomDocumentID'),
        ipadFallbackUrl: Uri.parse(
            'https://joinsingsing.com/deeplink-page.php?event_id=$eventCustomDocumentID'),
        bundleId: 'com.google.FirebaseCppDynamicLinksTestApp.dev',
        minimumVersion: '0',
      ),
    );

    final ShortDynamicLink shortLink = await parameters.buildShortLink();
    Uri url = shortLink.shortUrl;

    setState(() {
      deepLink = url.toString();
    });
  }

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];

  void initState() {
    String apiKey = 'AIzaSyBYCNGrqhdsJallpPo-S27tUV-lb-CFpEg';
    googlePlace = GooglePlace(apiKey);

    getNextFriday();
    createDynamicLink();
    getAlreadyRegisteredUsers();
    getPermissions();
    globalCurrentUserCellNumber = UserAccountUtils.getUserPhoneNumber();
    globalCurrentUserDocumentID = UserAccountUtils.getUserDocumentID();

    super.initState();
  }

  getPermissions() async {
    var status = await Permission.contacts.status;
    if (status.isGranted) {
      getAllContacts();
      contactSearchController.addListener(() {
        filterContacts();
      });
    }
  }

  getAlreadyRegisteredUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        alreadyRegisteredUsersList[doc["phone_number"]] = doc.id;
      });
    });
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  getAllContacts() async {
    List colors = [Colors.green, Colors.indigo, Colors.yellow, Colors.orange];
    int colorIndex = 0;
    List<Contact> _contacts = (await ContactsService.getContacts()).toList();

    List<Contact> registeredUserContacts = [];
    List<Contact> nonRegisteredUserContacts = [];

    _contacts.forEach((contact) {
      if (contact.phones!.isNotEmpty) {
        if (alreadyRegisteredUsersList.containsKey(contact.phones!
            .elementAt(0)
            .value
            .toString()
            .replaceAll(' ', ''))) {
          registeredUserContacts.add(contact);
        } else {
          nonRegisteredUserContacts.add(contact);
        }
      }

      Color baseColor = colors[colorIndex];
      contactsColorMap[contact.displayName.toString()] = baseColor;
      colorIndex++;
      if (colorIndex == colors.length) {
        colorIndex = 0;
      }
    });

    setState(() {
      contacts = registeredUserContacts + nonRegisteredUserContacts;
      isGetAllContactsExecuted = true;
    });
  }

  filterContacts() {
    List<Contact> _contacts = [];
    _contacts.addAll(contacts);
    if (contactSearchController.text.isNotEmpty) {
      _contacts.retainWhere((contact) {
        String searchTerm = contactSearchController.text.toLowerCase();
        String searchTermFlatten = flattenPhoneNumber(searchTerm);
        String contactName = contact.displayName!.toLowerCase();
        bool nameMatches = contactName.contains(searchTerm);
        if (nameMatches == true) {
          return true;
        }

        if (searchTermFlatten.isEmpty) {
          return false;
        }

        var phone = contact.phones!.firstWhere((phn) {
          String phnFlattened = flattenPhoneNumber(phn.value.toString());
          return phnFlattened.contains(searchTermFlatten);
        }, orElse: () => null as Item);

        return phone != null;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  void _sendSMS(String message, String phoneNumber) async {
    String _result = await sendSMS(message: message, recipients: [phoneNumber])
        .catchError((onError) {
      print(onError);
    });
  }

  inviteButtonStateFunction(phoneNumber) {
    var userDocumentID = alreadyRegisteredUsersList[phoneNumber];

    for (var docID in addedParticipantsList) {
      docID = docID.split("=")[0].toString().trim();

      if (docID == userDocumentID) {
        if (alreadyRegisteredUsersList.containsValue(userDocumentID)) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.25,
            height: MediaQuery.of(context).size.width * 0.08,
            alignment: Alignment.center,
            child: Text('SENT',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),

            decoration: BoxDecoration(
              color: Color(0xffC4C4C4),
              borderRadius: BorderRadius.all(Radius.circular(15)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0xff274D6C),
                  spreadRadius: 0,
                  blurRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ), // Apply gradient to the button
          );
        }
      }
    }

    for (var phone in invitedViaSMSParticipantsList) {
      if (phone == phoneNumber) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.25,
          height: MediaQuery.of(context).size.width * 0.08,
          alignment: Alignment.center,
          child: Text('INVITED',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),

          decoration: BoxDecoration(
            color: Color(0xffC4C4C4),
            borderRadius: BorderRadius.all(Radius.circular(15)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0xff04D3A8),
                spreadRadius: 0,
                blurRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ), // Apply gradient to the button
        );
      }
    }

    if (alreadyRegisteredUsersList.containsValue(userDocumentID)) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.width * 0.08,
        alignment: Alignment.center,

        child: SizedBox(
          child: Text('ADD',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
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
                colors: [
                  secondaryColor,
                  primaryColor
                ])), // Apply gradient to the button
      );
    } else {
      return Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.width * 0.08,
        alignment: Alignment.center,

        child: Text('INVITE',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white)),

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
                colors: [
                  secondaryColor,
                  primaryColor
                ])), // Apply gradient to the button
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (screenState == "NameScreen") {
      nameScreen();
    } else if (screenState == "PermissionForContactScreen") {
      return permissionForContactScreen();
    } else if (screenState == "DeniedContactAccessScreen") {
      return deniedContactAccessScreen();
    } else if (screenState == "ContactScreen") {
      return contactScreen();
    } else if (screenState == "DateChosenScreen") {
      return dateChosenScreen();
    } else if (screenState == "AddLocationScreen") {
      return addLocationScreen();
    } else if (screenState == "AddDebrisDataScreen") {
      return addDebrisDataScreen();
    } else if (screenState == "AddBannerScreen") {
      return addBannerScreen();
    } else if (screenState == "EventIntroScreen") {
      return eventIntroScreen();
    }

    return nameScreen();
  }

  final _formKey = GlobalKey<FormState>();

  int nameTextFieldMaxLength = 60; //Max Length of name field
  Color nameFieldUnderlineColor =
      Color(0xff07B1A1); // text-field underline color

  Widget nameScreen() {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xffFFFFFF),
          elevation: 0,
          leading: TextButton(
            onPressed: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              await Future.delayed(const Duration(milliseconds: 200), () {});
              clearVariableValues();
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => DashboardPage()));
            },
            child: const Text(
              "X",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 22.0,
                color: Color(0xff274D6C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            color: Color(0xffFFFFFF),
            padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.05,
                right: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  "Moment Name",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xff595959)),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                TextFormField(
                  cursorColor: fontColor,
                  controller: eventNameController,
                  style: TextStyle(fontSize: 25),
                  maxLength: nameTextFieldMaxLength,
                  onChanged: (value) {
                    if (value.length == nameTextFieldMaxLength) {
                      setState(() {
                        nameFieldUnderlineColor = Color(0xffff0000);
                      });
                    } else if (value.length == nameTextFieldMaxLength - 1) {
                      setState(() {
                        nameFieldUnderlineColor = fontColor;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Moment Name',
                    hintStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff595959)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: fontColor, width: 2.0),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: fontColor, width: 2.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          child: Container(
              margin: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width * 0.05,
                  0,
                  MediaQuery.of(context).size.width * 0.05,
                  MediaQuery.of(context).size.height * 0.05),
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
                  var status = await Permission.contacts.status;

                  if (status.isGranted) {
                    //Validate eventNameController (Required)
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        screenState = "ContactScreen";
                      });
                    }
                  } else {
                    setState(() {
                      screenState = "PermissionForContactScreen";
                    });
                  }
                },
                child: Text(
                  'NEXT',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              )),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget permissionForContactScreen() {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        backgroundColor: Color(0xffFFFFFF),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            setState(() {
              screenState = "DeniedContactAccessScreen";
            });
          },
          child: const Text(
            "SKIP",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18.0,
              color: Color(0xff274D6C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.white,
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Add A Collaborator",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff595959)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            Padding(
              padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Sync contacts to see which of your friends",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff595959)),
              ),
            ),
            Image.asset(
                //Add image from asset
                "images/right-wrong.png", //Image source
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.5),
          ])),
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
              if (await Permission.contacts.request().isGranted) {
                getAlreadyRegisteredUsers();
                getPermissions();

                setState(() {
                  screenState = "ContactScreen";
                });
              } else {
                setState(() {
                  screenState = "DeniedContactAccessScreen";
                });
              }
            },
            child: Text(
              'ALLOW ACCESS TO CONTACTS',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          )),
      bottomSheet: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget deniedContactAccessScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffFFFFFF),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            setState(() {
              screenState = "NameScreen";
            });
          },
          child: const Text(
            "<<",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22.0,
              color: Color(0xff274D6C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: Container(
        //Add gradient to background
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width * 0.05,
                  0,
                  MediaQuery.of(context).size.width * 0.05,
                  0),
              child: Text(
                "Allow contact access",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff595959)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
            Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: TextButton(
                      onPressed: () {
                        openAppSettings();
                      },
                      child: Text("Turn on contact permission on settings",
                          style: TextStyle(
                              color: fontColor, fontWeight: FontWeight.bold))),
                )),
          ],
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
            onPressed: () {
              setState(() {
                screenState = "DateChosenScreen";
              });
            },
            child: Text(
              'NEXT',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          )),
      bottomSheet: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.05)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget contactScreen() {
    bool isSearching = contactSearchController.text.isNotEmpty;
    bool listItemsExist = (contactsFiltered.length > 0 || contacts.length > 0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Color(0xffFFFFFF),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            setState(() {
              screenState = "NameScreen";
            });
          },
          child: const Text(
            "<<",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22.0,
              color: Color(0xff274D6C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      //Scaffold widget will expand or occupy the whole device screen.
      body: Container(
        //Add gradient to background
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width * 0.05,
                  0,
                  MediaQuery.of(context).size.width * 0.05,
                  0),
              child: Text(
                "Add collaborators",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.03,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff595959)),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.025,
            ),
            Container(
              height: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).size.height * 0.2,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    listItemsExist == true
                        ? isSearching == true && contactsFiltered.length == 0
                            ? Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.10),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: isSearching == true
                                    ? contactsFiltered.length
                                    : contacts.length,
                                itemBuilder: (context, index) {
                                  Contact contact = isSearching == true
                                      ? contactsFiltered[index]
                                      : contacts[index];

                                  var baseColor =
                                      contactsColorMap[contact.displayName]
                                          as dynamic;

                                  Color color1 = baseColor;
                                  Color color2 = baseColor;
                                  return ListTile(
                                    visualDensity: VisualDensity(
                                        horizontal: 0, vertical: -4),
                                    title: Text(contact.displayName.toString()),
                                    subtitle: Text(contact.phones!.length > 0
                                        ? contact.phones!
                                            .elementAt(0)
                                            .value
                                            .toString()
                                        : ''),
                                    leading: Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                                colors: [
                                                  color1,
                                                  color2,
                                                ],
                                                begin: Alignment.bottomLeft,
                                                end: Alignment.topRight)),
                                        child: CircleAvatar(
                                            child: Text(contact.initials(),
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            backgroundColor:
                                                Colors.transparent)),
                                    trailing: InkWell(
                                      onTap: () {
                                        // Main Contact

                                        var currentNumber = contact.phones!
                                            .elementAt(0)
                                            .value
                                            .toString()
                                            .replaceAll(' ', '');
                                        var userDocumentID =
                                            alreadyRegisteredUsersList[
                                                currentNumber];

                                        if (addedParticipantsList.contains(
                                            userDocumentID.toString() +
                                                " = [PENDING]")) {
                                          setState(() {
                                            addedParticipantsList.remove(
                                                userDocumentID.toString() +
                                                    " = [PENDING]");
                                          });
                                        } else {
                                          if (alreadyRegisteredUsersList
                                              .containsValue(userDocumentID)) {
                                            setState(() {
                                              addedParticipantsList.add(
                                                  userDocumentID.toString() +
                                                      " = [PENDING]");
                                            });
                                          } else {
                                            String currentPhoneNumber = contact
                                                .phones!
                                                .elementAt(0)
                                                .value
                                                .toString()
                                                .replaceAll(' ', '');

                                            setState(() {
                                              if (invitedViaSMSParticipantsList
                                                  .contains(
                                                      currentPhoneNumber)) {
                                                invitedViaSMSParticipantsList
                                                    .remove(currentPhoneNumber);
                                              } else {
                                                invitedViaSMSParticipantsList
                                                    .add(currentPhoneNumber);
                                              }
                                            });

                                            _sendSMS(
                                                "Hey, join my social event on SingSing $deepLink",
                                                currentNumber);
                                          }
                                        }
                                      },
                                      child: inviteButtonStateFunction(contact
                                          .phones!
                                          .elementAt(0)
                                          .value
                                          .toString()
                                          .replaceAll(' ', '')),
                                    ),
                                  );
                                },
                              )
                        : isGetAllContactsExecuted == false
                            ? Center(
                                child: Padding(
                                    padding: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.10),
                                    child: SpinKitFadingCircle(
                                      color: Colors.black,
                                    )),
                              )
                            : Center(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.width *
                                          0.10),
                                  child: Column(
                                    children: [
                                      Text('No contacts found',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline6),
                                      Icon(
                                        Icons.warning_amber,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.30,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ],
                ),
              ),
            )
          ],
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
          onPressed: () {
            getNextFriday(); // Run the getNextFriday function to assign default value automatically.

            setState(() {
              screenState = "DateChosenScreen";
            });
          },
          child: Text(
            'NEXT',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
      bottomSheet: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.05)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
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

  Widget dateChosenScreen() {
    final Color fontColor = Color(0xff274D6C); // Define a color button gradient
    final Color primaryColor =
        Color(0xff274D6C); // Define a color button gradient
    final Color secondaryColor =
        Color(0xff00bfff); // Define a color button gradient

    final formKey = GlobalKey<FormState>();

    void _onChanged(bool value) {
      setState(() {
        dateTimeAllDaysStatus = value;
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffFFFFFF),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            setState(() {
              screenState = "ContactScreen";
            });
          },
          child: const Text(
            "<<",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22.0,
              color: Color(0xff595959),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: Container(
        //Add gradient to background
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Color(0xffFFFFFF),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Text(
                  "Add Date & Time",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff595959)),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.025,
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(37)),
                    color: Color(0xffffffff),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0xffC4C4C4),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Column(
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
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Column(
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
                                        _onChanged(true);
                                      } else {
                                        _onChanged(false);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                            final value =
                                                DateFormat('EEEE, MMMM d, y')
                                                    .format(dateTime);

                                            setState(() {
                                              startDate = value;
                                            });

                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                      child: startDate == ""
                                          ? Container(
                                              width: MediaQuery.of(context).size.width *
                                                  0.5,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.05,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(15)),
                                                  color: Color(0xffc4c4c4)),
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
                                                          color: Color(
                                                              0xffffffff)))
                                                ],
                                              ))
                                          : Container(
                                              width:
                                                  MediaQuery.of(context).size.width *
                                                      0.5,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.05,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(15)),
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
                                                  Text(startDate,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                              0xffffffff)))
                                                ],
                                              )),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                                final value =
                                                    DateFormat('HH:mm')
                                                        .format(dateTime);

                                                setState(() {
                                                  startTime = value;
                                                });

                                                Navigator.pop(context);
                                              },
                                            );
                                          }
                                        },
                                        child: dateTimeAllDaysStatus == true ||
                                                startTime == ""
                                            ? Container(
                                                width: MediaQuery.of(context).size.width *
                                                    0.2,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.all(
                                                        Radius.circular(15)),
                                                    color: Color(0xffc4c4c4)),
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      if (dateTimeAllDaysStatus ==
                                                          false)
                                                        Text("select",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xffffffff)))
                                                    ]))
                                            : Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                height: MediaQuery.of(context).size.height * 0.05,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                    boxShadow: <BoxShadow>[
                                                      BoxShadow(
                                                        color:
                                                            Color(0xffC4C4C4),
                                                        spreadRadius: 0,
                                                        blurRadius: 2,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ],
                                                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [secondaryColor, primaryColor])),
                                                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                                  if (dateTimeAllDaysStatus ==
                                                      false)
                                                    Text(startTime,
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                0xffffffff)))
                                                ]))),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.0125,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
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
                                            final value =
                                                DateFormat('EEEE, MMMM d, y')
                                                    .format(dateTime);

                                            setState(() {
                                              endDate = value;
                                            });

                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                      child: endDate == ""
                                          ? Container(
                                              width: MediaQuery.of(context).size.width *
                                                  0.5,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.05,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(15)),
                                                  color: Color(0xffc4c4c4)),
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
                                                          color: Color(
                                                              0xffffffff)))
                                                ],
                                              ))
                                          : Container(
                                              width:
                                                  MediaQuery.of(context).size.width *
                                                      0.5,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.05,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(15)),
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
                                                  Text(endDate,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                              0xffffffff)))
                                                ],
                                              )),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                                final value =
                                                    DateFormat('HH:mm')
                                                        .format(dateTime);

                                                setState(() {
                                                  endTime = value;
                                                });

                                                Navigator.pop(context);
                                              },
                                            );
                                          }
                                        },
                                        child: dateTimeAllDaysStatus == true ||
                                                endTime == ""
                                            ? Container(
                                                width: MediaQuery.of(context).size.width *
                                                    0.2,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.all(
                                                        Radius.circular(15)),
                                                    color: Color(0xffc4c4c4)),
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      if (dateTimeAllDaysStatus ==
                                                          false)
                                                        Text("select",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xffffffff)))
                                                    ]))
                                            : Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                height: MediaQuery.of(context).size.height * 0.05,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                    boxShadow: <BoxShadow>[
                                                      BoxShadow(
                                                        color:
                                                            Color(0xffC4C4C4),
                                                        spreadRadius: 0,
                                                        blurRadius: 2,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ],
                                                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [secondaryColor, primaryColor])),
                                                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                                  if (dateTimeAllDaysStatus ==
                                                      false)
                                                    Text(endTime,
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                0xffffffff)))
                                                ]))),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.025),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
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
                          screenState = "AddLocationScreen";
                        });
                      },
                      child: Text(
                        'NEXT',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget addLocationScreen() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: TextButton(
          onPressed: () async {
            setState(() {
              screenState = "DateChosenScreen";
            });
          },
          child: const Text(
            "<<",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22.0,
              color: Color(0xff595959),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        backgroundColor: Color(0xffFFFFFF),
      ),
      body: Container(
        //Add gradient to background
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add location",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 24.0,
                color: Color(0xff595959),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.0125,
            ),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xff3B455C),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.05,
                child: TextField(
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      autoCompleteSearch(value);
                    } else {
                      if (predictions.length > 0 && mounted) {
                        setState(() {
                          predictions = [];
                        });
                      }
                    }
                  },
                  textAlignVertical: TextAlignVertical.top,
                  textAlign: TextAlign.start,
                  cursorColor: Color(0xffC4C4C4),
                  style: TextStyle(fontSize: 12, color: Color(0xffC4C4C4)),
                  decoration: InputDecoration(
                    hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xffC4C4C4)),
                    filled: true,
                    hintText: 'Search location',
                    prefixIcon: Icon(Icons.search, color: Color(0xffC4C4C4)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xff00B7B2),
                      child: Icon(
                        Icons.pin_drop,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(predictions[index].description.toString(),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff595959))),
                    onTap: () {
                      geDetails(predictions[index].placeId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: Container(
            margin: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.05,
                0,
                MediaQuery.of(context).size.width * 0.05,
                MediaQuery.of(context).size.height * 0.05),
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
                  screenState = "AddDebrisDataScreen";
                });
              },
              child: Text(
                'NEXT',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            )),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void geDetails(var placeId) async {
    var result = await this.googlePlace.details.get(placeId);
    if (result != null && result.result != null && mounted) {
      address = result.result!.formattedAddress.toString();
    }
  }

  void autoCompleteSearch(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  Widget addDebrisDataScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffFFFFFF),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            setState(() {
              screenState = "AddLocationScreen";
            });
          },
          child: const Text(
            "<<",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22.0,
              color: Color(0xff274D6C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      //Scaffold widget will expand or occupy the whole device screen.
      body: Container(
        padding: EdgeInsets.all(20),
        //Add gradient to background
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: MediaQuery.of(context).size.width * 0.35,
                  width: MediaQuery.of(context).size.width * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    color: Color(0xffffffff),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0xffC4C4C4),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(10),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "images/bottle.png",
                          width: MediaQuery.of(context).size.width * 0.075,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0125,
                        ),
                        Text(
                          "Plastic Bottles",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Color(0xff595959),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextFormField(
                          cursorColor: fontColor,
                          controller: bottleCountController,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                          onChanged: (value) {},
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.width * 0.35,
                  width: MediaQuery.of(context).size.width * 0.3,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    color: Color(0xffffffff),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0xffC4C4C4),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "images/plastic-glass.png",
                          width: MediaQuery.of(context).size.width * 0.075,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0125,
                        ),
                        Text(
                          "Containers",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Color(0xff595959),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextFormField(
                          cursorColor: fontColor,
                          controller: containerCountController,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                          onChanged: (value) {},
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: MediaQuery.of(context).size.width * 0.35,
                  width: MediaQuery.of(context).size.width * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    color: Color(0xffffffff),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0xffC4C4C4),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(10),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "images/bag.png",
                          width: MediaQuery.of(context).size.width * 0.075,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0125,
                        ),
                        Text(
                          "Polythene Bags",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Color(0xff595959),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextFormField(
                          cursorColor: fontColor,
                          controller: bagCountController,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                          onChanged: (value) {},
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.width * 0.35,
                  width: MediaQuery.of(context).size.width * 0.3,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    color: Color(0xffffffff),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0xffC4C4C4),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "images/other.png",
                          width: MediaQuery.of(context).size.width * 0.075,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0125,
                        ),
                        Text(
                          "Other Plastics",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Color(0xff595959),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextFormField(
                          cursorColor: fontColor,
                          controller: otherCountController,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                          onChanged: (value) {},
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: fontColor, width: 2.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: Container(
            margin: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.05,
                0,
                MediaQuery.of(context).size.width * 0.05,
                MediaQuery.of(context).size.height * 0.05),
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
                  screenState = "AddBannerScreen";
                });
              },
              child: Text(
                'NEXT',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            )),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget addBannerScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffFFFFFF),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            setState(() {
              screenState = "AddDebrisDataScreen";
            });
          },
          child: const Text(
            "<<",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22.0,
              color: Color(0xff274D6C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      //Scaffold widget will expand or occupy the whole device screen.
      body: Container(
        //Add gradient to background
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.025,
                  right: MediaQuery.of(context).size.width * 0.025),
              child: Text(
                "Add A Image",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff595959)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    slideSheet();
                  },
                  child: Center(
                    child: Stack(
                      children: [
                        (bannerImageLocalPath == null)
                            ? Icon(
                                Icons.add_photo_alternate,
                                color: fontColor,
                                size: 100,
                              )
                            : Stack(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(30),
                                    ),
                                    child: Image.file(
                                      bannerImageLocalPath,
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width *
                                          0.9,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
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
                      screenState = "EventIntroScreen";
                    });
                  },
                  child: Text(
                    'NEXT',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                )),
          ],
        ),
      ),
      bottomSheet: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void slideSheet() {
    eventImagePictureNameAndPathGenerationFunction() async {
      var uuid = Uuid();
      String generatedUUID = uuid.v1();

      bannerImageRefPath = '$generatedUUID-$globalCurrentUserDocumentID';

      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);

      setState(() {
        bannerImageLocalPath = File(pickedFile!.path);
      });
    }

    eventCameraImagePictureNameAndPathGenerationFunction() async {
      var uuid = Uuid();
      String generatedUUID = uuid.v1();

      bannerImageRefPath = '$generatedUUID-$globalCurrentUserDocumentID';

      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 20);

      setState(() {
        bannerImageLocalPath = File(pickedFile!.path);
      });
    }

    showModalBottomSheet(
        backgroundColor: Color(0xff3B455C).withOpacity(0),
        context: context,
        builder: (context) {
          return bannerImageLocalPath == null
              ? Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.375),
                  margin:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
                  decoration: BoxDecoration(
                    color: Color(0xff3B455C),
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 0,
                        color: Color(0xff3B455C),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context, true);
                            eventCameraImagePictureNameAndPathGenerationFunction();
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera,
                                  color: Color(0xffffffff)),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.025),
                              Text(
                                "Take a photo",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffffffff)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                      Card(
                        elevation: 0,
                        color: Color(0xff3B455C),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context, true);
                            eventImagePictureNameAndPathGenerationFunction();
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: Color(0xffffffff)),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.025),
                              Text(
                                "Choose from gallery",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffffffff)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                      Card(
                        elevation: 0,
                        color: Color(0xff3B455C),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context, true);
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: Color(0xffffffff)),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.025),
                              Text(
                                "Cancel",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffffffff)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.475),
                  margin:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
                  decoration: BoxDecoration(
                    color: Color(0xff3B455C),
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 0,
                        color: Color(0xff3B455C),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context, true);
                            setState(() {
                              bannerImageLocalPath = null;
                            });
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Color(0xffCD5C5C)),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.025),
                              Text(
                                "Delete",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffCD5C5C)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                      Card(
                        elevation: 0,
                        color: Color(0xff3B455C),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context, true);
                            eventCameraImagePictureNameAndPathGenerationFunction();
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera,
                                  color: Color(0xffffffff)),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.025),
                              Text(
                                "Take a photo",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffffffff)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                      Card(
                        elevation: 0,
                        color: Color(0xff3B455C),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context, true);
                            eventImagePictureNameAndPathGenerationFunction();
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: Color(0xffffffff)),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.025),
                              Text(
                                "Choose from gallery",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffffffff)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                      Card(
                        elevation: 0,
                        color: Color(0xff3B455C),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context, true);
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: Color(0xffffffff)),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.025),
                              Text(
                                "Cancel",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffffffff)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
        });
  }

  Color introFieldUnderlineColor =
      Color(0xff07B1A1); // text-field underline color

  Widget eventIntroScreen() {
    uploadNotificationData(String notificationNamePara, var targetedUserList,
        String customNotificationID) async {
      var splitTargetedUserIDS = [];

      for (final id in targetedUserList) {
        List<String> idParts = id.split("=");
        splitTargetedUserIDS.add(idParts[0].trim());
      }

      splitTargetedUserIDS.remove(
          globalCurrentUserDocumentID); // Remove globalCurrentUserDocumentID to avoid sending notification to current user.

      String notificationCategory = "[EVENT_REQUEST]";
      String notificationName = notificationNamePara;
      String notificationMessage = "invited you to join the event";
      String notificationDate = DateFormat('MM/dd/yyyy').format(DateTime.now());
      String notificationTime =
          DateFormat('hh:mm aa"').format(DateTime.now()).replaceAll("'", "");

      Map<String, dynamic> notificationData = {
        "notification_id": customNotificationID,
        "notification_category": notificationCategory,
        "notification_name": notificationName,
        "notification_message": notificationMessage,
        "notification_date": notificationDate,
        "notification_time": notificationTime,
        "main_user": globalCurrentUserDocumentID,
        "targeted_user_ids": splitTargetedUserIDS,
        "notification_banner_image":
            bannerImageURL == "" ? '[SKIPPED]' : bannerImageURL,
        "notification_event_id": eventCustomDocumentID,
        "notification_status": '[ACTIVE]'
      };

      UserAccountUtils.updateNotificationAvailableAsTrue(
          splitTargetedUserIDS); // Change isNotificationAvailableAsTrue
      await FirebaseFirestoreClass.insertNotificationData(
          notificationData,
          "notification_data",
          customNotificationID); // Insert notification data
    }

    uploadDeeplinkDataToJoinSingSingWebPage(String createdURL) async {
      var url = Uri.parse(createdURL);
      var response = await http.post(url);
    }

    Future uploadEventBannerPicture(var imagePath, var imageName) async {
      final fileName = path.basename(imagePath.toString());
      var fileExtension = path.extension(fileName).replaceAll("'", "");

      final destination = "event-banner/$imageName$fileExtension";

      bannerImageRefPath = destination;

      await FirebaseStorageClass.uploadFile(destination, imagePath);

      return "finished";
    }

    Future getUrlOfBannerImage(imageName) async {
      final ref = FirebaseStorage.instance.ref().child(imageName);
      await ref.getDownloadURL().then((value) {
        bannerImageURL = value;
      });
    }

    uploadEventDataToDatabase() async {
      hostList.add(alreadyRegisteredUsersList[globalCurrentUserCellNumber]);
      addedParticipantsList.add(
          alreadyRegisteredUsersList[globalCurrentUserCellNumber].toString() +
              " = [GOING]");

      if (bannerImageLocalPath != null && bannerImageRefPath != "") {
        await uploadEventBannerPicture(
            bannerImageLocalPath, bannerImageRefPath);
        await getUrlOfBannerImage(bannerImageRefPath);
      }

      if (dateTimeAllDaysStatus == true) {
        startTime = "[ALLDAY]";
        endTime = "[ALLDAY]";
      }

      var startDateAndTime;

      var monthsNamesAndIndex = {
        "January": 1,
        "February": 2,
        "March": 3,
        "April": 4,
        "May": 5,
        "June": 6,
        "July": 7,
        "August": 8,
        "September": 9,
        "October": 10,
        "November": 11,
        "December": 12
      };

      if (startDate != "") {
        String month =
            monthsNamesAndIndex[startDate.toString().split(" ")[1].trim()]
                .toString();
        String date =
            startDate.toString().split(" ")[2].trim().replaceAll(",", "");
        String year = startDate.toString().split(" ")[3].trim();

        String hour = "";
        String min = "";

        if (startTime != "") {
          hour = startTime.toString().split(":")[0].trim();
          min = startTime.toString().split(":")[1].trim();
        } else {
          hour = "00";
          min = "00";
        }

        if (int.parse(date) < 10) {
          date = "0" + date;
        }

        String datetime =
            year + "-" + month + "-" + date + " " + hour + ":" + min;
        print(datetime);
        startDateAndTime = DateTime.parse(datetime);
      }

      if (startDateAndTime == null) {
        startDateAndTime = DateTime.parse("1970-00-00 00:00");
      }

      DocumentReference ref = FirebaseFirestore.instance
          .collection("notification_Data")
          .doc(); // Get the next docID

      String customNotificationDocumentID = ref.id;

      Map<String, dynamic> eventData = {
        "event_id": eventCustomDocumentID,
        "event_name": eventNameController.text,
        "location": address == "" ? '[SKIPPED]' : address,
        "participants": addedParticipantsList,
        "start_date": startDate == "" ? '[SKIPPED]' : startDate,
        "end_date": endDate == "" ? '[SKIPPED]' : endDate,
        "start_time": startTime == "" ? '[SKIPPED]' : startTime,
        "end_time": endTime == "" ? '[SKIPPED]' : endTime,
        "banner_image_ref_path":
            bannerImageRefPath == "" ? '[SKIPPED]' : bannerImageRefPath,
        "banner_image_url": bannerImageURL == "" ? '[SKIPPED]' : bannerImageURL,
        "bottle_count": bottleCountController.text,
        "bag_count": bagCountController.text,
        "container_count": containerCountController.text,
        "other_count": otherCountController.text,
        "event_intro": eventIntroController.text == ""
            ? '[SKIPPED]'
            : eventIntroController.text,
        "deeplink_url": deepLink,
        "host": hostList,
        "start_date_time": startDateAndTime,
        "event_creator": globalCurrentUserDocumentID,
        "notification_id": customNotificationDocumentID,
        "target_message_notification_uids": [],
        "guest_as_host": '[FALSE]',
        "event_status": '[ACTIVE]'
      };

      String deeplinkDataInsertionLink = await deeplinkURLMaker(
          eventCustomDocumentID,
          eventNameController.text,
          bannerImageURL,
          startDate,
          endDate,
          startTime,
          endTime);
      uploadDeeplinkDataToJoinSingSingWebPage(deeplinkDataInsertionLink);

      await uploadNotificationData(eventNameController.text,
          addedParticipantsList, customNotificationDocumentID);
      var status =
          await FirebaseFirestoreClass.insertMapDataWithCustomDocumentID(
              eventData, "event_data", eventCustomDocumentID);

      return status;
    }

    return isLoadingDataEntering == false
        ? Scaffold(
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            appBar: AppBar(
              backgroundColor: Color(0xffFFFFFF),
              elevation: 0,
              leading: TextButton(
                onPressed: () {
                  setState(() {
                    screenState = "AddBannerScreen";
                  });
                },
                child: const Text(
                  "<<",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 22.0,
                    color: Color(0xff274D6C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Container(
                //Add gradient to background
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                color: Color(0xffFFFFFF),
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.025,
                    right: MediaQuery.of(context).size.width * 0.025),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      "Description",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff595959)),
                    ),
                    TextFormField(
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 3,
                      cursorColor: fontColor,
                      controller: eventIntroController,
                      style: TextStyle(fontSize: 25),
                      onChanged: (value) {},
                      decoration: InputDecoration(
                        hintText: 'Description',
                        hintMaxLines: 2,
                        hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff595959)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: fontColor, width: 2.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: fontColor, width: 2.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              elevation: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      margin: EdgeInsets.fromLTRB(
                          0, 0, 0, MediaQuery.of(context).size.height * 0.05),
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
                            isLoadingDataEntering = true;
                          });

                          String storeEventCustomDocumentIDLocally =
                              eventCustomDocumentID; // We store the eventCustomDocumentID locally to fix clearing bug

                          await uploadEventDataToDatabase().then((status) {
                            if (status == true) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DashboardPage(
                                          documentID:
                                              storeEventCustomDocumentIDLocally)));
                              clearVariableValues();
                              isLoadingDataEntering = false;
                            }
                          });
                        },
                        child: Text(
                          'NEXT',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      )),
                ],
              ),
            ),
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

clearVariableValues() {
  bannerImageRefPath = "";
  bannerImageLocalPath = null;
  bannerImageURL = "";

  eventNameController.clear();
  bottleCountController.clear();
  bagCountController.clear();
  otherCountController.clear();
  containerCountController.clear();
  address = "";

  isGetAllContactsExecuted = false;

  addedParticipantsList.clear();
  hostList.clear();
  alreadyRegisteredUsersList.clear();
  contacts.clear();

  startDate = "";
  endDate = "";
  startTime = "";
  endTime = "";

  dateTimeAllDaysStatus = false;
  eventIntroController.clear();

  deepLink = "";
  eventCustomDocumentID = "";

  screenState = "NameScreen";
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

  /// Alternativaly: You can display an Android Styled Bottom Sheet instead of an iOS styled bottom Sheet
  // static void showSheet(
  //   BuildContext context, {
  //   required Widget child,
  // }) =>
  //     showModalBottomSheet(
  //       context: context,
  //       builder: (context) => child,
  //     );

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
