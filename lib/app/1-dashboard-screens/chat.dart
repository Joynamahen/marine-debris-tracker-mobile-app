    SlidingUpPanel(
                controller: _pc,
                minHeight: MediaQuery.of(context).size.height * 0.1,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
                onPanelClosed: () {
                  setState(() {});
                },
                onPanelOpened: () {},
                panel: Container(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  decoration: BoxDecoration(
                      color: Color(0xff3B455C), borderRadius: radius),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gathering Chat",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xffD8833A),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: streamChatData(),
                        ),
                      ),
                    ],
                  ),
                ),
                footer: Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.05,
                      right: MediaQuery.of(context).size.width * 0.05,
                      bottom: MediaQuery.of(context).size.width * 0.025),
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Color(0xffffffff),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.multiline,
                                minLines: 1,
                                maxLines: 2,
                                cursorColor: Color(0xff595959),
                                controller: messageController,
                                textInputAction: TextInputAction.send,
                                decoration: InputDecoration(
                                  hintText: 'Start typing...',
                                  contentPadding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width *
                                          0.05),
                                  hintStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff555555)),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff595959)),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send, color: Color(0xff595959)),
                              onPressed: () async {
                                uploadChatDataToDatabase();
                                chatScroller.animateTo(
                                    chatScroller.position.maxScrollExtent,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                collapsed: Container(
                  decoration: BoxDecoration(
                      color: Color(0xff3B455C), borderRadius: radius),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.00625,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                MediaQuery.of(context).size.width * 0.05,
                                10,
                                MediaQuery.of(context).size.width * 0.05,
                                0),
                            child: Text(
                              "Gathering Chat",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xffD8833A),
                              ),
                            ),
                          ),
                          //messageNotificationFutureBuilderView()
                        ],
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                MediaQuery.of(context).size.width * 0.05,
                                0,
                                MediaQuery.of(context).size.width * 0.05,
                                10),
                            child: Text(
                              "Start your conversation",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xffD8833A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                borderRadius: radius,
              );
              