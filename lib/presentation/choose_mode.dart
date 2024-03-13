import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sender_app/domain/local_firestore.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';
import 'package:sender_app/domain/set_auto_connect.dart';
import 'package:sender_app/presentation/screens/video_stream.dart';

class ModePage extends StatelessWidget {
  const ModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.all(100),
      child: Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                await initializeService();
                var service = FlutterBackgroundService();
                bool status = await service.isRunning();
                if (status) {
                  print('[ModePge] service running stopping service');
                  service.invoke('stopService');
                  return;
                } else {
                  print('[ModePage] service not running. starting service.');

                  service.startService();
                }
              },
              child: Text('broadcast')),
          ElevatedButton(
              onPressed: () async {
                //  await FirestoreOps.getAvaialableSenders('receiverEmail');

                Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => VideoStreamPage()));
              },
              child: Text('Stream'))
        ],
      ),
    ));
  }
}
