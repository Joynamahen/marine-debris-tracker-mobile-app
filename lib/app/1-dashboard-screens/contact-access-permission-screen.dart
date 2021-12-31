import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:debristracker/app/1-dashboard-screens/add-extra-participants-screen.dart';

final Color fontColor = Color(0xff07B1A1);
final Color buttonColor =
    Color(0xff04D3A8); // Define a color for button gradient
final Color primaryColor =
    Color(0xff04D3A8); // Define a color for button gradient
final Color secondaryColor =
    Color(0xff00B7B2); // Define a color for button gradient

String localEventDataDocumentID = "";

class ContactAccessPermissionScreen extends StatefulWidget {
  var eventDocumentID;

  ContactAccessPermissionScreen({Key? key, this.eventDocumentID})
      : super(key: key);

  @override
  _ContactAccessPermissionScreenState createState() =>
      _ContactAccessPermissionScreenState(eventDocumentID);
}

class _ContactAccessPermissionScreenState
    extends State<ContactAccessPermissionScreen> {
  _ContactAccessPermissionScreenState(eventDocumentID);

  @override
  void initState() {
    localEventDataDocumentID = widget.eventDocumentID;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        backgroundColor: Color(0xffF3F0E6),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            //Navigator.push(context, MaterialPageRoute(builder: (_) => ParticipantListPage()));
          },
          child: const Text(
            "SKIP",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18.0,
              color: Color(0xff595959),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xffF3F0E6), Color(0xffFFFFFF)])),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Find your friends on\nSINGSING",
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
                "Sync contacts to see which of your friends are already on SINGSING",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff595959)),
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.passthrough,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.05,
                    child: Image.asset(
                        //Add image from asset
                        "images/friends1.png", //Image source
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.5),
                  ),
                  Positioned(
                    right: MediaQuery.of(context).size.width * 0.1,
                    left: MediaQuery.of(context).size.width * 0.1,
                    top: -MediaQuery.of(context).size.height * 0.05,
                    child: Image.asset("images/friends2.png",
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.45),
                  ),
                  Positioned(
                    right: MediaQuery.of(context).size.width * 0.05,
                    left: MediaQuery.of(context).size.width * 0.05,
                    top: MediaQuery.of(context).size.height * 0.45,
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width -
                            MediaQuery.of(context).size.width * 0.05,
                        padding: EdgeInsets.symmetric(vertical: 5),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width -
                              MediaQuery.of(context).size.width * 0.05,
                          height: 40,
                          child: TextButton(
                            onPressed: () async {
                              if (await Permission.contacts
                                  .request()
                                  .isGranted) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AddExtraParticipantsPage(
                                                eventDocumentID:
                                                    localEventDataDocumentID)));
                              } else {
                                openAppSettings();
                              }
                            },
                            child: Text(
                              'ALLOW ACCESS TO CONTACTS',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
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
                                ])), //Add gradiant colors to the button
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ])),
    );
  }
}
