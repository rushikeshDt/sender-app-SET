// import 'dart:async';
// import 'dart:isolate';

// import 'dart:ui';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:sender_app/domain/local_firestore.dart';
// import 'package:sender_app/domain/experimental/video_stream_service.dart';
// import 'package:sender_app/firebase_options.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socket_io_client/socket_io_client.dart';

// Future<FlutterBackgroundService> initializeServiceLegacy() async {
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

// RootIsolateToken? token = RootIsolateToken.instance;
// @pragma('vm:entry-point')
// void onStart(
//   ServiceInstance service,
// ) async {
//   // BackgroundIsolateBinaryMessenger.ensureInitialized(
//   //     ServicesBinding.rootIsolateToken!);
//   // RootIsolateToken? token = ServicesBinding.rootIsolateToken;
//   // Only available for flutter 3.0.0 and later
//   if (token == null) {
//     print('token is null');
//   }
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
//     service.on('stopService').listen((event) async {
//       print('stoping service');
//       service.stopSelf();
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
//   ReceivePort receivePort = ReceivePort();
//   receivePort.listen((data) async {
//     if (data is SendPort) {
//       print('sendPort obtained from child');
//       data.send(token);
//       data.send('START_A');

//       await Future.delayed(Duration(seconds: 360));
//       data.send('SHOW_A');
//       await Future.delayed(Duration(seconds: 5));
//       data.send('STOP');
//     }
//   });
//   await Isolate.spawn(childIsolateFunction, receivePort.sendPort);
// }

// void childIsolateFunction(SendPort sendPort) {
//   WebrtcSender service = WebrtcSender(
//       options: 'FRONT_CAM',
//       receiverEmail: 'receiverEmail',
//       userEmail: 'userEmail');

//   ReceivePort rport = ReceivePort();
//   sendPort.send(rport.sendPort);
//   rport.listen((message) {
//     print('message in child: $message');
//     if (message is String) {
//       switch (message) {
//         case 'START_A':
//           // a = A(msg: 'hello from child');
//           test.feedParams('userEmail', 'rmail', 'FRONT_CAM');
//           test.createRoom();
//           break;
//         case 'SHOW_A':
//           //a.show();
//           service.hangUp();
//           break;

//         case 'STOP':
//           print('stopping child');
//           Isolate.exit();

//         default:
//       }
//     }
//     if (message is RootIsolateToken) {
//       BackgroundIsolateBinaryMessenger.ensureInitialized(message);
//     }
//   });
// }

// class A {
//   late String msg;
//   A({required this.msg});
//   void show() {
//     print('msg is $msg');
//   }
// }

// class test {
//   static Map<String, dynamic> configuration = {
//     'iceServers': [
//       {
//         'urls': [
//           'stun:stun1.l.google.com:19302',
//           'stun:stun2.l.google.com:19302'
//         ]
//       }
//     ]
//   };
//   static late String userEmail;
//   static late String receiverEmail;
//   static late String options;
//   static RTCPeerConnection? peerConnection;
//   static MediaStream? localStream;

//   static feedParams(String umail, String rmail, String option) {
//     userEmail = umail;
//     receiverEmail = rmail;
//     options = option;
//   }

//   static Future<void> createRoom() async {
//     try {
//       await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
//       FirebaseFirestore db = FirebaseFirestore.instance;
//       DocumentReference roomRef = db
//           .collection('sessions')
//           .doc(receiverEmail)
//           .collection(userEmail)
//           .doc('videoStream');

//       print(
//           '[WebrtcSender.createRoom] Create PeerConnection with configuration: $configuration');
//       // DebugFile.saveTextData(
//       //     '[WebrtcSender.createRoom] Create PeerConnection with configuration: $configuration');

//       peerConnection = await createPeerConnection(configuration);
//       //  registerPeerConnectionListeners(false);
//       print('new code');

//       options == 'BACK_CAM'
//           ? await _openUserMedia(front: false)
//           : await _openUserMedia(front: true);

//       localStream?.getTracks().forEach((track) {
//         peerConnection?.addTrack(track, localStream!);
//       });

//       // Code for collecting ICE candidates below
//       var callerCandidatesCollection = roomRef.collection('callerCandidates');

//       peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//         callerCandidatesCollection.add(candidate.toMap());
//       };
//       // Finish Code for collecting ICE candidate

//       // Add code for creating a room

//       RTCSessionDescription offer = await peerConnection!.createOffer();
//       await peerConnection!.setLocalDescription(offer);
//       print('[WebrtcSender.createRoom] Created offer: $offer');
//       // DebugFile.saveTextData(
//       //     '[WebrtcSender.createRoom] Created offer: $offer');

//       Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

//       await roomRef.set(roomWithOffer);
//       // var roomId = roomRef.id;
//       print('[WebrtcSender.createRoom] New room created with SDP offer.');
//       // DebugFile.saveTextData(
//       //     '[WebrtcSender.createRoom] New room created with SDP offer');

//       // Listening for remote sessions description below
//       roomRef.snapshots().listen((snapshot) async {
//         print(
//             '[WebrtcSender.createRoom] For videoStream doc snapshot.exist ${snapshot.exists}');
//         if (snapshot.exists) {
//           print('Got updated room: ${snapshot.data()}');
//           print("[WebrtcSender.createRoom] Someone tried to connect");
//           // DebugFile.saveTextData(
//           //     "[WebrtcSender.createRoom] Someone tried to connect");

//           Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//           print('[WebrtcSender.createRoom] answer is ${data['answer']}');
//           if (peerConnection?.getRemoteDescription() != null &&
//               data['answer'] != null) {
//             if (true) {
//               print(
//                   '[WebrtcSender.createRoom] Setting remote description');
//               // DebugFile.saveTextData(
//               //     '[WebrtcSender.createRoom] Setting remote description');
//               var answer = RTCSessionDescription(
//                 data['answer']['sdp'],
//                 data['answer']['type'],
//               );

//               await peerConnection?.setRemoteDescription(answer);
//             }
//           }
//         }
//       });
//       // Listening for remote sessions description above

//       // Listen for remote Ice candidates below
//       roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
//         snapshot.docChanges.forEach((change) {
//           if (change.type == DocumentChangeType.added) {
//             Map<String, dynamic> data =
//                 change.doc.data() as Map<String, dynamic>;

//             peerConnection!.addCandidate(
//               RTCIceCandidate(
//                 data['candidate'],
//                 data['sdpMid'],
//                 data['sdpMLineIndex'],
//               ),
//             );
//           }
//         });
//       });
//       // Listen for remote ICE candidates above
//     } catch (e) {
//       print('[VideoStream.createRoom] Error: ${e.toString()}');
//       // DebugFile.saveTextData('[VideoStream.createRoom] Error: ${e.toString()}');
//     }
//   }

//   static Future<void> _openUserMedia({required bool front}) async {
//     var stream = await navigator.mediaDevices.getUserMedia({
//       'video': {
//         'facingMode':
//             front ? 'user' : 'environment', //front ? 'user' : 'environment'
//       },
//       'audio': true
//     });

//     localStream = stream;
//     print('[WebrtcSender.openMedia] got localStream');
//     // DebugFile.saveTextData('[WebrtcSender.openMedia] got localStream');

//     // remoteVideo.srcObject = await createLocalMediaStream('key');
//   }
// }

// Future<dynamic> computeIsolate(Future Function() function) async {
//   final receivePort = ReceivePort();
//   var rootToken = RootIsolateToken.instance!;
//   await Isolate.spawn<_IsolateData>(
//     _isolateEntry,
//     _IsolateData(
//       token: rootToken,
//       function: function,
//       answerPort: receivePort.sendPort,
//     ),
//   );
//   return await receivePort.first;
// }

// void _isolateEntry(_IsolateData isolateData) async {
//   BackgroundIsolateBinaryMessenger.ensureInitialized(isolateData.token);
//   final answer = await isolateData.function();
//   isolateData.answerPort.send(answer);
// }

// class _IsolateData {
//   final RootIsolateToken token;
//   final Function function;
//   final SendPort answerPort;

//   _IsolateData({
//     required this.token,
//     required this.function,
//     required this.answerPort,
//   });
// }
