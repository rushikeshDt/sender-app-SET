import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/fetch_location.dart';
import 'package:sender_app/network/send_request.dart';
import 'package:sender_app/presentation/screens/about_screen.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool mapLoaded = false;
  String _status = "";

  _LocationPageState({required this.senderEmail});

  @override
  void initState() {
    super.initState();
    _fetchLocation = FetchLocation.getInstance(senderEmail: senderEmail);
    _fetchLocation.openLocationStream();
    _fetchLocation.sendLocationRequest();

    // TODO: implement initState
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
      appBar: AppBar(title: Text('Location Page'), actions: [
        IconButton(
          onPressed: () async {
            await _fetchLocation.sendLocationRequest();
            setState(() {});
          },
          icon: Icon(Icons.restart_alt),
        )
      ]),
      body: StreamBuilder(
        stream: _fetchLocation
            .locationStream, // rws.sendRequest(CurrentUser.user['userEmail'], senderEmail),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print('[print] data in location page ${snapshot.data}');

            if (snapshot.data!['STATUS'] == 'SENDER_ONE_TIME_LOCATION') {
              Map<String, dynamic> map = snapshot.data!['LOCATION'];

              double lat = double.parse(map['lat']!);
              ;
              double lng = double.parse(map['lang']!);
              return Center(
                child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _status = "please wait launching google maps";
                      });
                      try {
                        await _launchGoogleMaps(lat, lng);
                      } catch (e) {
                        setState(
                          () {
                            _status = e.toString();
                          },
                        );
                      }
                    },
                    child: Text("Open Maps")),
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

  Future<void> _launchGoogleMaps(double lat, double lon) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch Google Maps';
    }
  }
}


  // Container mapContainer(double lat, double lng) {
  //   return Container(
  //     child: Column(
  //       children: [
  //         Container(
  //           height: DeviceInfo.getDeviceHeight(context) / 2,
  //           child: FutureBuilder(
  //             future: mapWala(lat, lng),
  //             builder: (context, snapshot) {
  //               if (snapshot.hasData) {
  //                 return snapshot.data!;
  //               } else {
  //                 return Center(
  //                   child: Text('waiting for map to laod'),
  //                 );
  //               }
  //             },
  //           ),
  //         ),
  //         SizedBox(
  //           height: 10,
  //         ),
  //         ElevatedButton(
  //             onPressed: () async {
  //               setState(() {
  //                 _status = "please wait launching google maps";
  //               });
  //               try {
  //                 await _launchGoogleMaps(lat, lng);
  //               } catch (e) {
  //                 setState(() {
  //                   _status = e.toString();
  //                 });
  //               }
  //             },
  //             child: Text(mapLoaded ? "Cant see map?" : "Loading")),
  //         SizedBox(
  //           height: 10,
  //         ),
  //         Text(_status)
  //       ],
  //     ),
  //   );
  // }

  // Future<Widget> mapWala(double lat, double lng) async {
  //   Position pos = await Geolocator.getCurrentPosition();
  //   double initLat = pos.latitude;
  //   double initLng = pos.longitude;

  //   CameraPosition _newPos = CameraPosition(
  //       bearing: 192.8334901395799,
  //       target: LatLng(lat, lng),
  //       tilt: 59.440717697143555,
  //       zoom: 19.151926040649414);

  //   CameraPosition _initPos = CameraPosition(
  //     target: LatLng(initLat, initLng),
  //     zoom: 14.4746,
  //   );

  //   Set<Marker> _markers = {
  //     Marker(
  //       markerId: MarkerId('locationPin'),
  //       position: LatLng(lat, lng),
  //       infoWindow: InfoWindow(
  //         title: 'Location',
  //         snippet: 'Your location description goes here',
  //       ),
  //       icon: BitmapDescriptor.defaultMarker,
  //     ),
  //   };
  //   Future<void> _goToLocation(GoogleMapController controller) async {
  //     setState(() {
  //       mapLoaded = true;
  //     });
  //     await controller.animateCamera(CameraUpdate.newCameraPosition(_newPos));
  //   }

  //   return GoogleMap(
  //     mapType: MapType.normal,
  //     initialCameraPosition: _initPos,
  //     markers: _markers,
  //     onMapCreated: (GoogleMapController controller) {
  //       _goToLocation(controller);
  //     },
  //   );
  // }