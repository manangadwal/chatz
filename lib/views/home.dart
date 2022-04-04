// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_local_variable

import 'package:chatz/services/auth.dart';
import 'package:chatz/services/data_base.dart';
import 'package:chatz/views/chatscreen.dart';
import 'package:chatz/views/signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../helperfunctions/sharedpref_helper.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? myName, myProfilePic, myUserName, myEmail;
  bool isSearching = false;
  Stream<QuerySnapshot>? usersStream, chatRoomStream;

  TextEditingController searchUserNameController = TextEditingController();

  getChatRoomIdByUserNames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  getMyInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName() ?? '';
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl() ?? '';
    myUserName = await SharedPreferenceHelper().getUserName() ?? '';
    myEmail = await SharedPreferenceHelper().getUserEmail() ?? '';

    setState(() {});
  }

  onSearchBtnClick() async {
    if (searchUserNameController.text != "") {
      isSearching = true;
      usersStream = await DataBaseMethod()
          .getUserByUserName(searchUserNameController.text);
      setState(() {});
    }
  }

  Widget chatRoomList() {
    return StreamBuilder<QuerySnapshot>(
        stream: chatRoomStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, idx) {
                    DocumentSnapshot? ds = snapshot.data?.docs[idx];

                    return ChatRoomListTile(
                      lastMessage: ds?["lastMessage"],
                      chatRoomId: ds?.id,
                      myUsername: myUserName,
                    );
                  })
              : Center(child: CircularProgressIndicator());
        });
  }

  Widget searcListUserTile(String profileUrl, name, email, userName) {
    return GestureDetector(
      onTap: () {
        var chatRoomId =
            getChatRoomIdByUserNames(userName, myUserName as String);

        Map<String, dynamic> chatRoomInfoMap = {
          "users": [name, myName]
        };

        DataBaseMethod().createChatRoom(chatRoomId, chatRoomInfoMap);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatScreen(
                      name: name,
                      userName: userName,
                    )));
      },
      child: Container(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              child: Image.network(profileUrl, height: 45),
              borderRadius: BorderRadius.circular(25),
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget searchUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (context, idx) {
                  DocumentSnapshot? ds = snapshot.data?.docs[idx];
                  return searcListUserTile(ds?['imgUrl'], ds?['name'],
                      ds?['email'], ds?['username']);
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }

  getChatRoomListData() async {
    chatRoomStream = await DataBaseMethod().getChatRoom();
    setState(() {});
  }

  onScreenLoaded() async {
    await getMyInfoFromSharedPreferences();
    getChatRoomListData();
    // chatRoomList();
  }

  @override
  void initState() {
    onScreenLoaded();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buggy Messenger "),
        // elevation: 1,
        actions: [
          IconButton(
            onPressed: () {
              AuthMethods().signOut().then((s) {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => SignIn()));
              });
            },
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.only(top: 15),
        margin: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Row(
              children: [
                isSearching
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            isSearching = false;
                            searchUserNameController.text = "";
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.arrow_back),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: Container(
                    // margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: Colors.grey,
                            width: 1,
                            style: BorderStyle.solid)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            showCursor: false,
                            controller: searchUserNameController,
                            decoration: InputDecoration(
                                hintText: "search users",
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                    fontSize: 15, color: Colors.grey[600])),
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              onSearchBtnClick();
                            },
                            child: Icon(Icons.search)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Container(child: chatRoomList()),
            isSearching ? searchUsersList() : chatRoomList(),
          ],
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  String? lastMessage, chatRoomId, myUsername;
  // const ChatRoomListTile({Key? key}) : super(key: key);
  ChatRoomListTile({this.lastMessage, this.chatRoomId, this.myUsername});

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String? profilePicUrl, name, userName;

  getThisUserInfo() async {
    userName = widget.chatRoomId
        ?.replaceAll(widget.myUsername ?? '', "")
        .replaceAll("@gmail.com", "")
        .replaceAll("_", "");

    QuerySnapshot querySnapshot =
        await DataBaseMethod().getUserInfo(userName ?? '');
    name = "${querySnapshot.docs[0]["name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["imgUrl"]}";

    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.network(
          profilePicUrl ?? '',
          height: 30,
          width: 30,
        ),
        Column(
          children: [
            Text(name ?? ''),
            Text(widget.lastMessage ?? ''),
          ],
        )
      ],
    );
  }
}
