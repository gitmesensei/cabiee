import 'package:cabiee/models/size_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ignore: must_be_immutable
class BookCab extends StatefulWidget {
  String name;
  String image;
  double val;
  PointLatLng myLocation;
  PointLatLng destination;
  String locationName;
  String destinationName;
  String selectedOption;

  BookCab(this.name, this.image, this.val, this.myLocation, this.destination, this.locationName, this.destinationName, this.selectedOption);

  @override
  _PickupState createState() => _PickupState();
}

class _PickupState extends State<BookCab> with SingleTickerProviderStateMixin {
  Completer<GoogleMapController> _mapController = Completer();
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  var tween = Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
      .chain(CurveTween(curve: Curves.elasticInOut));
  AnimationController _animationController;
  Animation _animation2;
  Animation _animation;
  double totalDistance = 0.0;
  int bottomSelectedIndex = 0;
  String id;
  String name;
  String image;
  String phoneNumber;
  PageController pageController = PageController(
    initialPage: 0,
  );

  void pageChanged(int index) {
    setState(() {
      this.bottomSelectedIndex = index;
    });
  }

  void bottomTapped(int index) {
    setState(() {
      bottomSelectedIndex = index;
      pageController.animateToPage(index,
          duration: Duration(milliseconds: 100), curve: Curves.easeIn);
    });
  }

  Widget buildPageView() {
    return PageView(
      controller: pageController,
      onPageChanged: (index) {
        pageChanged(index);
      },
      children: <Widget>[Screen1(), Screen2(), Screen3()],
    );
  }

  void _loadCurrentUser() async {
    User user = FirebaseAuth.instance.currentUser;
    setState(() {
      this.id = user.uid;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void fetchUserDetails() async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(firebaseUser.uid)
        .get()
        .then((value) {
      setState(() {
        name = value.data()['name'];
        image = value.data()['image'];
        phoneNumber = value.data()['number'];
        print(name);
      });
    }).whenComplete(() => sendRideRequest());
  }

  void sendRideRequest() async {
    await FirebaseFirestore.instance.collection('RideRequest').doc(id).set({
      'name': name,
      'image': image,
      'phone_number': phoneNumber,
      'createdAt': DateTime.now(),
      'driver_id': 'waiting',
      "status":'waiting',
      'payment_mode':widget.selectedOption,
      'location': GeoPoint(widget.myLocation.latitude, widget.myLocation.longitude),
      'locationName':widget.locationName,
      'destination': GeoPoint(widget.destination.latitude, widget.destination.longitude),
      'destinationName':widget.destinationName,
      'userId': id,
      'fare': widget.val
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    fetchUserDetails();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 1500), vsync: this);
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animation2 = Tween(begin: 0.0, end: 1.0).animate(_animationController);

    /// origin marker
    _addMarker(LatLng(widget.myLocation.latitude, widget.myLocation.longitude),
        "origin", BitmapDescriptor.defaultMarkerWithHue(198.4));
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            widget.myLocation == null
                ? Center(
                    child: Container(
                      color: Theme.of(context).canvasColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(
                            height: 5,
                          ),
                          Text('loading...')
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _animation,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                          target: LatLng(widget.myLocation.latitude,
                              widget.myLocation.longitude),
                          zoom: 13),
                      myLocationEnabled: false,
                      tiltGesturesEnabled: true,
                      compassEnabled: true,
                      scrollGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      onMapCreated: _onMapCreated,
                      markers: Set<Marker>.of(markers.values),
                      polylines: Set<Polyline>.of(polylines.values),
                    ),
                  ),
            SlideTransition(
              position: _animation2.drive(tween),
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    elevation: 10,
                    child: Container(
                        height: 300,
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LinearProgressIndicator(
                              backgroundColor: Colors.amber,
                              valueColor:AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                            _items(),
                            ButtonTheme(
                              height: 45,
                              child: RaisedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('RideRequest')
                                      .doc(id)
                                      .delete();
                                  Navigator.pop(context);
                                },
                                color: Colors.amber,
                                child: Center(
                                  child: Text(
                                    'Cancel Booking',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )),
                  )),
            ),
            Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                    ),
                    onPressed: () async{
                      await FirebaseFirestore.instance
                          .collection('RideRequest')
                          .doc(id)
                          .delete();
                      Navigator.pop(context);
                    }))
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    Future.delayed(Duration(seconds: 2), () async {
      GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(widget.myLocation.latitude, widget.myLocation.longitude),
            zoom: 19.0,
          ),
        ),
      );
    });
  }

  Widget _items() {
    return Container(
      height: 220,
      child: Stack(
        children: [
          Container(
            child: buildPageView(),
          ),
          Center(
              child: Container(
            margin: EdgeInsets.only(top: 200),
            width: 150,
            height: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  height: bottomSelectedIndex == 0 ? 12 : 8,
                  width: bottomSelectedIndex == 0 ? 12 : 8,
                  decoration: BoxDecoration(
                      color: bottomSelectedIndex == 0
                          ? Colors.amber
                          : Colors.amberAccent,
                      borderRadius: BorderRadius.circular(12)),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  height: bottomSelectedIndex == 1 ? 12 : 8,
                  width: bottomSelectedIndex == 1 ? 12 : 8,
                  decoration: BoxDecoration(
                      color: bottomSelectedIndex == 1
                          ? Colors.amber
                          : Colors.amberAccent,
                      borderRadius: BorderRadius.circular(12)),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  height: bottomSelectedIndex == 2 ? 12 : 8,
                  width: bottomSelectedIndex == 2 ? 12 : 8,
                  decoration: BoxDecoration(
                      color: bottomSelectedIndex == 2
                          ? Colors.amber
                          : Colors.amberAccent,
                      borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ))
        ],
      ),
    );
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  // ignore: non_constant_identifier_names
  Widget Screen1() {
    return Container(
      height: 180,
      child: Column(
        children: [
          GestureDetector(
              child: Image.asset(
            'assets/b1.jpg',
            width: 140.0,
            height: 140.0,
            fit: BoxFit.contain,
          )),
          Container(
            child: Text(
              'SANITIZED RIDES',
              style: TextStyle(
                  fontSize: 20.0,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway'),
              textAlign: TextAlign.center,
            ),
            margin: EdgeInsets.only(top: 20.0),
          ),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget Screen2() {
    return Container(
      height: 180,
      child: Column(
        children: [
          GestureDetector(
              child: Image.asset(
            'assets/b2.jpg',
            width: 140.0,
            height: 140.0,
            fit: BoxFit.contain,
          )),
          Container(
            child: Text(
              ' ALWAYS MASK ON',
              style: TextStyle(
                  fontSize: 20.0,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway'),
              textAlign: TextAlign.center,
            ),
            margin: EdgeInsets.only(top: 20.0),
          ),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget Screen3() {
    return Container(
      height: 180,
      child: Column(
        children: [
          GestureDetector(
              child: Image.asset(
            'assets/b3.jpg',
            width: 140.0,
            height: 140.0,
            fit: BoxFit.contain,
          )),
          Container(
            child: Text(
              'SAFETY & PROTECTION',
              style: TextStyle(
                  fontSize: 20.0,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway'),
              textAlign: TextAlign.center,
            ),
            margin: EdgeInsets.only(top: 20.0),
          ),
        ],
      ),
    );
  }
}
