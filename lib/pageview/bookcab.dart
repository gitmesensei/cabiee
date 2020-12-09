import 'package:cabiee/models/size_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ignore: must_be_immutable
class BookCab extends StatefulWidget {
  String name;
  String image;
  double val;
  DateTime date;
  PointLatLng myLocation;
  BookCab(this.name, this.image, this.val, this.date, this.myLocation);

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
  Timer _clockTimer;
  Timer _locationTimer;
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
  @override
  void dispose() {
    _animationController.dispose();
    _clockTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  populateClients(){
    FirebaseFirestore.instance.collection('Drivers').get().then((value){

      value.docs.forEach((element) {
        initMarker(element['coords'].latitude,element['coords'].longitude, element.id);
      });

    });
  }

  initMarker(lat,lng,docid) async{
    double calculateDistance(lat1, lon1, lat2, lon2) {
      var p = 0.017453292519943295;
      var c = cos;
      var a = 0.5 -
          c((lat2 - lat1) * p) / 2 +
          c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
      return 12742 * asin(sqrt(a));
    }
    List<dynamic> data = [];
    data.add({"lat": lat, "lng": lng});
    print(data);
    double totalDistance = 0;
    for(var i = 0; i < data.length; i++){

      totalDistance += calculateDistance(widget.myLocation.latitude,widget.myLocation.longitude,data[i]["lat"], data[i]["lng"]);
    }
    if(totalDistance<2.5){
      FirebaseFirestore.instance.collection('Drivers').doc(docid).get().then((value){
        if(value['ongoing']==false){
          List<dynamic> nList = [];
          nList.add({
            "td":totalDistance,
            "docid":docid
          });
        }
      });
    }


  }
  void checkForRequest(List<dynamic> as) async{
    print(as.first);
  }
  @override
  void initState() {
    super.initState();
    populateClients();
    _animationController = AnimationController(duration: Duration(milliseconds: 1500), vsync: this);
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
                            LinearProgressIndicator(backgroundColor: Colors.amber,),
                            _items(),
                            ButtonTheme(
                              height: 45,
                              child: RaisedButton(
                                onPressed: () => Navigator.pop(context),
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
                    onPressed: () => Navigator.pop(context)))
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
