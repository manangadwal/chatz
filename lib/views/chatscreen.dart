// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:chatz/helperfunctions/sharedpref_helper.dart';
import 'package:chatz/services/data_base.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

class ChatScreen extends StatefulWidget {
  final String userName, name;
  ChatScreen({required this.name, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String chatRoomId, messageId = "";
  late String myName, myProfilePic, myUserName, myEmail;
  Stream<QuerySnapshot>? messageStream;
  TextEditingController textEditingController = TextEditingController();

  getMyInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName() ?? '';
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl() ?? '';
    myUserName = await SharedPreferenceHelper().getUserName() ?? '';
    myEmail = await SharedPreferenceHelper().getUserEmail() ?? '';

    print(widget.userName);
    print(myUserName);
    chatRoomId = getChatRoomIdByUserNames(widget.userName, myUserName);
  }

  getChatRoomIdByUserNames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  addMessage(bool sendClicked) {
    if (textEditingController.text != null) {
      String message = textEditingController.text;

      var lastMessageTs = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "ts": lastMessageTs,
        "imgUrl": myProfilePic
      };

      //messageID
      if (messageId == "") {
        messageId = randomAlphaNumeric(12);
      }

      DataBaseMethod()
          .addMessage(chatRoomId, messageId, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTs": lastMessageTs,
          "lastMessageSendBy": myUserName
        };

        DataBaseMethod().updateLastMessageSend(chatRoomId, lastMessageInfoMap);

        if (sendClicked) {
          //remove the text in input field
          textEditingController.text = '';
          //make message id blank to regenrate on next message send
          messageId = '';
        }
      });
    }
  }

  Widget chatMessageTile(String messages, bool sendByMe) {
    return Row(
      mainAxisAlignment:
          sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: sendByMe ? Radius.circular(20) : Radius.circular(0),
              bottomRight: sendByMe ? Radius.circular(0) : Radius.circular(20),
            ),
            color: sendByMe ? Colors.blue : Colors.grey,
          ),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              messages,
              style: TextStyle(color: sendByMe ? Colors.white : Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget chatMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(bottom: 85),
                reverse: true,
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (context, idx) {
                  DocumentSnapshot? ds = snapshot.data?.docs[idx];
                  return chatMessageTile(
                      ds?["message"], myUserName == ds?["sendBy"]);
                })
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  getAndSetMessages() async {
    messageStream = await DataBaseMethod().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreferences();
    getAndSetMessages();
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Container(
        // margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Stack(children: [
          chatMessages(),
          Container(
            // color: Colors.white,
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              child: Container(
                margin:
                    EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 16),

                // color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(25)),
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                      onChanged: (value) {
                        addMessage(false);
                      },
                      controller: textEditingController,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: "type a message"),
                    )),
                    GestureDetector(
                        onTap: () {
                          if (textEditingController.text != '') {
                            addMessage(true);
                          }
                        },
                        child: Icon(Icons.send)),
                  ],
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }
}
