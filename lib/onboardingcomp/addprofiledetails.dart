
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class ChooseName extends StatefulWidget {
  @override
  _ChooseUsernameState createState() => _ChooseUsernameState();
}

class _LoginData {
  String email = '';
  String name = '';
}

class _ChooseUsernameState extends State<ChooseName>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  _LoginData _data = new _LoginData();

  int check;

  String _validateEmail(String value) {
    if (value.length < 5) {
      return 'The email must be at least 5 characters.';
    }

    return null;
  }

  String _validateName(String value) {
    if (value.length < 5) {
      return 'The Name must be at least 5 characters.';
    }

    return null;
  }

  void submit() {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.
      User user =FirebaseAuth.instance.currentUser;
        FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid.toString())
            .set({
          'number': user.phoneNumber,
          'user_id': user.uid.toString(),
          'email': this._data.email,
          'name': this._data.name,
          'image': '',
          'home': null,
          'work': null,
        }).whenComplete(() {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MyApp()));
        }).catchError((e) {
        return e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
      body: ListView(
        children: <Widget>[

          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Hero(
                   tag: 'loco',
                   child: Container(
                     height: 100,
                     width: 100,
                     padding: EdgeInsets.only(bottom: 20,),
                     decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(
                             width: 4.0,
                             color: Colors.white,
                             style: BorderStyle.solid),
                         boxShadow: [
                           BoxShadow(
                               blurRadius: 1.0,
                               color: Colors.black12,
                               spreadRadius: 2.0)
                         ],
                         image: DecorationImage(
                             image: AssetImage('logo.png'), fit: BoxFit.cover)),
                   ),
                 ),
                 SizedBox(height: 20,),
                 Container(
                   margin: EdgeInsets.only(left: 20, right: 20, top: 10),
                   child: Text(
                     'Cabiee',
                     style: TextStyle(
                         fontSize: 32,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 2,
                       ),
                   ),
                 ),
               ],
            ),
          ),
          Container(
            padding: new EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
            child: Form(
              key: this._formKey,
              child: Column(
                children: <Widget>[
                  new TextFormField(
                      decoration: new InputDecoration(
                          hintText: 'Email',
                          labelText: 'Enter Your Email'),
                      validator: this._validateEmail,
                      onSaved: (String value) {
                        this._data.email = value;
                      }),
                  SizedBox(height: 20,),
                  new TextFormField(
                      decoration: new InputDecoration(
                          hintText: 'Name', labelText: 'Enter Your Name'),
                      validator: this._validateName,
                      onSaved: (String value) {
                        this._data.name = value;
                      }),
                  SizedBox(height: 20,),
                  new Container(
                    width: screenSize.width,
                    child: new RaisedButton(
                      child: new Text(
                        'Register',
                        style: new TextStyle(color: Colors.amberAccent),
                      ),
                      onPressed: this.submit,
                      color: Colors.black,
                    ),
                    margin: new EdgeInsets.only(top: 20.0),
                  ),
                ],
              ),
            ),
          )
        ],
      )),
    );
  }
}
