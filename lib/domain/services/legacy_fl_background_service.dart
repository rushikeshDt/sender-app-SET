// import 'dart:async';

// import 'dart:ui';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:sender_app/domain/local_firestore.dart';
// import 'package:sender_app/firebase_options.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socket_io_client/socket_io_client.dart';

// Future<FlutterBackgroundService> initializeService() async {
//   print("[print]initializing service");
//   final service = FlutterBackgroundService();
//   await service.isRunning() ? service.invoke("stopService") : () {};
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
//   // Only available for flutter 3.0.0 and later
//   DartPluginRegistrant.ensureInitialized();

//   // For flutter prior to version 3.0.0
//   // We have to register the plugin manually

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   // bring to foreground
//   Timer.periodic(const Duration(seconds: 1), (timer) async {
//     if (service is AndroidServiceInstance) {
//       if ((await service.isForegroundService())) {
//         service.setForegroundNotificationInfo(
//           title: "My App Service",
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

//   SharedPreferences info = await SharedPreferences.getInstance();
//   userEmail = info.getString('userEmail')!;
//   receiverEmail = info.getString('receiverEmail')!;
//   minutesToStart = info.getInt("minutesToAutoConnect")!;
//   minutesToStop = info.getInt('minutesToDissconnect')!;
//   print(
//       ' userEmail is ${userEmail}, minutesToStart is ${minutesToStart}, minutesToStop is ${minutesToStop}');
//   Socket socket =
//       io('https://websocket-server-set.glitch.me', <String, dynamic>{
//     'transports': ['websocket'],
//     'autoConnect': false
//   });

//   socket.onConnectError((data) {});

//   socket.onConnect((_) {
//     print('Connected: ${socket.id}');

//     var socketId = socket.id ?? 'null socketId';

//     socket.emit('senderHello', {
//       'userEmail': userEmail,
//       'socketId': socketId,
//       'receiverEmail': receiverEmail
//     });

//     // sendLocation from server
//     socket.on('sendLocation', (data) async {
//       print('Received data from server: $data');

//       Position pos = await Geolocator.getCurrentPosition();

//       // sending to server
//       socket.emit('myLocation', {
//         'location': {
//           'lat': pos.latitude.toString(),
//           'lang': pos.longitude.toString()
//         },
//         'time': DateTime.now().toLocal().toString(),
//         'userEmail': userEmail,
//         'receiverEmail': data['receiverEmail'],
//         'receiverSocketId': data['receiverSocketId']
//       });
//     });
//   });

//   notifyReceiver(bool connected) async {
//     print("[print] notifyReceiver called");
//     print("[print] updating document");
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
//     CollectionReference collectionReference =
//         FirebaseFirestore.instance.collection('availableSenders');
//     DocumentReference documentReference =
//         collectionReference.doc(receiverEmail);
//     documentReference.set({
//       userEmail: {
//         'connected': connected,
//       }
//     }, SetOptions(merge: true));

//     print("[print] document updated");
//   }

//   Future.delayed(Duration(seconds: minutesToStart * 60 - 30))
//       .then((value) async {
//     await notifyReceiver(true);
//     socket.connect();
//   });

//   Future.delayed(Duration(seconds: minutesToStop * 60)).then((value) async {
//     await notifyReceiver(false);
//     socket.disconnect();
//     service.stopSelf();
//   });

//   service.on('stopService').listen((event) async {
//     if (socket.connected) {
//       socket.disconnect();
//     }
//     service.stopSelf();
//   });
// }

  
 
  

//   // setUpAutoConnect() async {
//   //   Future.delayed(Duration(seconds: minutesToStart * 60 - 30))
//   //       .then((value) async {
//   //     await notifyReceiver();

//   //     socket.connect();
//   //   });
//   // }

//   // setUpAutoDisconnect() async {
//   //   Future.delayed(Duration(seconds: minutesToStop * 60)).then((value) {
//   //     if (socket.connected) {
//   //       socket.disconnect();
//   //     }

//   //     service.invoke("stopService");
//   //   });
//   // }

//   // socket.onConnectError((data) {});

//   //beginning of effective code
//   // setUpAutoConnect();
//   // setUpAutoDisconnect();