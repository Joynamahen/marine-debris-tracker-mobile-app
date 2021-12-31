import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAccountUtils {

   static getUserPhoneNumber() {

    final FirebaseAuth _auth = FirebaseAuth.instance; // Create Firebase Auth instance

    if (_auth.currentUser != null) {
      return _auth.currentUser!.phoneNumber!;
    }
  }

   static getUserDocumentID() {

     final FirebaseAuth _auth = FirebaseAuth.instance; // Create Firebase Auth instance

     if (_auth.currentUser != null) {
       return _auth.currentUser!.uid;
     }
   }

   static Future<String> getCurrentUserUsername() async {

    String userName = "";

    final userUID = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(userUID).get().then((DocumentSnapshot documentSnapshot) {
      userName = documentSnapshot['name'].toString();
    });

    return userName;
  }


   static updateNotificationAvailableAsFalse(String userID) async {

     CollectionReference users = FirebaseFirestore.instance.collection("users");
     users.doc(userID).update({'is_notification_available':'[FALSE]'});
     return true;

   }

   static updateNotificationAvailableAsTrue(var targetedUserIDS) async {

     for (final id in targetedUserIDS) {

       CollectionReference users = FirebaseFirestore.instance.collection("users");
       users.doc(id).update({'is_notification_available':'[TRUE]'});

     }
     return true;

   }


}
