import 'dart:async';

import 'package:cabiee/models/size_config.dart';
import 'package:cabiee/onboardingcomp/addprofiledetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_view/pin_view.dart';

import 'login.dart';
import '../main.dart';


// ignore: must_be_immutable
class OTP extends StatefulWidget {
  String verificationId;
  String phone;
  OTP(this.verificationId, this.phone);

  @override
  _OTPState createState() => _OTPState();
}

class _OTPState extends State<OTP> {


  Future<void> verify() async{
    final PhoneCodeAutoRetrievalTimeout autoRetrievalTimeout = (String id){
      widget.verificationId=id;
    };
    final PhoneCodeSent codeSent = (String id,[int resend]){
      widget.verificationId=id;
    };

    final PhoneVerificationCompleted completed = (user){

    };
    final PhoneVerificationFailed failed = ( FirebaseAuthException exception){
      print('${exception.message}');
    };


    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        timeout: const Duration(seconds: 5),
        verificationCompleted:completed,
        verificationFailed: failed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: autoRetrievalTimeout);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold (
          backgroundColor: Colors.amberAccent,
          body: Container (
            padding: EdgeInsets.only(top:0,left: 20,right: 20),
            child: Column (
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible (
                    child: Column (
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 10,),
                        Icon(Icons.phonelink_ring, size: 100.0, color: Colors.black),
                        SizedBox(height: 10,),
                        Container (
                          width: MediaQuery.of(context).size.width * 4/5,
                          child: Text (
                            "Waiting to automatically detect SMS sent to your mobile number.",
                            textAlign: TextAlign.center,
                            style: TextStyle (
                                fontSize: 17.0,
                                fontWeight: FontWeight.w400,
                                color: Colors.black
                            ),
                          ),
                        ),
                        SizedBox(height: 20,),
                        Container (
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: PinView (
                              count: 6, // count of the fields, excluding dashes
                              autoFocusFirstField: false,
                              dashPositions: [3], // describes the dash positions (not indexes)
                              dashStyle: TextStyle(color: Colors.black,fontSize: 16),
                              style: TextStyle(color: Colors.black,fontSize: 20),
                              sms: SmsListener (
                                // this class is used to receive, format and process an sms
                                  from: "56161174",
                                  formatBody: (String body){
                                    return body;
                                  }
                              ),
                              submit: (String pin){
                                signIn(pin);
                              } // gets triggered when all the fields are filled
                          ),
                        ),
                        SizedBox(height: 90,),
                        Container (
                          width: MediaQuery.of(context).size.width * 4/5,
                          child: Text (
                            "Did not receive sms? Resend SMS.",
                            textAlign: TextAlign.center,
                            style: TextStyle (
                                fontSize: 17.0,
                                fontWeight: FontWeight.w400,
                                color: Colors.black
                            ),
                          ),
                        ),
                        SizedBox(height: 20,),
                        RaisedButton(
                          elevation: 5.0,
                          splashColor: Colors.white,
                          onPressed: verify,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Resend SMS',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 18.0),
                            ),
                          ),
                          color: Colors.black,
                        ),
                      ],
                    )
                )
              ],
            ),
          )
      ),
    );
  }
  signIn(pin) {
    if (pin.length != 6) {
      //  TODO: show error
    }
    final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, smsCode: pin);
    FirebaseAuth.instance.signInWithCredential(credential)
        .then((user) {

      if(user!=null){
        FirebaseFirestore.instance
            .collection('Users')
            .doc(user.user.uid.toString())
            .get()
            .then((DocumentSnapshot snap) {
          if (snap.exists) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChooseName()));

          }
        });
      }else{

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));

      }

    }).catchError((e) {
      print(e);
    });
    // FirebasePhoneAuth.signInWithPhoneNumber(smsCode: code);
  }

}
