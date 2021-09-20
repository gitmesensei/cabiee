import 'dart:async';
import 'dart:io';
import 'package:cabiee/global_variables.dart';
import 'package:cabiee/pageview/add_home.dart';
import 'package:cabiee/pageview/add_pickup.dart';
import 'package:cabiee/pageview/set_location_on_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoding/geocoding.dart';
import '../models/Place.dart';
import 'add_work.dart';

// ignore: must_be_immutable
class AddDestination extends StatefulWidget {
  double latitude;
  double longitude;

  AddDestination(this.latitude, this.longitude);

  @override
  _AddDestinationState createState() => _AddDestinationState();
}

String kGoogleApiKey;

class _AddDestinationState extends State<AddDestination> {
  TextEditingController _searchController = new TextEditingController();
  TextEditingController _searchController2 = new TextEditingController();

  Timer _throttle;

  String myLocation;
  bool myDestinationActive = true;
  PointLatLng _location;
  PointLatLng _destination;
  String id;

  FocusNode fieldNode = FocusNode();

  String _heading;
  String _home;
  String _work;
  GeoPoint homePoint;
  GeoPoint workPoint;
  List<Place> _placesList;
  bool _showRecent;
  String destinationName;

  @override
  void initState() {
    getMyLocayion();
    _loadCurrentUser();
    print(widget.latitude + widget.longitude);
    if (Platform.isAndroid) {
      // Android-specific code
      kGoogleApiKey = Global.kAndroidGoogleApiKey;
    } else if (Platform.isIOS) {
      // iOS-specific code
      kGoogleApiKey = Global.kIOSGoogleApiKey;
    }
    super.initState();
    _heading = "Suggestions";
    _showRecent = true;
  }

  void _loadCurrentUser() async {
    User user =FirebaseAuth.instance.currentUser;
      setState(() {
        this.id = user.uid.toString();
      });
    _getHome();
    _getWork();
  }

  getMyLocayion() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(widget.latitude, widget.longitude);
    var first = placemarks.first;
    setState(() {
      myLocation = first.name;
      _location = PointLatLng(widget.latitude, widget.longitude);
    });
    _searchController2 = TextEditingController(text: myLocation);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchController2.dispose();
    if (_throttle != null) {
      _throttle.cancel();
    }
    super.dispose();
  }

  void getLocationResults(String input) async {
    if (input.isEmpty) {
      setState(() {
        _heading = "Recent";
        _showRecent = true;
      });
    } else {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String type = '(regions)';
      String request = '$baseURL?input=$input&key=$kGoogleApiKey&type=$type';
      Response response = await Dio().get(request);

      final predictions = response.data['predictions'];
      List<Place> _displayResults = [];
      for (var i = 0; i < predictions.length; i++) {
        String place = predictions[i]['description'];

        _displayResults.add(Place(place));
      }

      setState(() {
        _heading = "Results";
        _showRecent = false;
        _placesList = _displayResults;
      });
    }
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

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ListView(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 0.0, right: 10.0, bottom: 0),
                child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 30, right: 30),
              child: TextFormField(
                style: TextStyle(color: Colors.white, fontSize: 16),
                controller: _searchController2,
                decoration: InputDecoration(
                  labelText: 'My Location',
                  labelStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(
                    Icons.my_location,
                    color:
                        fieldNode.hasFocus ? Colors.amberAccent : Colors.white,
                    size: 20,
                  ),
                  hintStyle: TextStyle(color: Colors.white54),
                  suffixIcon: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: fieldNode.hasFocus
                            ? Colors.amberAccent
                            : Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _searchController2.clear()),
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                    borderSide: new BorderSide(color: Colors.white, width: 0.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                    borderSide: new BorderSide(color: Colors.amberAccent),
                  ),
                ),
                onChanged: (text) {
                  if (_throttle?.isActive ?? false) _throttle.cancel();
                  _throttle = Timer(const Duration(milliseconds: 500), () {
                    getLocationResults(text);
                  });
                },
                onTap: () {
                  setState(() {
                    myDestinationActive = false;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 20, left: 30, right: 30, bottom: 20),
              child: TextFormField(
                style: TextStyle(color: Colors.white, fontSize: 16),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_on,
                    color:
                        fieldNode.hasFocus ? Colors.amberAccent : Colors.white,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: fieldNode.hasFocus
                            ? Colors.amberAccent
                            : Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _searchController.clear()),
                  fillColor: Colors.white,
                  labelText: 'Destination',
                  labelStyle: TextStyle(color: Colors.white),
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                    borderSide: new BorderSide(color: Colors.white, width: 0.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                    borderSide: new BorderSide(color: Colors.amberAccent),
                  ),
                ),
                onChanged: (text) {
                  if (_throttle?.isActive ?? false) _throttle.cancel();
                  _throttle = Timer(const Duration(milliseconds: 500), () {
                    getLocationResults(text);
                  });
                },
                onTap: () {
                  setState(() {
                    myDestinationActive = true;
                  });
                },
              ),
            ),
            _showRecent == false
                ? ListTile(
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 0.0, right: 10.0, bottom: 0),
                        child: Text(_heading,
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  )
                : SizedBox(),
            _showRecent == false
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: _placesList.length,
                    itemBuilder: (BuildContext context, int index) =>
                        buildPlaceCard(context, index),
                  )
                : SizedBox(
                    width: 0.1,
                    height: 0.1,
                  ),
            ListTile(
              leading: Icon(
                Icons.home,
                color: Colors.white,
              ),
              title: Text(
                _home ?? 'Add Home',
                style: TextStyle(color: Colors.white),
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
                              _location,
                              PointLatLng(
                                  homePoint.latitude, homePoint.longitude),_home)));
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.work,
                color: Colors.white,
              ),
              title: Text(
                _work ?? 'Add Work',
                style: TextStyle(color: Colors.white),
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
                              _location,
                              PointLatLng(
                                  workPoint.latitude, workPoint.longitude),_work)));
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.location_on,
                color: Colors.white,
              ),
              title: Text(
                ' Set Location On Map',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SLOM(_location, id,myLocation)));
              },
            ),
            SizedBox(
              height: 10,
            ),
            _showRecent == false
                ? SizedBox()
                : ListTile(
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 0.0, right: 10.0, bottom: 0),
                        child: Text(_heading,
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
            _showRecent == false
                ? SizedBox(
                    width: 0.1,
                    height: 0.1,
                  )
                : buildRecentPlaceCard(context),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.amberAccent,
          onPressed: () {
            if (_searchController2.text.isNotEmpty &
                _searchController.text.isNotEmpty) {
              Navigator.of(context).push(_createRoute());
              print(_searchController2.text + _searchController.text);
            }
          },
          label: Text('Proceed', style: TextStyle(color: Colors.black)),
          icon: Icon(
            Icons.chevron_right,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget buildPlaceCard(BuildContext context, int index) {
    return Container(
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: ListTile(
        title: Text(_placesList[index].place,
            style: TextStyle(color: Colors.white)),
        leading: Icon(
          Icons.location_on,
          color: Colors.white,
        ),
        onTap: () async {
          var addresses = await Geocoder.local
              .findAddressesFromQuery(_placesList[index].place);
          var first = addresses.first;
          setState(() {
            if (myDestinationActive == true) {
              _destination = PointLatLng(
                  first.coordinates.latitude, first.coordinates.longitude);
              _searchController =
                  TextEditingController(text: _placesList[index].place);
              destinationName=addresses.toString();
            } else {
              _location = PointLatLng(
                  first.coordinates.latitude, first.coordinates.longitude);
              _searchController2 =
                  TextEditingController(text: _placesList[index].place);
            }
          });
          FirebaseFirestore.instance
              .collection('Users')
              .doc(id)
              .collection('locations')
              .add({
            'place': _placesList[index].place,
            'coords': GeoPoint(_destination.latitude, _destination.longitude),
            'timestamp': Timestamp.now()
          });
        },
      ),
    );
  }

  Widget buildRecentPlaceCard(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(id)
            .collection('locations')
            .limit(15)
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
                      color: Colors.white,
                    ),
                    title: Text(ds['place'],
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        if (myDestinationActive == true) {
                          _destination = PointLatLng(
                              ds['coords'].latitude, ds['coords'].longitude);
                          _searchController =
                              TextEditingController(text: ds['place']);
                          destinationName=ds['place'];
                        } else {
                          _location = PointLatLng(
                              ds['coords'].latitude, ds['coords'].longitude);
                          _searchController2 =
                              TextEditingController(text: ds['place']);
                        }
                      });
                    },
                  ),
                );
              });
        });
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          AddPickup(_location, _destination,destinationName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
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
