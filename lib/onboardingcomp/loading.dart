import 'dart:async';

import 'package:cabiee/main.dart';
import 'package:cabiee/models/size_config.dart';
import 'package:cabiee/onboardingcomp/login.dart';
import 'package:cabiee/onboardingcomp/splash.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  startTime() async {
    var _duration = new Duration(seconds: 3);
    return new Timer(_duration, navigationPage);
  }

  AnimationController controller;

  @override
  void initState() {
    super.initState();
    startTime();
    controller = AnimationController(duration: Duration(seconds: 4), vsync: this);
  }

  void navigationPage() async {
    User user =FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid.toString())
            .get()
            .then((DocumentSnapshot snap) {
          if (snap.exists) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MyApp()));
          } else {
            FirebaseAuth.instance.signOut().then((_) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginPage()));
            });
          }
        });
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Splash()));
      }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.amberAccent,
            body: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 20),
                    child: Text(
                      'CABIEE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(left: 20, right: 20, top: 120),
                    child: CircularProgressIndicator()
                  ),
                ),
              ],
            )));
  }
}
