import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:cabiee/navigationdrawercomp/navigationdrawer.dart';
import 'package:cabiee/pageview/add_destination.dart';
import 'package:cabiee/models/size_config.dart';
import 'package:cabiee/pageview/add_home.dart';
import 'package:cabiee/pageview/add_work.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'add_pickup.dart';

class MyAppHome extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyAppHome> with TickerProviderStateMixin {
  Completer<GoogleMapController> mapController = Completer();
  void _onMapCreated(GoogleMapController controller) async {
    mapController.complete(controller);
    Future.delayed(Duration(seconds: 1), () async {
      GoogleMapController controller = await mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_centerPosition.latitude, _centerPosition.longitude),
            zoom: 16.0,
          ),
        ),
      );
    });
  }

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var markerCenter;
  AnimationController _animationController;
  Animation _animation;
  String id;
  Animation _animation3;
  LatLng _centerPosition;
  BitmapDescriptor sourceIcon;
  BitmapDescriptor locationIcon;
  Position currentLocation;
  var tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero)
      .chain(CurveTween(curve: Curves.bounceInOut));
  var tween2 = Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
      .chain(CurveTween(curve: Curves.ease));
  FocusNode fieldNode = FocusNode();
  String _home;
  String _work;
  GeoPoint homePoint;
  GeoPoint workPoint;


  @override
  void initState() {
    populateClients();
    getMarker();
    _loadCurrentUser();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 1500), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.ease);
    _animation3 = Tween(begin: 0.0, end: 1.0).animate(_animationController);

    super.initState();
  }

  void _loadCurrentUser() async {
    User user =FirebaseAuth.instance.currentUser;
    setState(() {
      this.id = user.uid.toString();
    });
    _getHome();
    _getWork();
  }
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }
  getMarker() async {
    final Uint8List markerIcon = await getBytesFromAsset('assets/car.png', 120);
    setState(() {
      sourceIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }
  _getHome() async {

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(id)
        .collection('home').get()
        .then((value) {
      value.docs.forEach((element) {
        setState(() {
          homePoint = element['coords'];
          _home = element['place'];
        });
      });
    });
  }

  _getWork() async {

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(id)
        .collection('work')
        .get()
        .then((value) {
      value.docs.forEach((element) {
        setState(() {
          workPoint = element['coords'];
          _work = element['place'];
        });
      });
    });
  }

  Future<Position> locateUser() async {
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }

  Future<String> getUserLocation2() async {
    currentLocation = await locateUser();
    setState(() {
      _centerPosition =
          LatLng(currentLocation.latitude, currentLocation.longitude);
    });
    return _centerPosition.toString();
  }

  locationMarker() {
    var markerIdVal = 'my location';
    final MarkerId markerId = MarkerId(markerIdVal);
    final Marker marker = Marker(
      markerId: markerId,
      infoWindow:
      InfoWindow(title: 'My Location', snippet: _centerPosition.toString()),
      position: LatLng(_centerPosition.latitude, _centerPosition.longitude),
    );
    markers[markerId] = marker;
    markerCenter = marker;
  }

  populateClients() {
    FirebaseFirestore.instance.collection('Drivers').get().then((value) {
      value.docs.forEach((element) {
        initMarker(element['coords'].latitude,element['coords'].longitude, element.id,element['heading']);
      });
    });
  }

  initMarker(lat,lng,docid,heading) async {
    currentLocation = await locateUser();
    print(currentLocation);
    double calculateDistance(lat1, lon1, lat2, lon2) {
      var p = 0.017453292519943295;
      var c = cos;
      var a = 0.5 -
          c((lat2 - lat1) * p) / 2 +
          c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
      return 12742 * asin(sqrt(a));
    }

    print(docid);
    List<dynamic> data = [];
    data.add({"lat": lat, "lng": lng});
    print(data);
    double totalDistance = 0;
    for (var i = 0; i < data.length; i++) {
      totalDistance += calculateDistance(currentLocation.latitude,
          currentLocation.longitude, data[i]["lat"], data[i]["lng"]);
    }
    print(totalDistance);
    var markerIdVal = docid;
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      icon: sourceIcon,
      rotation: heading,
      position: LatLng(lat,lng),
      draggable: false,
      zIndex: 2,
      flat: true,
      anchor: Offset(0.5, 0.5),
    );
    if (totalDistance < 2.5) {
      setState(() {
        markers[markerId] = marker;
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).canvasColor,
          appBar: AppBar(
              automaticallyImplyLeading: false,
              iconTheme: IconThemeData(color: Colors.black, size: 30),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Colors.black,
                        size: 30,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'CABIEE',
                        style: TextStyle(color: Colors.black, letterSpacing: 2),
                      ),
                    ],
                  ),
                ],
              )),
          body:SlidingUpPanel(
            color: Colors.amberAccent,
            minHeight:200,
            panel: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.drag_handle_sharp),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 0, left: 30, right: 30),
                    child: InkWell(
                      onTap: (){
                        Navigator.of(context).push(_createRoute());
                      },
                      child: TextFormField(
                        style: TextStyle(color: Colors.white),
                        enabled: false,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Where Do You Want To Go ?',
                          filled: true,
                          fillColor: Colors.black,
                          labelStyle:
                          TextStyle(color: Colors.white,fontSize: 14),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                          hintStyle:
                          TextStyle(color: Colors.white54),
                          suffixIcon: IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              onPressed: () {
                              }),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                            new BorderRadius.circular(10.0),
                            borderSide: new BorderSide(
                                color: Colors.white, width: 0.0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                            new BorderRadius.circular(10.0),
                            borderSide: new BorderSide(
                                color: Colors.amberAccent),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.home,
                      color: Colors.black,
                    ),
                    title: Text(
                      _home ?? 'Add Home',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      if (homePoint == null) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddHome(homePoint, id)));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddPickup(
                                    PointLatLng(_centerPosition.latitude, _centerPosition.longitude),
                                    PointLatLng(
                                        homePoint.latitude, homePoint.longitude),_home)));
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.work,
                      color: Colors.black,
                    ),
                    title: Text(
                      _work ?? 'Add Work',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      if (workPoint == null) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddWork(workPoint, id)));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddPickup(
                                    PointLatLng(_centerPosition.latitude, _centerPosition.longitude),
                                    PointLatLng(
                                        workPoint.latitude, workPoint.longitude),_work)));
                      }
                    },
                  ),
                  buildRecentPlaceCard(context)

                ],
              ),
            ),
            body: Stack(
              children: <Widget>[
                FutureBuilder<String>(
                    future: getUserLocation2(),
                    builder: (BuildContext context, AsyncSnapshot<String> snap) {
                      if (!snap.hasData) {
                        print(snap.data);
                        return Center(
                          child: Container(
                            color: Theme.of(context).canvasColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor:AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text('Loading...')
                                ],
                              ),
                            ),
                          ),
                        );
                      } else if (snap.hasError) {
                        return Center(child: Text('Still waiting'));
                      }
                      locationMarker();
                      return GoogleMap(
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                        mapType: MapType.normal,
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                            target: LatLng(_centerPosition.latitude,
                                _centerPosition.longitude),
                            zoom: 10),
                        markers: Set<Marker>.of(markers.values),
                      );
                    }),
                SlideTransition(
                  position: _animation3.drive(tween2),
                  child: Material(
                    elevation: 10,
                    child: Container(
                        color: Colors.lightBlue,
                        padding: EdgeInsets.all(5),
                        height: SizeConfig.safeBlockVertical * 6,
                        child: Center(
                          child: Text(
                            ' Stay Safe From Covid-19, Our Drivers Follow All Safety Procedures And Regular Sensitisation',
                            textAlign: TextAlign.center,
                            style:
                            TextStyle(color: Colors.white),
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ) ,
          endDrawer: Drawer(
            child: AppDrawer(),
          )),
    );
  }

  Route _createRoute() {
    print(_centerPosition.latitude + _centerPosition.longitude);
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => AddDestination(
          _centerPosition.latitude, _centerPosition.longitude),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Widget buildRecentPlaceCard(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(id)
            .collection('locations')
            .limit(4)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snap) {
          if (!snap.hasData)
            return new Center(
              child: Text(
                'no data available',
                style: TextStyle(color: Colors.white),
              ),
            );
          return ListView.builder(
              itemCount: snap.data.docs.length == null
                  ? 0
                  : snap.data.docs.length,
              scrollDirection: Axis.vertical,
              primary: false,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snap.data.docs[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 0),
                  child: ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.black,
                    ),
                    title: Text(ds['place'],
                        style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddPickup(
                                  PointLatLng(_centerPosition.latitude,_centerPosition.longitude),PointLatLng(ds['coords'].latitude, ds['coords'].longitude),ds['place'])));
                    },
                  ),
                );
              });
        });
  }

}
