import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sender_app/configs/device_info.dart';

import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/presentation/screens/audio_screen.dart';

import 'package:sender_app/presentation/screens/location_page.dart';
import 'package:sender_app/presentation/screens/video_stream.dart';
import 'package:sender_app/user/user_info.dart';

class ServicePage extends StatefulWidget {
  final String senderEmail;
  final List<String> services;
  const ServicePage(
      {super.key, required this.senderEmail, required this.services});

  @override
  State<ServicePage> createState() =>
      _ServicePageState(senderEmail: senderEmail, services: services);
}

class _ServicePageState extends State<ServicePage> {
  late String senderEmail;
  late List<String> services;
  late bool isVideoStreamAvailable = false;
  late bool isLiveLocationAvailable = false;
  late bool isAudioStreamAAvailable = false;
  bool isConnected = false;
  StreamSubscription? subscription;
  _ServicePageState({required this.senderEmail, required this.services}) {
    for (var element in services) {
      switch (element) {
        case 'LIVE_LOCATION':
          isLiveLocationAvailable = true;

        case 'VIDEO_STREAM':
          isVideoStreamAvailable = true;
        case 'AUDIO_STREAM':
          isAudioStreamAAvailable = true;
        default:
      }
    }
    // services.contains('LIVE_LOCATION')
    //     ? isLiveLocationAvailable = true
    //     : isLiveLocationAvailable = false;
    // services.contains('VIDEO_STREAM')
    //     ? isVideoStreamAvailable = true
    //     : isVideoStreamAvailable = false;
    // services.contains('AUDIO_STREAM')
    //     ? isAudioStreamAAvailable = true
    //     : isAudioStreamAAvailable = false;
  }

  @override
  void initState() {
    getIsConnected();

    super.initState();
  }

  @override
  void dispose() {
    subscription ?? subscription!.cancel();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Choose Service'),
        ),
        body: Padding(
            padding: EdgeInsets.all(100),
            child: isConnected
                ? Column(
                    children: [
                      isLiveLocationAvailable
                          ? ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (ctx) => LocationPage(
                                          senderEmail: senderEmail,
                                        )));
                              },
                              child: Text('Location'))
                          : Text('Location Unavailable'),
                      SizedBox(
                        height: 20,
                      ),
                      isVideoStreamAvailable
                          ? ElevatedButton(
                              onPressed: () async {
                                TextEditingController controller =
                                    TextEditingController();
                                //  await FirestoreOps.getAvaialableSenders('receiverEmail');
                                showDialog(
                                    context: context,
                                    builder: (ctx) {
                                      return AlertDialog(
                                        title: Container(
                                          width: DeviceInfo.getDeviceWidth(
                                              context),
                                          padding: EdgeInsets.all(5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (ctx) =>
                                                              VideoStreamPage(
                                                                  senderEmail:
                                                                      senderEmail,
                                                                  options: {
                                                                    'FRONT_CAM':
                                                                        true,
                                                                    'AUDIO_ONLY':
                                                                        false,
                                                                  })));
                                                },
                                                child: Text('Front Cam'),
                                              ),
                                              SizedBox(
                                                width: 2,
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (ctx) =>
                                                              VideoStreamPage(
                                                                  senderEmail:
                                                                      senderEmail,
                                                                  options: {
                                                                    'FRONT_CAM':
                                                                        false,
                                                                    'AUDIO_ONLY':
                                                                        false
                                                                  })));
                                                },
                                                child: Text('Back Cam'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              child: Text('Video Stream'))
                          : Text('Video Streaming Unavailable'),
                      SizedBox(
                        height: 10,
                      ),
                      isAudioStreamAAvailable
                          ? ElevatedButton(
                              child: Text('Audio Streaming'),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (ctx) {
                                  return AudioStreamPage(
                                    senderEmail: senderEmail,
                                  );
                                }));
                              },
                            )
                          : Text('Audio Streaming Unavailable'),
                    ],
                  )
                : Text('Not Connected')));
  }

  getIsConnected() async {
    try {
      subscription = await FirebaseFirestore.instance
          .collection('availableSenders')
          .doc(CurrentUser.user['userEmail'])
          .get()
          .asStream()
          .listen((snap) {
        if (snap.exists) {
          setState(() {
            isConnected = snap.data()![senderEmail]['connected'];
          });
        }
      });
    } catch (e) {
      DebugFile.saveTextData(
          '[ServicePage.getIsConnected] Error ${e.toString()}');
    }
  }
}
