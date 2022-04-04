import 'package:chatz/helperfunctions/sharedpref_helper.dart';
import 'package:chatz/services/data_base.dart';
import 'package:chatz/views/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken,
    );

    UserCredential result = await firebaseAuth.signInWithCredential(credential);
    User? userDetails = result.user;

    if (result != null) {
      SharedPreferenceHelper().saveUserEmail(userDetails?.email ?? '');
      SharedPreferenceHelper().saveUserId(userDetails?.uid ?? '');
      SharedPreferenceHelper().saveUserName(userDetails?.email ?? '');

      SharedPreferenceHelper().saveDisplayName(userDetails?.displayName ?? '');
      SharedPreferenceHelper().saveUserProfileUrl(userDetails?.photoURL ?? '');

      Map<String, dynamic> userInfoMap = {
        "email": userDetails?.email,
        "username": userDetails?.email,
        "name": userDetails?.displayName,
        "imgUrl": userDetails?.photoURL,
      };

      DataBaseMethod().addUserInfoToDB(userDetails?.uid, userInfoMap).then(
        (value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Home(),
            ),
          );
        },
      );
    }
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
  }
}
