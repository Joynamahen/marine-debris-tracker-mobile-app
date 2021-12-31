import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFirestoreClass {
  static insertMapData(Map data, String collectionName) async {
    CollectionReference collectionReference = FirebaseFirestore.instance.collection(collectionName);
    await collectionReference.add(data);
    return true;
  }

  static insertMapDataWithCustomDocumentID(Map data, String collectionName, String customEventDocID) async {
    CollectionReference collectionReference = FirebaseFirestore.instance.collection(collectionName);
    await collectionReference.doc(customEventDocID).set(data);
    return true;
  }

  static insertMapDataReturnDocumentID(Map data, String collectionName) async {
    CollectionReference collectionReference = FirebaseFirestore.instance.collection('event_data');
    var documentData = await collectionReference.add(data);

    return documentData.id;
  }

  static updateDocumentData(String collectionName, String documentID, var updateData) {
    CollectionReference users = FirebaseFirestore.instance.collection(collectionName);
    users.doc(documentID).update(updateData);

    return true;
  }

  static insertNotificationData(Map data, String collectionName, String customDocID) async {
    CollectionReference collectionReference = FirebaseFirestore.instance.collection(collectionName);
    await collectionReference.doc(customDocID).set(data);
    return true;
  }

  static insertChatData(Map data, String collectionName, String customDocID) async {
    CollectionReference collectionReference = FirebaseFirestore.instance.collection(collectionName);
    await collectionReference.doc(customDocID).set(data);
    return true;
  }
}
