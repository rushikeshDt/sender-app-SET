// import 'dart:async';
// import 'dart:io';
// import 'dart:ui';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:sender_app/domain/experimental/SessionControl.dart';
// import 'package:sender_app/domain/debug_printer.dart';
// import 'package:sender_app/domain/local_firestore.dart';
// import 'package:sender_app/domain/location_service.dart';
// import 'package:sender_app/domain/experimental/video_stream_client.dart';
// import 'package:sender_app/domain/socket_client.dart';
// import 'package:sender_app/domain/experimental/video_stream_service.dart';

// import 'package:sender_app/firebase_options.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// Future<FlutterBackgroundService> initializeService() async {
//   print("[initializeService] initializing service");
//   DebugFile.saveTextData('[intitializeService] Configuring service');
//   final service = FlutterBackgroundService();

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
//   return service;
// }

// @pragma('vm:entry-point')
// void onStart(
//   ServiceInstance service,
// ) async {
//   print('new code 2');
//   BackgroundIsolateBinaryMessenger.ensureInitialized(
//       ServicesBinding.rootIsolateToken!);

//   // Only available for flutter 3.0.0 and later
//   DartPluginRegistrant.ensureInitialized();
//   await DebugFile.createFile();

//   // For flutter prior to version 3.0.0
//   // We have to register the plugin manually
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//     service.on('stopService').listen((event) {
//       service.stopSelf();
//     });
//   }
//   // bring to foreground
//   Timer.periodic(const Duration(seconds: 1), (timer) async {
//     if (service is AndroidServiceInstance) {
//       if ((await service.isForegroundService())) {
//         service.setForegroundNotificationInfo(
//           title: "service for realtime video stream",
//           content: "Updated at ${DateTime.now()}",
//         );
//       }
//     }

//     service.invoke(
//       'update',
//       {
//         "current_date": DateTime.now().toIso8601String(),
//       },
//     );
//   });

//   late String userEmail;
//   late String receiverEmail;
//   late int minutesToStart;
//   late int minutesToStop;
//   late List<String>? services;

//   try {
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
//     SharedPreferences info = await SharedPreferences.getInstance();
//     userEmail = info.getString('userEmail')!;
//     receiverEmail = info.getString('receiverEmail')!;
//     minutesToStart = info.getInt("minutesToAutoConnect")!;
//     minutesToStop = info.getInt('minutesToDissconnect')!;
//     services = info.getStringList('services')!;

//     print(
//         '[service.onStart] got userEmail: $userEmail, receiverEmail:$receiverEmail, minutesToStart:$minutesToStart, minutesToStop:$minutesToStop, services:$services');
//     DebugFile.saveTextData(
//         '[service.onStart] got userEmail: $userEmail, receiverEmail:$receiverEmail, minutesToStart:$minutesToStart, minutesToStop:$minutesToStop, services:$services');

//     Future.delayed(Duration(minutes: minutesToStart)).then((value) async {
//       SessionControl.feedParameters(uEmail: userEmail, rEmail: receiverEmail);
//       await SessionControl.notifyReceiver(
//         connected: true,
//       );
//       await SessionControl.sendMessage(
//         title: 'reply',
//         message: 'READY',
//       );

//       if (services!.contains('VIDEO_STREAM')) {
//         SessionControl.listenForCommand();
//         print('[service.onStart] VIDEO_STREAM service successfully activated');
//         DebugFile.saveTextData(
//             '[service.onStart] VIDEO_STREAM service successfully activated');
//       }
//       if (services.contains('LIVE_LOCATION')) {
//         LocationService.feedParameters(
//             rEmail: receiverEmail, uEmail: userEmail);

//         LocationService.listenForRequest();

//         print('[service.onStart] LIVE_LOCATION service successfully activated');
//         DebugFile.saveTextData(
//             '[service.onStart] LIVE_LOCATION service successfully activated');
//       }
//     });

//     Future.delayed(Duration(minutes: minutesToStop)).then((value) async {
//       await SessionControl.notifyReceiver(
//         connected: false,
//       );
//       if (services!.contains('VIDEO_STREAM')) {
//         await SessionControl.hangUp();

//         print(
//             '[service.onStart] VIDEO_STREAM service successfully deactivated');

//         DebugFile.saveTextData(
//             '[service.onStart] VIDEO_STREAM service successfully deactivated');
//       }
//       SessionControl.deleteSession();

//       await Future.delayed(Duration(seconds: 5));
//       print('[service.onStart] stopping service.');
//       DebugFile.saveTextData('[service.onStart] Stopping service.');
//       service.stopSelf();
//     });
//   } catch (e) {
//     print('[service.onStart] error ${e.toString()}');
//     DebugFile.saveTextData('[service.onStart] error ${e.toString()}');
//   }
// }
