import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sender_app/domain/fetch_location.dart';
import 'package:sender_app/network/send_request.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LocationPage extends StatefulWidget {
  final String senderEmail;
  const LocationPage({super.key, required this.senderEmail});

  @override
  State<LocationPage> createState() =>
      _LocationPageState(senderEmail: this.senderEmail);
}

class _LocationPageState extends State<LocationPage> {
  late FetchLocation _fetchLocation;
  final String senderEmail;
//  RequestWebSocket rws = RequestWebSocket();

  _LocationPageState({required this.senderEmail});

  @override
  void initState() {
    _fetchLocation = FetchLocation.getInstance(senderEmail: senderEmail);
    _fetchLocation.openLocationStream();
    _fetchLocation.sendLocationRequest();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    _fetchLocation.closeLocationStream();
    // Clean up or dispose of resources here
    super.dispose();

    // rws.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    // Replace this with the actual implementation for fetching and displaying location
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Page'),
      ),
      body: StreamBuilder(
        stream: _fetchLocation
            .locationStream, // rws.sendRequest(CurrentUser.user['userEmail'], senderEmail),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print('[print] data in location page ${snapshot.data}');
            // Use the data from the stream to build your UI
            if (snapshot.data!['STATUS'] == 'SENDER_ONE_TIME_LOCATION') {
              Map<String, dynamic> map = snapshot.data!['LOCATION'];
              // redirectToGoogleMaps(map['lat']!, map['long']!);

              double lat = double.parse(map['lat']!);
              double lng = double.parse(map['lang']!);

              double initLat = 20.0;
              double initLng = 70.0;

              CameraPosition _newPos = CameraPosition(
                  bearing: 192.8334901395799,
                  target: LatLng(lat, lng),
                  tilt: 59.440717697143555,
                  zoom: 19.151926040649414);

              CameraPosition _initPos = CameraPosition(
                target: LatLng(initLat, initLng),
                zoom: 14.4746,
              );

              Future<void> _goToLocation(GoogleMapController controller) async {
                await controller
                    .animateCamera(CameraUpdate.newCameraPosition(_newPos));
              }

              Set<Marker> _markers = {
                Marker(
                  markerId: MarkerId('locationPin'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: 'Location',
                    snippet: 'Your location description goes here',
                  ),
                  icon: BitmapDescriptor.defaultMarker,
                ),
              };
              return GoogleMap(
                mapType: MapType.normal,
                markers: _markers,
                initialCameraPosition: _initPos,
                onMapCreated: (GoogleMapController controller) {
                  _goToLocation(controller);
                },
              );
            }
            return Center(
              child: Text(snapshot.data!['STATUS'] ?? snapshot.data!['ERROR']),
            );
          } else {
            return const Center(
              child: Text('No data yet'),
            );
          }
        },
      ),
    );
  }

  // void redirectToGoogleMaps(String latitude, String longitude) async {
  //   String googleMapsUrl =
  //       "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

  //   await canLaunchUrlString(googleMapsUrl)
  //       ? await launchUrlString(googleMapsUrl)
  //       : throw Exception("COULD_NOT_LAUNCH");
  // }
}

MapWala(double lat, double lng) async {
  Position pos = await Geolocator.getCurrentPosition();
  double initLat = pos.latitude;
  double initLng = pos.longitude;

  CameraPosition _newPos = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(lat, lng),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  CameraPosition _initPos = CameraPosition(
    target: LatLng(initLat, initLng),
    zoom: 14.4746,
  );

  Future<void> _goToLocation(GoogleMapController controller) async {
    await controller.animateCamera(CameraUpdate.newCameraPosition(_newPos));
  }

  return GoogleMap(
    mapType: MapType.hybrid,
    initialCameraPosition: _initPos,
    onMapCreated: (GoogleMapController controller) {
      _goToLocation(controller);
    },
  );
}
