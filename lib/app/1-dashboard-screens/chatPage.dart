import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app-utils/user-account-utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

final messageController =
    TextEditingController(); //Create a text-box controller to get the message from the user.
var globalCurrentUserDocumentID = "";
var globalCurrentUserName = "";
String currentChatId = "";
String chatDate = "";
String chatTime = "";
String profilePictureURL = "";

class ChatPageView extends StatefulWidget {
  ChatPageView({Key? key}) : super(key: key);

  @override
  _ChatPageViewState createState() => _ChatPageViewState();
}

getUserName() async {
  globalCurrentUserName = await UserAccountUtils.getCurrentUserUsername();
}

class _ChatPageViewState extends State<ChatPageView> {
  ScrollController _scrollController = ScrollController();

  void initState() {
    globalCurrentUserDocumentID = UserAccountUtils.getUserDocumentID();
    getUserName();

    super.initState();
  }

  uploadChatDataToDatabase() async {
    var currentTimestamp = DateTime.now().millisecondsSinceEpoch;

    chatDate = DateFormat("yyyy/MM/dd").format(DateTime.now());
    chatTime = DateFormat("hh:mm a").format(DateTime.now());
    DocumentReference ref = FirebaseFirestore.instance
        .collection("chat_data")
        .doc(); // Get the next docID
    String currentChatId = ref.id;

    Map<String, dynamic> chatData = {
      "chat_id": currentChatId,
      "user_id": globalCurrentUserDocumentID,
      "message": messageController.text,
      "chat_date": chatDate,
      "chat_time": chatTime,
      "timestamp": currentTimestamp,
    };

    await FirebaseFirestoreClass.insertMapDataWithCustomDocumentID(
        chatData, "chat_data", currentChatId);
    messageController.clear(); //clear TextBox
  }

  streamChatData() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_data')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.data != null && snapshot.hasData) {
            return Container(
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot documentSnapshot =
                        snapshot.data!.docs[index];
                    var basicChatData = [
                      documentSnapshot.get('message'),
                      documentSnapshot.get('user_id')
                    ];
                    return getProfileDataFutureBuilderView(basicChatData);
                  }),
            );
          } else {
            return Text("");
          }
        });
  }

  getProfileDataFutureBuilderController(String userID) async {
    var profileData = [];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      profileData.add(documentSnapshot['name'].toString());
      profileData.add(documentSnapshot['profile_picture_url'].toString());
    });

    return profileData;
  }

  getProfileDataFutureBuilderView(var basicChatData) {
    return FutureBuilder(
      future: getProfileDataFutureBuilderController(basicChatData[1]),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Card(
            margin: EdgeInsets.only(top: 10),
            elevation: 0,
            color: Color(0xff3B455C),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(15),
                  ),
                  child: snapshot.data[1] == "[SKIPPED]"
                      ? Image.asset(
                          "images/default-profile-picture.png",
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: MediaQuery.of(context).size.width *
                              0.1, // this is the solution for border
                        )
                      : CachedNetworkImage(
                          imageUrl: snapshot.data[1],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.1,
                                height: MediaQuery.of(context).size.width * 0.1,
                                color: Colors.white,
                              ),
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: MediaQuery.of(context).size.width *
                              0.1, // this is the solution for border
                        ),
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.data[0],
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xffffffff),
                        ),
                      ),
                      Text(
                        basicChatData[0],
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xffffffff),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Text("");
        }
      },
    );
  }

  getUserProfilePictureFutureBuilderController() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(globalCurrentUserDocumentID)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      profilePictureURL = documentSnapshot['profile_picture_url'].toString();
    });

    return profilePictureURL;
  }

  getUserProfilePictureFutureBuilderView() {
    return FutureBuilder(
      future: getUserProfilePictureFutureBuilderController(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.all(
              Radius.circular(15),
            ),
            child: snapshot.data.toString() != '[SKIPPED]'
                ? CachedNetworkImage(
                    imageUrl: snapshot.data.toString(),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                        child: Container(
                          width: 60,
                          height: 40,
                          color: Colors.white,
                        ),
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    width: 60,
                    height: 40, // this is the solution for border
                  )
                : Image.asset(
                    "images/default-profile-picture.png",
                    fit: BoxFit.cover,
                    width: 60,
                    height: 40, // this is the solution for border
                  ),
          );
        } else {
          return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: Shimmer.fromColors(
                  child: Container(
                    width: 60,
                    height: 40,
                    color: Colors.white,
                  ),
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.navigate_before,
              size: 30, color: Color(0xff595959)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          getUserProfilePictureFutureBuilderView(),
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Flexible(
              fit: FlexFit.tight,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    // reverse: true,
                    child: streamChatData(),
                  )),
            ),
            Container(
              color: Colors.black12,
              height: 50,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextField(
                  maxLines: 20,
                  controller: messageController,
                  decoration: InputDecoration(
                    suffixIcon: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Color(0xff274D6C),
                          ),
                          onPressed: () async {
                            uploadChatDataToDatabase();
                          },
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    hintText: "enter your message",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
