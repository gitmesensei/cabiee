import 'dart:ui';

import 'package:cabiee/onboardingcomp/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Container(
          decoration: BoxDecoration(
            color: Colors.amberAccent,
            border: Border(right: BorderSide(color: Colors.white,width: 0.5))
          ),
          child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 0),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            width: 2.0,
                            color: Colors.black,
                            style: BorderStyle.solid),
                    ),
                    child: Center(
                      child: Icon(Icons.person,color: Colors.black,size: 50,),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      'Yog Sharma',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      'yog2328@gmail.com',
                      style: TextStyle(color: Colors.black, fontSize: 10),
                    ),
                  )
                ],
              ),
            ),
          ),
          ListTile(
            title: Text(
              'favourites',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.favorite,
              color: Colors.black,
            ),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              'recent booking',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.check_circle,
              color: Colors.black,
            ),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              'inquiry',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.person_pin,
              color: Colors.black,
            ),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              'submit offer',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.publish,
              color: Colors.black,
            ),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              'logout',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.exit_to_app,
              color: Colors.black,
            ),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Splash()));
            },
          ),
          Divider(
            height: 2,
            color: Colors.black,
          ),
          Padding(
            padding: EdgeInsets.only(top: 10, left: 20),
            child: Text(
              'communicate',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            title: Text(
              'contact us',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.mail,
              color: Colors.black,
            ),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              'privacy policy',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.lock,
              color: Colors.black,
            ),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              'help',
              style: TextStyle(color: Colors.black),
            ),
            leading: Icon(
              Icons.help,
              color: Colors.black,
            ),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
        ],
      )
      )]);
  }
}
