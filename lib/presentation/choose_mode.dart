import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sender_app/domain/local_firestore.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';
import 'package:sender_app/domain/set_auto_connect.dart';
import 'package:sender_app/presentation/screens/location_page.dart';
import 'package:sender_app/presentation/screens/video_stream.dart';

class ServicePage extends StatelessWidget {
  late String senderEmail;
  late List<String> services;
  late bool isVideoStreamAvailable;
  late bool isLiveLocationAvailable;
  ServicePage({super.key, required this.senderEmail, required this.services}) {
    services.contains('LIVE_LOCATION')
        ? isLiveLocationAvailable = true
        : isLiveLocationAvailable = false;
    services.contains('VIDEO_STREAM')
        ? isVideoStreamAvailable = true
        : isVideoStreamAvailable = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Choose Service'),
        ),
        body: Padding(
          padding: EdgeInsets.all(100),
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => LocationPage(
                              senderEmail: senderEmail,
                            )));
                  },
                  child: Text('Location')),
              ElevatedButton(
                  onPressed: () async {
                    //  await FirestoreOps.getAvaialableSenders('receiverEmail');

                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => VideoStreamPage(
                              senderEmail: senderEmail,
                            )));
                  },
                  child: Text('Video Stream'))
            ],
          ),
        ));
  }
}
