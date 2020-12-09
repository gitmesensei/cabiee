import 'dart:ui';

import 'package:cabiee/onboardingcomp/login.dart';
import 'package:cabiee/models/size_config.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  VideoPlayerController _controller;
  AnimationController _animationController;
  Animation _animation;
  Image myImage;
  @override
  void initState() {
    myImage= Image.asset('assets/logo.png');
    super.initState();
    _animationController =
        AnimationController( duration: Duration(seconds: 2), vsync: this);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    _controller = VideoPlayerController.asset('assets/splash.mp4')
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(true);
        _controller.setVolume(0);
        setState(() {});
      });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(myImage.image, context);
  }
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward();
    SizeConfig().init(context);
    return Scaffold(
        body: Stack(
      children: [
        FadeTransition(
          opacity: _animation,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size?.width ?? 0,
                height: _controller.value.size?.height ?? 0,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.black26),
        ),
        Container(
          margin: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical*60),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FadeTransition(
                    opacity: _animation,
                    child: Container(
                      height: 100,
                      width: 100,
                      padding: EdgeInsets.only(bottom: 20),
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
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(left: 20, right: 20, top: 10),
                      child: Text(
                        'Cabiee',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 2,
                              )
                            ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Center(
          child: Container(
            margin: EdgeInsets.only(left: 20, right: 20, top: 0),
            child: Text(
              'Book Your Cab On The Go !!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 2,
                    )
                  ]),
            ),
          ),
        ),
        Center(
          child: Container(
            margin: EdgeInsets.only(top: SizeConfig.blockSizeVertical*60),
            child: Text(
              '  By clicking this you accept our privacy policy and terms & conditions  ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                 ),
            ),
          ),
        ),
        Center(
          child: Container(
            margin: EdgeInsets.only(top: SizeConfig.blockSizeVertical*80),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white,width: 1)
            ),
            child: ButtonTheme(
              height: 50,
              child: RaisedButton(onPressed:(){
                Navigator.of(context).push(_createRoute());

              },
                  color: Colors.black,
                  elevation: 10,
                  splashColor: Colors.white,
                  child: Text('BOOK YOUR RIDE',
                    style: TextStyle(
                      color: Colors.white,
                      wordSpacing: 2,
                      letterSpacing: 1,
                      fontSize: 18,
                    ),)),
            ),
          ),
        )

      ],
    ));
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeIn;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
