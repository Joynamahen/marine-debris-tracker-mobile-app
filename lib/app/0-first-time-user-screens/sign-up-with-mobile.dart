import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:code_field/code_field.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication library helps to authenticate users.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:debristracker/app/1-dashboard-screens/dashboard-main-screen.dart';
import 'package:debristracker/app/landing-screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'registration-screen.dart';

//Executes first
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: SignUpWithMobile()));
}

//Create a stateful widget
class SignUpWithMobile extends StatefulWidget {
  const SignUpWithMobile({Key? key}) : super(key: key);

  @override
  _SignUpWithMobileState createState() => _SignUpWithMobileState();
}

String selectedCountryCode = "+94";

final FirebaseAuth _auth =
    FirebaseAuth.instance; //Create firebase instance(object)
final FirebaseFirestore _firestore =
    FirebaseFirestore.instance; //Create firebase_store instance(object)

final Color fontColor = Color(0xff07B1A1); // Define a color for button gradient
final Color primaryColor =
    Color(0xff04D3A8); // Define a color for button gradient
final Color secondaryColor =
    Color(0xff00B7B2); // Define a color for button gradient

PanelController _pc1 = new PanelController();
final phoneNumberTextBox =
    TextEditingController(); // Create a controller for phone number textbox
final otpController = TextEditingController(); // Create an OTP input controller

var userEnteredPhoneNumber = "";

bool buttonHide = false;
bool countryCodeListPanelVisible = false;

int waitTimeForOTP = 60;
bool isOTPLoading = false;
bool resendOTPStatus = false;
var resendOTPButtonStatus = "ToSend";

class _SignUpWithMobileState extends State<SignUpWithMobile> {
  var isLoginScreen =
      true; // To store login screen status, if it is true, it should open-up the login screen.
  var isOTPScreen =
      false; // To store OTP screen status, if it is true, it should open-up the OTP screen
  var verificationCode = ''; // To store verification code.

  @override
  void initState() {
    super.initState();
    listenOTP();
  }

  final Color fontColor = Color(0xff274D6C); // Define a color button gradient
  final Color primaryColor =
      Color(0xff274D6C); // Define a color button gradient
  final Color secondaryColor =
      Color(0xff00bfff); // Define a color button gradient

  BorderRadiusGeometry radius = BorderRadius.only(
    topLeft: Radius.circular(15.0),
    topRight: Radius.circular(15.0),
  );
  Color underlineColor = Color(0xffc4c4c4); // text-field underline color
  String invalidOTP = "";

  //Here, widgets are built.
  @override
  Widget build(BuildContext context) {
    // If the "isOTPScreen" is true, return the "returnOTPScreen()" widget. Otherwise, it returns the "returnLoginScreen()" screen.
    return isOTPScreen ? returnOTPScreen() : returnLoginScreen();
  }

  final _phoneNumberValidationKey = GlobalKey<FormState>();

  getCountryCodeFutureBuilderController() async {
    List countryCodesList = [];
    final String response =
        await rootBundle.loadString('asset/country-code.json');
    countryCodesList = jsonDecode(response);

    return countryCodesList;
  }

  getCountryCodeFutureBuilderView() {
    return FutureBuilder(
        future: getCountryCodeFutureBuilderController(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return Visibility(
              visible: countryCodeListPanelVisible,
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SlidingUpPanel(
                      minHeight: MediaQuery.of(context).size.height * 0.05,
                      maxHeight: MediaQuery.of(context).size.height * 0.69,
                      controller: _pc1,
                      onPanelClosed: () {
                        setState(() {
                          countryCodeListPanelVisible = false;
                          buttonHide = false;
                        });
                      },
                      panel: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Color(0xff3B455C), borderRadius: radius),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.65,
                              width: double.maxFinite,
                              child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  itemCount: snapshot.data.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        Card(
                                          elevation: 0,
                                          color: Color(0xff3B455C),
                                          child: ListTile(
                                            onTap: () async {
                                              setState(() {
                                                countryCodeListPanelVisible =
                                                    false;
                                                selectedCountryCode = snapshot
                                                    .data[index]['code'];
                                                buttonHide = false;
                                              });

                                              _pc1.close();
                                            },
                                            title: Text(
                                                snapshot.data[index]['name'],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                            trailing: Text(
                                                snapshot.data[index]['code'],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          ),
                                        ),
                                        Divider(
                                          color: Colors.white,
                                        ),
                                      ],
                                    );
                                  }),
                            ),
                          ],
                        ),
                      ),
                      collapsed: Container(
                        decoration: BoxDecoration(
                            color: Color(0xff3B455C), borderRadius: radius),
                      ),
                      borderRadius: radius,
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Text("");
            // Return nothing
          }
        });
  }

  Widget returnLoginScreen() {
    return Form(
        key: _phoneNumberValidationKey,
        child: Scaffold(
          appBar: AppBar(
            leadingWidth: 65,
            backgroundColor: Color(0xffFFFFFF),
            elevation: 0,
            leading: IconButton(
              onPressed: () async {
                countryCodeListPanelVisible = false;
                buttonHide = false;

                otpController.clear();
                FocusScope.of(context)
                    .requestFocus(new FocusNode()); // Close the keyboard
                await Future.delayed(const Duration(milliseconds: 200),
                    () {}); // To fix the overflow issue
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => LandingPage()));
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: fontColor,
              ),
            ),
          ),
          body: Container(
            color: Color(0xffFFFFFF),
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.height * 0.025,
                      right: MediaQuery.of(context).size.height * 0.025),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Continue With Mobile",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: Color(0xff595959)),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0375),
                      Stack(
                        children: <Widget>[
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                countryCodeListPanelVisible = true;
                                buttonHide = true;
                              });

                              await Future.delayed(
                                  const Duration(milliseconds: 200), () {});

                              _pc1.open();
                            },
                            child: Text(selectedCountryCode,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff595959))),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.2),
                            child: TextFormField(
                              cursorColor: fontColor,
                              cursorHeight: 30,
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                //Do something with the user input.
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a mobile number';
                                } else if (value.isNotEmpty) {
                                  String pattern =
                                      r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$';
                                  RegExp regExp = new RegExp(pattern);

                                  if (!regExp.hasMatch(value)) {
                                    return 'Please enter valid mobile number';
                                  }
                                }
                                return null;
                              },
                              controller: phoneNumberTextBox,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff595959)),
                              decoration: InputDecoration(
                                hintText: 'xxxxxxxxx',
                                hintStyle: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff595959)),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                getCountryCodeFutureBuilderView(),
              ],
            ),
          ),
          floatingActionButton: buttonHide == false
              ? Container(
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
                    //If loading is false,
                    onPressed: () async {
                      await SmsAutoFill().getAppSignature;

                      if (_phoneNumberValidationKey.currentState!.validate()) {
                        await login();
                      }
                    },
                    child: Text(
                      'CONTINUE',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ))
              : Container(),
          bottomSheet: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.075)),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ));
  }

  //It contains the UI and functionalities of OTP Screen
  Widget returnOTPScreen() {
    return isOTPLoading == false
        ? Scaffold(
            appBar: AppBar(
              leadingWidth: 65,
              backgroundColor: Color(0xffFFFFFF),
              elevation: 0,
              leading: IconButton(
                onPressed: () {
                  otpController.clear();
                  resendOTPStatus = false; // Reset OTP value
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SignUpWithMobile()));
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: fontColor,
                ),
              ),
            ),
            body: SafeArea(
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
                    children: [
                      Text(
                        "Enter Verification Code",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: Color(0xff595959)),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0375),
                      GestureDetector(
                          child: PinFieldAutoFill(
                        codeLength: 6,
                        autoFocus: true,
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: UnderlineDecoration(
                          textStyle: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                              color: Color(0xff595959)),
                          colorBuilder: FixedColorBuilder(underlineColor),
                        ),
                        onCodeChanged: (val) async {
                          if (otpController.text.length == 6) {
                            FocusScope.of(context).requestFocus(FocusNode());
                            try {
                              setState(() {
                                isOTPLoading = true;
                              });

                              await _auth
                                  .signInWithCredential(
                                      PhoneAuthProvider.credential(
                                          verificationId: verificationCode,
                                          smsCode:
                                              otpController.text.toString()))
                                  .then((user) async => {
                                        //sign in was success
                                        if (user != null)
                                          {
                                            await _firestore
                                                .collection('users')
                                                .where('phone_number',
                                                    isEqualTo:
                                                        userEnteredPhoneNumber
                                                            .trim()
                                                            .replaceAll(
                                                                ' ', ''))
                                                .get()
                                                .then((result) {
                                              if (result.docs.length > 0) {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            DashboardPage()));
                                              } else {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            RegistrationPage()));
                                              }

                                              otpController.clear();
                                              phoneNumberTextBox.clear();

                                              setState(() {
                                                isOTPLoading = false;
                                              });
                                            }),
                                          }
                                      });
                            } catch (e) {
                              setState(() {
                                isOTPLoading = false;
                                underlineColor = Color(0xffff0000);
                                invalidOTP =
                                    "invalid code used. please try again";
                              });
                            }
                          }
                        },
                      )),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.0125),
                      Text(
                        invalidOTP,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xffff0000)),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      resendOTPStatus == false
                          ? Countdown(
                              seconds: waitTimeForOTP,
                              build: (BuildContext context, double time) {
                                return Text(
                                  "Resend OTP in " +
                                      time.toInt().toString() +
                                      " seconds",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      color: fontColor),
                                );
                              },
                              interval: Duration(milliseconds: 1000),
                              onFinished: () {
                                setState(() {
                                  resendOTPStatus = true;
                                });
                              },
                            )
                          : Center(
                              child: resendOTPButtonStatus == "ToSend"
                                  ? Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.080,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(15)),
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
                                        onPressed: () async {
                                          setState(() {
                                            login();
                                            resendOTPButtonStatus = "Sent";
                                          });
                                        },
                                        child: Text(
                                          'Resend OTP',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                        ),
                                      ))
                                  : Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.080,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(15)),
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
                                                Color(0xffC4C4C4C),
                                                Color(0xffC4C4C4C)
                                              ])),
                                      child: TextButton(
                                        onPressed: () async {},
                                        child: Text(
                                          'Sending...',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                        ),
                                      )),
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
                  onPressed: () async {},
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

  /*
  Future signUp() async {

  var PhoneNumberVariable = '+94 '+phone_number_text_box.text.toString();

  var verifyPhoneNumber = _auth.verifyPhoneNumber(
    phoneNumber: PhoneNumberVariable,

    verificationCompleted: (PhoneAuthCredential) {

    _auth.signInWithCredential(PhoneAuthCredential).then((user) async => {

      if (user != null)
      {
        //store registration details in firestore database
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set({
          'phone_number': phone_number_text_box.text.trim(),
        }, SetOptions(merge: true))
        .then((value) => {

          setState(() {

             isLoginScreen = false;
             isOTPScreen = false;

             Navigator.pushAndRemoveUntil(
               context,
               MaterialPageRoute(
                 builder: (BuildContext context) =>
                     GetUserInfo(),
               ),
                   (route) => false,
             );
          })
        })
        .catchError((onError) => {
          debugPrint(
              'Error saving user to db.' + onError.toString())
        })

        }

    });

    },
    verificationFailed: (FirebaseAuthException error) {

      debugPrint(error.message.toString());

    },
    codeSent: (String verificationId, int? resendToken) {
      print("Code sent");
      setState(() {
        verificationCode = verificationId;
      });
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      setState(() {
        verificationCode = verificationId;
      });
    },
    timeout: Duration(seconds: 60),
  );

  await verifyPhoneNumber;

  }
   */

  //Define a display error messages bar
  displaySnackBar(text) {
    final snackBar = SnackBar(content: Text(text));
    //_scaffoldKey.currentState!.showSnackBar(snackBar);
  }

  String validateMobile(String value) {
    String patttern = r'(^(?:[+0]9)?[0-9]{10,12}$)';

    RegExp regExp = new RegExp(patttern);
    if (value.length == 0) {
      return 'Please enter mobile number';
    } else if (!regExp.hasMatch(value)) {
      return 'Please enter valid mobile number';
    }
    return "False";
  }

  //Define the login functionalities.
  Future login() async {
    var phoneNumber = selectedCountryCode +
        phoneNumberTextBox.text
            .trim(); //Get the phone number from the controller box add +94 with it.
    userEnteredPhoneNumber =
        phoneNumber; //Assign the phone number to this global variable to check, the user existence.

    var verifyPhoneNumber = _auth
        .verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (phoneAuthCredential) {
            //If verification complete
            print("Verification Completed");
          },
          verificationFailed: (FirebaseAuthException error) {
            //If verification failed.
            print(error);
          },
          codeSent: (verificationId, forceResendingToken) async {
            //If OTP code send.
            print("Code Sent...");
            setState(() {
              verificationCode = verificationId;
              isOTPScreen = true;
              resendOTPStatus = false;
              resendOTPButtonStatus = "ToSend";
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            //If timeouts,
            setState(() {
              verificationCode = verificationId;
            });
          },
          timeout: Duration(seconds: waitTimeForOTP), // Timeout duration 2 mins
        )
        .catchError((error) => {
              print(error),
            });

    await verifyPhoneNumber;
  }
}

void listenOTP() async {
  SmsAutoFill().listenForCode;
}
