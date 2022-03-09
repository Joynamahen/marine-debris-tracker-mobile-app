import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:debristracker/app-utils/firebase-firestore-utils.dart';
import 'package:debristracker/app/1-dashboard-screens/event-setting.dart';

class SearchLocation extends StatefulWidget {
  var eventDocumentID;
  SearchLocation({Key? key, this.eventDocumentID}) : super(key: key);

  @override
  _SearchLocationState createState() => _SearchLocationState(eventDocumentID);
}

class _SearchLocationState extends State<SearchLocation> {
  _SearchLocationState(eventDocumentID);

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];

  @override
  void initState() {
    String apiKey = 'AIzaSyCM73rL10J5WPy21OZw7YakC6WGXeruPgA';
    googlePlace = GooglePlace(apiKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
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
        backgroundColor: Color(0xffF3F0E6),
      ),
      body: Container(
        //Add gradient to background
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Color(0xffFFFFFF),
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
                      backgroundColor: Color(0xff274D6C),
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
    );
  }

  void geDetails(var placeId) async {
    var result = await this.googlePlace.details.get(placeId);
    if (result != null && result.result != null && mounted) {
      String address = result.result!.formattedAddress.toString();
      await FirebaseFirestoreClass.updateDocumentData(
          "event_data", widget.eventDocumentID, {'location': address});

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EventSettingScreen(
                    eventDocumentID: widget.eventDocumentID,
                  ))).then((value) => setState(() {}));
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
}
