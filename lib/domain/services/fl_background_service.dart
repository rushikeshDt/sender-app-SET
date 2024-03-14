import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/domain/local_firestore.dart';
import 'package:sender_app/domain/signaling.dart';
import 'package:sender_app/domain/socket_client.dart';

import 'package:sender_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<FlutterBackgroundService> initializeService() async {
  print("[initializeService] initializing service");
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );
  return service;
}

@pragma('vm:entry-point')
void onStart(
  ServiceInstance service,
) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if ((await service.isForegroundService())) {
        service.setForegroundNotificationInfo(
          title: "service for realtime video stream",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
      },
    );
  });

  late String userEmail = 'senderEmail';
  late String receiverEmail = 'receiverEmail';
  late int minutesToStart = 0;
  late int minutesToStop = 10;
  late List<String>? services = ['VIDEO_STREAM'];

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    SharedPreferences info = await SharedPreferences.getInstance();
    userEmail = info.getString('userEmail')!;
    receiverEmail = info.getString('receiverEmail')!;
    minutesToStart = info.getInt("minutesToAutoConnect")!;
    minutesToStop = info.getInt('minutesToDissconnect')!;
    services = info.getStringList('services')!;

    print(
        '[service.onStart] got userEmail: $userEmail, receiverEmail:$receiverEmail, minutesToStart:$minutesToStart, minutesToStop:$minutesToStop, services:$services');
    DebugFile.saveTextData(
        '[service.onStart] got userEmail: $userEmail, receiverEmail:$receiverEmail, minutesToStart:$minutesToStart, minutesToStop:$minutesToStop, services:$services');
    Future.delayed(Duration(minutes: minutesToStart)).then((value) async {
      if (services!.contains('VIDEO_STREAM')) {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(receiverEmail)
            .collection(userEmail)
            .doc('messages')
            .set({'reply': 'WAITING_FOR_COMMAND'});
        print('[service.onStart] WAITING_FOR_COMMAND sent');
        DebugFile.saveTextData('[service.onStart] WAITING_FOR_COMMAND sent');

        FirebaseFirestore.instance
            .collection('sessions')
            .doc(receiverEmail)
            .collection(userEmail)
            .doc('messages')
            .snapshots()
            .listen((snapshot) async {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if (data['command'] == 'CREATE_ROOM') {
            print('[service.onStart] CREATE_ROOM command from sender.');
            DebugFile.saveTextData(
                '[service.onStart] CREATE_ROOM command from sender.');
            await Signaling.createRoom(
                receiverEmail: receiverEmail, senderEmail: userEmail);
            await FirebaseFirestore.instance
                .collection('sessions')
                .doc(receiverEmail)
                .collection(userEmail)
                .doc('messages')
                .set({'reply': 'ROOM_CREATED'});
          } else if (data['command'] == 'HANG_UP') {
            print('[service.onStart] HANG_UP from sender.');
            DebugFile.saveTextData('[service.onStart] HANG_UP from sender.');
            await Signaling.hangUp(
                receiverEmail: receiverEmail, senderEmail: userEmail);
            await FirebaseFirestore.instance
                .collection('sessions')
                .doc(receiverEmail)
                .collection(userEmail)
                .doc('messages')
                .set({'reply': 'HUNG_UP'});
          }
        });

        print('[service.onStart] VIDEO_STREAM service successfully activated');
        DebugFile.saveTextData(
            '[service.onStart] VIDEO_STREAM service successfully activated');
      }
      if (services.contains('LIVE_LOCATION')) {
        SocketClient.feedParameters(uEmail: userEmail, rEmail: receiverEmail);
        SocketClient.registerEvents();
        SocketClient.socket.connect();
        FirestoreOps.notifyReceiver(
          connected: true,
          receiverEmail: receiverEmail,
          userEmail: userEmail,
        );

        print('[service.onStart] LIVE_LOCATION service successfully activated');
        DebugFile.saveTextData(
            '[service.onStart] LIVE_LOCATION service successfully activated');
      }
    });

    Future.delayed(Duration(minutes: minutesToStop)).then((value) async {
      if (services!.contains('VIDEO_STREAM')) {
        await Signaling.hangUp(
            receiverEmail: receiverEmail, senderEmail: userEmail);

        print(
            '[service.onStart] VIDEO_STREAM service successfully deactivated');
        DebugFile.saveTextData(
            '[service.onStart] VIDEO_STREAM service successfully deactivated');
      }
      if (services.contains('LIVE_LOCATION')) {
        if (SocketClient.socket.connected) {
          SocketClient.socket.disconnect();
          print('[service.onStart] socket is connected disconnecting now');
          DebugFile.saveTextData(
              '[service.onStart] socket is connected disconnecting now');
        }

        print(
            '[service.onStart] VIDEO_STREAM service successfully deactivated');
        DebugFile.saveTextData(
            '[service.onStart] VIDEO_STREAM service successfully deactivated');
      }

      service.invoke('stopService');
    });
  } catch (e) {
    print('[service.onStart] error ${e.toString()}');
    DebugFile.saveTextData('[service.onStart] error ${e.toString()}');
  }

  service.on('stopService').listen((event) async {
    print('[service.onStart] stopService event. stopping service.');
    DebugFile.saveTextData(
        '[service.onStart] stopService event. stopping service.');
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(receiverEmail)
        .collection(userEmail)
        .doc('messages')
        .set({'reply': 'DISCONNECTED'});

    FirestoreOps.notifyReceiver(
      connected: false,
      receiverEmail: receiverEmail,
      userEmail: userEmail,
    );
    await service.stopSelf();
  });
}

// Future<void> register(ServiceInstance service, Signaling Signaling) async {
//   return;
// }
