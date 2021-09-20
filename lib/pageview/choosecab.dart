import 'dart:async';
import 'dart:io';
import 'dart:math' show cos, sqrt, asin;
import 'package:cabiee/models/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/cabs.dart';
import 'bookcab.dart';

// ignore: must_be_immutable
class SelectCab extends StatefulWidget {
  PointLatLng myLocation;
  PointLatLng destination;
  String locationName;
  String destinationName;
  SelectCab(this.myLocation, this.destination, this.locationName,this.destinationName);

  @override
  _SelectCabState createState() => _SelectCabState();
}

String kGoogleApiKey;

class _SelectCabState extends State<SelectCab>  with SingleTickerProviderStateMixin {
  Completer<GoogleMapController> _mapController = Completer();
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = kGoogleApiKey;
  var tween = Tween(begin: Offset(1.0,0.0), end: Offset.zero).chain(CurveTween(curve: Curves.elasticInOut));
  AnimationController _animationController;
  Animation _animation2;
  Animation _animation;
  double totalDistance = 0.0;
  double _placeDistance;
  var _index=0;
  String _name='Normal Cab';
  String _selectedOption = 'CASH';


  String val;
  final List<Cabs> items =[
    Cabs('Normal Cab', 'assets/normal.jpg',9.50),
    Cabs('Prime Cab', 'assets/prime.jpg',11.0),
    Cabs('Outstation Ride', 'assets/outstation.jpg',12.0),
    Cabs('Auto Rickshaw', 'assets/auto.jpg',8.5),
    Cabs('Bike Ride', 'assets/bike.jpg',5),
  ];
 final List paymentOptions = ["CASH","CREDIT CARD","DEBIT CARD","INTERNET BANKING"];
 final List<Icon> iconOptions = [
   Icon(FontAwesomeIcons.moneyBillAlt,color: Colors.green,),
   Icon(FontAwesomeIcons.creditCard,color: Colors.deepPurpleAccent,),
   Icon(FontAwesomeIcons.creditCard,color:Colors.indigo),
   Icon(Icons.web,size: 30,color:Colors.blue ,),
 ];
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }




  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      // Android-specific code
      kGoogleApiKey = "AIzaSyC9pqyp5r_m4cHbQIGKJjDXY5NG6lwP9Zg";
    } else if (Platform.isIOS) {
      // iOS-specific code
      kGoogleApiKey = "AIzaSyD5qX2Kc9s5ggtsRjoKRKeu6YO8s4zd0PQ";
    }
    _animationController =
        AnimationController( duration: Duration(milliseconds: 1500), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animation2 = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    /// origin marker
    _addMarker(LatLng(widget.myLocation.latitude, widget.myLocation.longitude), "origin",
        BitmapDescriptor.defaultMarkerWithHue(198.4));

    /// destination marker
    _addMarker(LatLng(widget.destination.latitude, widget.destination.longitude), "destination",
        BitmapDescriptor.defaultMarker);
    _getPolyline();
    _animationController.forward();

  }
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Choose Cab'),
        ),
          body:Stack(
            children: [
              widget.destination==null?Center(
                child: Container(
                  color: Theme.of(context).canvasColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
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
                  initialCameraPosition: CameraPosition(
                      target: LatLng(widget.myLocation.latitude, widget.myLocation.longitude), zoom: 13),
                  myLocationEnabled: true,
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
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                      child: Container(
                        height: 250,
                        child:Column(
                          children: [

                            Expanded(
                              child: InkWell(
                                splashColor: Colors.white,
                                onTap: (){
                                  _showMyOptions();
                                },
                                child: Material(
                                  color: Colors.lightBlue,
                                  child: Center(
                                    child: Text(
                                      'Paying with $_selectedOption, to change option Press Here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _items(),
                            ButtonTheme(
                              height: 45,
                              child: RaisedButton(
                                  onPressed:(){
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context)=>
                                            BookCab(items[_index].name,items[_index].image,_placeDistance*items[_index].price,widget.myLocation,widget.destination,widget.locationName,widget.destinationName,_selectedOption)));
                                  },
                              color: Colors.white,
                                child: Center(
                                  child: Text('Book $_name',style: TextStyle(fontSize: 18),),
                                ),
                              ),
                            )

                          ],
                        )

                      ),
                    )),
              ),

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
              target: LatLng(widget.destination.latitude, widget.destination.longitude),
            zoom: 15.0,
          ),
        ),
      );
    });
  }


  Widget _items(){
    return Container(
        height: 160,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: items.length==null?0:items.length,
          itemBuilder: (context, int currentIndex) {
            try {
              double oo =(_placeDistance*items[currentIndex].price);
              this.val=oo.toStringAsFixed(2).toString();
            } catch (e) {
            }
            return InkWell(
              splashColor: Colors.amber,
              onTap: (){
                setState(() {
                  this._index=currentIndex;
                  this._name=items[currentIndex].name.toString();
                });
              },
              child: Container(
                color: _index==currentIndex?Colors.amberAccent:Colors.black,
                padding: EdgeInsets.only(left: 20,right: 20,top: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: items[currentIndex].name,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                width: 1.0,
                                color: _index==currentIndex?Colors.black:Colors.white,
                                style: BorderStyle.solid),
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 1.0,
                                  color: Colors.white38,
                                  spreadRadius: 2.0)
                            ],
                            image: DecorationImage(
                                image: AssetImage(items[currentIndex].image), fit: BoxFit.cover,colorFilter: ColorFilter.mode(Colors.amberAccent, BlendMode.darken))),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8,),
                      child: Text(
                        items[currentIndex].name,
                        style: TextStyle(
                          color:_index==currentIndex?Colors.black:Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8,),
                      child: Text('Rs.$val',
                        style: TextStyle(
                          color: _index==currentIndex?Colors.black:Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 10,),
                      child: Text('5 min',
                        style: TextStyle(
                          fontSize: 12,
                          color: _index==currentIndex?Colors.black:Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
    );

  }
  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
    Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.lightBlue, points: polylineCoordinates,width: 5);
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        kGoogleApiKey,
        PointLatLng(widget.myLocation.latitude, widget.myLocation.longitude),
        PointLatLng(widget.destination.latitude, widget.destination.longitude),
        travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
    getDistance();
  }
  getDistance() async {
    double _coordinateDistance(lat1, lon1, lat2, lon2) {
      var p = 0.017453292519943295;
      var c = cos;
      var a = 0.5 -
          c((lat2 - lat1) * p) / 2 +
          c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
      return 12742 * asin(sqrt(a));
    }
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += _coordinateDistance(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
    }

    setState(() {
      _placeDistance = totalDistance;
      print('DISTANCE: $_placeDistance km');
    });
  }
  Future<void> _showMyOptions() async {
    return  showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(paymentOptions.length, (index) => buildItems(index)));
        });
  }

  buildItems(int index) {

   return ListTile(
     title: Text(paymentOptions[index],style: TextStyle(fontWeight: FontWeight.w500),),
     leading: iconOptions[index],
     onTap: (){
       setState(() {
         _selectedOption = paymentOptions[index];
       });
       Navigator.pop(context);
     },
   );
  }
}


