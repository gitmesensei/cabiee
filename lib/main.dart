import 'package:cabiee/onboardingcomp/loading.dart';
import 'package:cabiee/pageview/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.amberAccent,
        accentColor: Colors.black,
        appBarTheme: AppBarTheme(color: Colors.amberAccent,
            iconTheme: IconThemeData(color: Colors.black,size: 30),
        ),
      ),
      home:Loading()
    )
    );
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyAppHome();
  }
}

