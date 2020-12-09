import 'dart:async';
import 'dart:io';

import 'package:cabiee/models/Place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder/geocoder.dart';

// ignore: must_be_immutable
class AddWork extends StatefulWidget {

  GeoPoint ds;
  String id;
  AddWork(this.ds,this.id);

  @override
  _AddWorkState createState() => _AddWorkState();
}
String kGoogleApiKey;
class _AddWorkState extends State<AddWork> {
  TextEditingController _searchController = new TextEditingController();
  Timer _throttle;
  String myLocation;
  bool myDestinationActive = true;
  PointLatLng _destination;
  String id;
  var first;
  FocusNode fieldNode = FocusNode();

  String _heading;
  GeoPoint homePoint;
  GeoPoint workPoint;
  List<Place> _placesList;
  bool _showRecent;
  bool start=false;

  @override
  void initState() {
    if (Platform.isAndroid) {
      // Android-specific code
      kGoogleApiKey = "AIzaSyC9pqyp5r_m4cHbQIGKJjDXY5NG6lwP9Zg";
    } else if (Platform.isIOS) {
      // iOS-specific code
      kGoogleApiKey = "AIzaSyD5qX2Kc9s5ggtsRjoKRKeu6YO8s4zd0PQ";
    }
    super.initState();
    _heading = "Suggestions";
    _showRecent = true;
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
      // TODO Add session token

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
  @override
  void dispose() {
    _searchController.dispose();
    if (_throttle != null) {
      _throttle.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Add Work'),
        ),
        body: ListView(
          children: [
            start==true? LinearProgressIndicator(backgroundColor: Colors.amberAccent,):Text(''),
            Padding(
              padding: const EdgeInsets.only(
                  top: 40, left: 30, right: 30, bottom: 20),
              child: TextFormField(
                style: TextStyle(color: Colors.white,fontSize: 16),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on,color:fieldNode.hasFocus? Colors.amberAccent:Colors.white,size: 20,),
                  suffixIcon: IconButton(
                      icon: Icon(Icons.clear,color:fieldNode.hasFocus? Colors.amberAccent:Colors.white,size: 20,),
                      onPressed: () => _searchController.clear()),
                  fillColor: Colors.white,
                  labelText: 'Destination',
                  labelStyle: TextStyle(color: Colors.white),
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                    borderSide: new BorderSide(color: Colors.white,width: 0.0),
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
            _showRecent==false? ListTile(
              title:Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                  const EdgeInsets.only(left: 0.0, right: 10.0, bottom: 0),
                  child: Text(_heading,style: TextStyle(color: Colors.white)),
                ),
              ),
            ):SizedBox(),
            _showRecent==false?ListView.builder(
              shrinkWrap: true,
              itemCount: _placesList.length,
              itemBuilder: (BuildContext context, int index) => buildPlaceCard(context, index),
            ):SizedBox(width: 0.1,height: 0.1,),
          ],
        ),floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amberAccent,
        onPressed: () {
          if (_searchController.text.isNotEmpty) {
            setState(() {
              start=true;
            });
            FirebaseFirestore.instance.collection('Users').doc(widget.id).collection('work').add({
              'place':_searchController.text.toString(),
              'coords':GeoPoint(_destination.latitude, _destination.longitude),
            }).whenComplete((){
              Navigator.pop(context);
            });
          }
        },
        label: Text('Save Work',style: TextStyle(color: Colors.black)),
        icon: Icon(Icons.chevron_right,color: Colors.black,),
      ),
      ),
    );
  }
  Widget buildPlaceCard(BuildContext context, int index) {
    return Container(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0,),
      child: ListTile(
        title: Text(_placesList[index].place,style: TextStyle(color: Colors.white)),
        leading: Icon(Icons.location_on,color: Colors.white,),
        onTap: () async {
          var addresses = await Geocoder.local.findAddressesFromQuery(_placesList[index].place);
          var add = addresses.first;
          first=add;
          setState(() {
            _destination=PointLatLng(first.coordinates.latitude, first.coordinates.longitude);
            _searchController =
                TextEditingController(text: _placesList[index].place);
          });
        },
      ),
    );
  }
}