import 'dart:async';

import 'package:cabiee/pageview/choosecab.dart';
import 'package:cabiee/models/size_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



// ignore: must_be_immutable
class SLOM extends StatefulWidget {
  PointLatLng location;
  DateTime date;
  String id;
  SLOM(this.location, this.date,this.id);
  @override
  _SLOMState createState() => _SLOMState();
}

class _SLOMState extends State<SLOM> with TickerProviderStateMixin {

  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  int _markerIdCounter = 0;
  Completer<GoogleMapController> _mapController = Completer();
  AnimationController _animationController;
  Animation _animation2;
  String myLocation;
  Animation _animation;
  PointLatLng _location;

  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    if (widget.location != null) {
      MarkerId markerId = MarkerId(_markerIdVal());
      LatLng position = LatLng(widget.location.latitude, widget.location.longitude);
      Marker marker = Marker(
        markerId: markerId,
        position: position,
        draggable: false,
      );

      setState(() {
        _markers[markerId] = marker;
      });
      Future.delayed(Duration(seconds: 1), () async {
        GoogleMapController controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: position,
              zoom: 18.0,
            ),
          ),
        );
      });
    }
  }
  getMyLocayion() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(widget.location.latitude, widget.location.longitude);
    var first = placemarks.first;
    setState(() {
      myLocation = first.name;
      _location= widget.location;
    });
  }
  String _markerIdVal({bool increment = false}) {
    String val = 'marker_id_$_markerIdCounter';
    if (increment) _markerIdCounter++;
    return val;
  }
  var tween = Tween(begin: Offset(0.0,1.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeIn));

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: 1500), vsync: this);
    _animation2 = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    getMyLocayion();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Choose Your Destination'),
        ),
        body: Stack(
            children: [
              widget.location == null
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
              ) : FadeTransition(
                opacity: _animation,
                child: GoogleMap(
                  markers: Set<Marker>.of(_markers.values),
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.location.latitude, widget.location.longitude),
                    zoom: 12.0,
                  ),
                  myLocationEnabled: true,
                  onCameraMove: (CameraPosition position) async {

                    if(_markers.length > 0) {
                      MarkerId markerId = MarkerId(_markerIdVal());
                      Marker marker = _markers[markerId];
                      Marker updatedMarker = marker.copyWith(
                        positionParam: position.target,
                      );
                      setState(() {
                        _markers[markerId] = updatedMarker;
                      });
                      getMovedMarkerLocation(position);
                    }
                  },
                ),
              ),
              SlideTransition(
                position: _animation2.drive(tween),
                child:Align(
                    alignment: Alignment.bottomCenter,
                    child: Material(
                      elevation: 10,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                      child: Container(
                        height: SizeConfig.safeBlockVertical * 25,
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
                                padding: const EdgeInsets.only(top: 20, left: 30, right: 30),
                                child: InkWell(
                                  onTap: (){
                                  },
                                  child: TextFormField(
                                    style: TextStyle(color: Colors.white),
                                    enabled: false,
                                    decoration: InputDecoration(
                                      labelText:myLocation==null?'Loading...':"Your Location:  "+myLocation.toString(),
                                      filled: true,
                                      fillColor: Colors.black,
                                      labelStyle:  TextStyle(color: Colors.white),
                                      prefixIcon: Icon(Icons.location_on,color:Colors.white,),
                                      hintStyle: TextStyle(color: Colors.white54),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: new BorderRadius.circular(10.0),
                                        borderSide: new BorderSide(color: Colors.white,width: 0.0),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: new BorderRadius.circular(10.0),
                                        borderSide: new BorderSide(color: Colors.amberAccent),
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
                                      Navigator.of(context).push(_createRoute());
                                      FirebaseFirestore.instance.collection('Users').doc(widget.id).collection('locations').add({
                                        'place':myLocation.toString(),
                                        'coords':GeoPoint(_location.latitude, _location.longitude),
                                        'timestamp':Timestamp.now()
                                      });
                                    },
                                    splashColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0)),
                                    color: Colors.black,
                                    elevation: 0,
                                    icon: Icon(Icons.done),
                                    textColor: Colors.white,
                                    label: Text('Set Location',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    )),
              ),


            ]),
      ),
    );
  }
  getMovedMarkerLocation(position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.target.latitude, position.target.longitude);
    var first = placemarks.first;
    setState(() {
      _location=PointLatLng(position.target.latitude, position.target.longitude);
      myLocation=first.name;
    });

  }
  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SelectCab(widget.location,_location,widget.date),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
