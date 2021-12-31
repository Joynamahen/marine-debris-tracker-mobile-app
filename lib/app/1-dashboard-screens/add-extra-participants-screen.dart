import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';

import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';
import 'package:debristracker/app/2-create-events-screens/event-creatation-main.dart';

final Color fontColor = Color(0xff07B1A1);
final Color buttonColor =
    Color(0xff04D3A8); // Define a color for button gradient
final Color primaryColor =
    Color(0xff04D3A8); // Define a color for button gradient
final Color secondaryColor =
    Color(0xff00B7B2); // Define a color for button gradient

var addedParticipantsList = [];
var invitedViaSMSParticipantsList = [];
final Map<String, String> alreadyRegisteredUsersList = {};

bool initStateDataFinishListenerStatus = false;

List<Contact> contacts = [];
List<Contact> contactsFiltered = [];

bool isGetAllContactsExecuted = false;

String screenState = "ContactWithoutSearchOption";

Map<String, Color> contactsColorMap = new Map();
TextEditingController contactSearchController = new TextEditingController();

String globalEventDataDocumentID = "";
String globalEventName = "";
String globalDeepLinkURL = "";

class AddExtraParticipantsPage extends StatefulWidget {
  var eventDocumentID;
  var eventName;

  AddExtraParticipantsPage({Key? key, this.eventDocumentID, this.eventName})
      : super(key: key);

  @override
  _AddExtraParticipantsPageState createState() =>
      _AddExtraParticipantsPageState(eventDocumentID, eventName);
}

class _AddExtraParticipantsPageState extends State<AddExtraParticipantsPage> {
  _AddExtraParticipantsPageState(eventDocumentID, eventName);

  @override
  void initState() {
    globalEventDataDocumentID = widget.eventDocumentID;
    globalEventName = widget.eventName;

    getPermissions();
    getAlreadyRegisteredUsers();
    getPreAddedAndDeeplinkURL();
    initStateDataFinishListener();

    super.initState();
  }

  initStateDataFinishListener() async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (addedParticipantsList.isNotEmpty &&
          alreadyRegisteredUsersList.isNotEmpty) {
        setState(() {
          initStateDataFinishListenerStatus = true;
        });

        break;
      }
    }
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

  getPreAddedAndDeeplinkURL() async {
    await FirebaseFirestore.instance
        .collection('event_data')
        .doc(globalEventDataDocumentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      addedParticipantsList = documentSnapshot['participants'];
      globalDeepLinkURL = documentSnapshot['deeplink_url'];
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
    print(_result);
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
        );
      }
    }

    if (alreadyRegisteredUsersList.containsValue(userDocumentID)) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.width * 0.08,
        alignment: Alignment.center,

        child: Text('ADD',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white)),

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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (screenState == "ContactWithoutSearchOption") {
      return contactWithoutSearchOption();
    } else if (screenState == "contactWithSearchOption") {
      return contactWithSearchOption();
    }

    return contactWithoutSearchOption();
  }

  Widget contactWithoutSearchOption() {
    bool isSearching = contactSearchController.text.isNotEmpty;
    bool listItemsExist = (contactsFiltered.length > 0 || contacts.length > 0);

    return initStateDataFinishListenerStatus == true
        ? Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Color(0xffF3F0E6),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.navigate_before,
                    size: 30, color: Color(0xff595959)),
                onPressed: () {
                  clearVariableValues();
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
                  Text(globalEventName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E90FF).withOpacity(0.65))),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                    onPressed: () {
                      setState(() {
                        screenState = "contactWithSearchOption";
                      });
                    },
                    icon: Icon(
                      Icons.search,
                      color: Colors.black.withOpacity(0.65),
                      size: 36,
                    )),
              ],
            ),
            //Scaffold widget will expand or occupy the whole device screen.
            body: Container(
              //Add gradient to background
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
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
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        MediaQuery.of(context).size.width * 0.05,
                        0,
                        MediaQuery.of(context).size.width * 0.05,
                        0),
                    child: Text(
                      "Invite tribe members to\nyour social gathering",
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
                  Container(
                    height: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).size.height * 0.25,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.05),
                            child: Row(
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: TextEditingController()
                                            ..text =
                                                "      " + globalDeepLinkURL,
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xff04D3A8)),
                                        ),
                                      ),
                                      Text(
                                        "copy",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff595959)),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.content_copy,
                                            color: Color(0xff595959)),
                                        onPressed: () async {
                                          ClipboardData data = ClipboardData(
                                              text: globalDeepLinkURL);
                                          await Clipboard.setData(data);

                                          Flushbar(
                                            flushbarPosition:
                                                FlushbarPosition.TOP,
                                            messageText: Text(
                                              "Invite link copied",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.white,
                                                  fontFamily: "Montserrat"),
                                            ),
                                            margin: EdgeInsets.fromLTRB(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.25,
                                                0,
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.25,
                                                0),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            backgroundGradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0xffD8833A),
                                                  Color(0xffD8AC3A)
                                                ]),
                                            duration: Duration(seconds: 3),
                                            isDismissible: false,
                                          )..show(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.0125),
                          Padding(
                            padding: EdgeInsets.only(
                                right:
                                    MediaQuery.of(context).size.width * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  "Or share now",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff07B1A1)),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.025,
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.height * 0.05,
                                  height:
                                      MediaQuery.of(context).size.height * 0.05,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(34)),
                                    gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [secondaryColor, primaryColor]),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0xff69B0AE),
                                        spreadRadius: 0,
                                        blurRadius: 2,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.share,
                                      color: Color(0xffffffff),
                                    ),
                                    onPressed: () async {
                                      Share.share(globalDeepLinkURL);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.0125),
                          listItemsExist == true
                              ? isSearching == true &&
                                      contactsFiltered.length == 0
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
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

                                        var baseColor = contactsColorMap[
                                            contact.displayName] as dynamic;

                                        Color color1 = baseColor;
                                        Color color2 = baseColor;
                                        return ListTile(
                                          visualDensity: VisualDensity(
                                              horizontal: 0, vertical: -4),
                                          title: Text(
                                              contact.displayName.toString()),
                                          subtitle: Text(
                                              contact.phones!.length > 0
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
                                                      begin:
                                                          Alignment.bottomLeft,
                                                      end: Alignment.topRight)),
                                              child: CircleAvatar(
                                                  child: Text(
                                                      contact.initials(),
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  backgroundColor:
                                                      Colors.transparent)),
                                          trailing: InkWell(
                                            onTap: () {
                                              // Main Contact

                                              var currentNumber = contact
                                                  .phones!
                                                  .elementAt(0)
                                                  .value
                                                  .toString()
                                                  .replaceAll(' ', '');
                                              var userDocumentID =
                                                  alreadyRegisteredUsersList[
                                                      currentNumber];

                                              if (addedParticipantsList
                                                  .contains(userDocumentID
                                                          .toString() +
                                                      " = [PENDING]")) {
                                                setState(() {
                                                  addedParticipantsList.remove(
                                                      userDocumentID
                                                              .toString() +
                                                          " = [PENDING]");
                                                });
                                              } else {
                                                if (alreadyRegisteredUsersList
                                                    .containsValue(
                                                        userDocumentID)) {
                                                  setState(() {
                                                    addedParticipantsList.add(
                                                        userDocumentID
                                                                .toString() +
                                                            " = [PENDING]");
                                                  });
                                                } else {
                                                  String currentPhoneNumber =
                                                      contact.phones!
                                                          .elementAt(0)
                                                          .value
                                                          .toString()
                                                          .replaceAll(' ', '');

                                                  setState(() {
                                                    if (invitedViaSMSParticipantsList
                                                        .contains(
                                                            currentPhoneNumber)) {
                                                      invitedViaSMSParticipantsList
                                                          .remove(
                                                              currentPhoneNumber);
                                                    } else {
                                                      invitedViaSMSParticipantsList
                                                          .add(
                                                              currentPhoneNumber);
                                                    }
                                                  });

                                                  _sendSMS(
                                                      "Hey, join my social event on SingSing $globalDeepLinkURL",
                                                      currentNumber);
                                                }
                                              }
                                            },
                                            child: inviteButtonStateFunction(
                                                contact.phones!
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
                                              top: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.10),
                                          child: SpinKitFadingCircle(
                                            color: Colors.black,
                                          )),
                                    )
                                  : Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.10),
                                        child: Column(
                                          children: [
                                            Text('No contacts found',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline6),
                                            Icon(
                                              Icons.warning_amber,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.30,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: Container(
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
                    if (addedParticipantsList.length > 0) {
                      bool status =
                          await FirebaseFirestoreClass.updateDocumentData(
                              'event_data',
                              globalEventDataDocumentID,
                              {'participants': addedParticipantsList});

                      if (status == true) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => DashboardPage()));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                          '⚠ No one is invited, please invite some people.',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        )),
                      );
                    }
                  },
                  child: Text(
                    'DONE',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                )),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            bottomSheet: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.05)),
          )
        : Center(
            child: Scaffold(
            body: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.10),
                child: SpinKitFadingCircle(
                  color: Colors.black,
                )),
          ));
  }

  Widget contactWithSearchOption() {
    bool isSearching = contactSearchController.text.isNotEmpty;
    bool listItemsExist = (contactsFiltered.length > 0 || contacts.length > 0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Color(0xffF3F0E6),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            setState(() {
              screenState = "contactWithoutSearchOption";
            });
          },
          child: const Text(
            "X",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22.0,
              color: Color(0xff595959),
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
            Container(
              padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width * 0.05,
                  0,
                  MediaQuery.of(context).size.width * 0.05,
                  0),
              child: Text(
                "Add tribe members",
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
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor: Color(0xffC4C4C4),
                  style: TextStyle(fontSize: 12, color: Color(0xffC4C4C4)),
                  controller: contactSearchController,
                  decoration: InputDecoration(
                    hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xffC4C4C4)),
                    filled: true,
                    hintText: 'Search contacts or users',
                    prefixIcon: Icon(Icons.search, color: Color(0xffC4C4C4)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width * 0.05,
                  0,
                  MediaQuery.of(context).size.width * 0.05,
                  0),
              child: Text(
                "your contacts",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: fontColor),
              ),
            ),
            listItemsExist == true
                ? Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: double.maxFinite,
                    child: isSearching == true && contactsFiltered.length == 0
                        ? Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.10),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
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
                                visualDensity:
                                    VisualDensity(horizontal: 0, vertical: -4),
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
                                            style:
                                                TextStyle(color: Colors.white)),
                                        backgroundColor: Colors.transparent)),
                                trailing: InkWell(
                                  // If the done button is clicked, do the following things.
                                  onTap: () {
                                    // Normal search

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
                                              .contains(currentPhoneNumber)) {
                                            invitedViaSMSParticipantsList
                                                .remove(currentPhoneNumber);
                                          } else {
                                            invitedViaSMSParticipantsList
                                                .add(currentPhoneNumber);
                                          }
                                        });

                                        _sendSMS(
                                            "Hey, join my social event on SingSing $globalDeepLinkURL",
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
                          ),
                  )
                : isGetAllContactsExecuted == false
                    ? Center(
                        child: Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.10),
                            child: SpinKitFadingCircle(
                              color: Colors.black,
                            )),
                      )
                    : Center(
                        child: Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.width * 0.10),
                        child: Column(
                          children: [
                            Text('No contacts found',
                                style: Theme.of(context).textTheme.headline6),
                            Icon(
                              Icons.warning_amber,
                              size: MediaQuery.of(context).size.width * 0.30,
                            ),
                          ],
                        ),
                      ))
          ],
        ),
      ),
    );
  }
}

clearVariableValues() {
  initStateDataFinishListenerStatus = false;
  addedParticipantsList.clear();
  invitedViaSMSParticipantsList.clear();
  alreadyRegisteredUsersList.clear();
}
