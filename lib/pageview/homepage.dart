import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:cabiee/navigationdrawercomp/navigationdrawer.dart';
import 'package:cabiee/pageview/add_destination.dart';
import 'package:cabiee/models/size_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyAppHome extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyAppHome> with TickerProviderStateMixin {
  Completer<GoogleMapController> mapController = Completer();
  Placemark places;
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

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var markerCenter;
  AnimationController _animationController;
  Animation _animation2;
  Animation _animation;
  DateTime _date;
  Animation _animation3;
  LatLng _centerPosition;
  BitmapDescriptor sourceIcon;
  Position currentLocation;
  var tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero)
      .chain(CurveTween(curve: Curves.bounceInOut));
  var tween2 = Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
      .chain(CurveTween(curve: Curves.ease));
  FocusNode fieldNode = FocusNode();

  @override
  void initState() {
    populateClients();
    getMarker();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 1500), vsync: this);
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.ease);
    _animation2 = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    _animation3 = Tween(begin: 0.0, end: 1.0).animate(_animationController);

    super.initState();
  }
  Future<Position> locateUser() async {
    return Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  getUserLocation() async {
    currentLocation = await locateUser();
    setState(() {
      _centerPosition = LatLng(currentLocation.latitude, currentLocation.longitude);
    });
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

  Future<String> getUserLocation2() async {
    _centerPosition = LatLng(currentLocation.latitude, currentLocation.longitude);
    _animationController.forward();
    locationMarker();
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
    setState(() {
      markers[markerId] = marker;
      markerCenter = marker;
    });
  }

  populateClients() {
    FirebaseFirestore.instance.collection('Drivers').get().then((value) {
      value.docs.forEach((element) {
        initMarker(element['coords'].latitude,element['coords'].longitude, element.id);
      });
    });
  }

  initMarker(lat,lng,docid) async {
    currentLocation = await locateUser();
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
      position: LatLng(lat,lng),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(
                                height: 5,
                              ),
                              Text('Loading...')
                            ],
                          ),
                        ),
                      );
                    } else if (snap.hasError) {
                      return Center(child: Text('Something went wrong'));
                    }
                    return FadeTransition(
                      opacity: _animation,
                      child: GoogleMap(
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                        mapType: MapType.normal,
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                            target: LatLng(_centerPosition.latitude,
                                _centerPosition.longitude),
                            zoom: 10),
                        markers: Set<Marker>.of(markers.values),
                      ),
                    );
                  }),
              SlideTransition(
                position: _animation3.drive(tween2),
                child: Material(
                  elevation: 10,
                  child: Container(
                      color: Colors.lightBlue,
                      height: SizeConfig.safeBlockVertical * 6,
                      child: Center(
                        child: Text(
                          ' Stay Safe From Covid-19, Our Drivers Follow All Safety\n              Procedures And Regular Sensitisation',
                          style: TextStyle(color: Colors.white),
                        ),
                      )),
                ),
              ),
              SlideTransition(
                position: _animation2.drive(tween),
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Material(
                      elevation: 10,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 2.0,
                                color: Colors.black26,
                                spreadRadius: 2.0)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 20, left: 30, right: 30),
                                child: InkWell(
                                  onTap: () {
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
                                          TextStyle(color: Colors.white),
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
                                          onPressed: () {}),
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
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: ButtonTheme(
                                  minWidth: 10,
                                  height: 40,
                                  child: RaisedButton.icon(
                                    onPressed: () {
                                      DatePicker.showDateTimePicker(
                                        context,
                                        showTitleActions: true,
                                        onChanged: (date) {
                                          print('change $date in time zone ' +
                                              date.timeZoneOffset.inHours
                                                  .toStringAsFixed(2)
                                                  .toString());
                                        },
                                        onCancel: () {
                                          setState(() {
                                            _date = null;
                                          });
                                        },
                                        onConfirm: (date) {
                                          setState(() {
                                            _date = date;
                                          });
                                        },
                                      );
                                    },
                                    splashColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0)),
                                    color: Colors.black,
                                    elevation: 0,
                                    icon: Icon(Icons.timer),
                                    textColor: Colors.white,
                                    label: Text(
                                        _date != null
                                            ? "Schedule |$_date"
                                            : "Schedule | Now",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            )
                          ],
                        ),
                      ),
                    )),
              )
            ],
          ),
          endDrawer: Drawer(
            child: AppDrawer(),
          )),
    );
  }

  Route _createRoute() {
    print(_centerPosition.latitude + _centerPosition.longitude);
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => AddDestination(
          _centerPosition.latitude, _centerPosition.longitude, _date),
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
}
