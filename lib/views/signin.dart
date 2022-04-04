// ignore_for_file: prefer_const_constructors

import 'package:chatz/services/auth.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buggy Messenger"),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            AuthMethods().signInWithGoogle(context);
          },
          child: Container(
            color: Colors.amber,
            padding: EdgeInsets.all(12),
            child: Text("Sign in with google"),
          ),
        ),
      ),
    );
  }
}
