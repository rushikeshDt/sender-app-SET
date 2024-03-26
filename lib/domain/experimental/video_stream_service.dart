// import 'dart:async';
// import 'dart:convert';
// import 'dart:isolate';
// import 'dart:ui';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:sender_app/domain/SessionControl.dart';
// import 'package:sender_app/firebase_options.dart';
// import 'package:sender_app/presentation/screens/sender_list_page.dart';

// import '../services/debug_printer.dart';

// class WebrtcSender {
//   Map<String, dynamic> configuration = {
//     'iceServers': [
//       {
//         'urls': [
//           'stun:stun1.l.google.com:19302',
//           'stun:stun2.l.google.com:19302'
//         ]
//       }
//     ]
//   };
//   late String userEmail;
//   late String receiverEmail;
//   late String options;
//   RTCPeerConnection? peerConnection;
//   MediaStream? localStream;

//   bool answerSet = false;
//   WebrtcSender(
//       {required this.userEmail,
//       required this.receiverEmail,
//       required this.options});
//   Future<void> createRoom() async {
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
//       registerPeerConnectionListeners(false);
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

//   Future<void> _openUserMedia({required bool front}) async {
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

//   Future<void> hangUp() async {
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
//     print(
//         '[WebrtcSender.hangup] hanging up for  receiver $receiverEmail sender $userEmail');
//     // DebugFile.saveTextData(
//     //     '[WebrtcSender.hangup] hanging up for receiver $receiverEmail sender $userEmail');
//     try {
//       if (localStream != null) {
//         localStream!.getTracks().forEach((track) {
//           track.stop();
//         });
//         localStream!.dispose();
//       }
//       if (peerConnection != null) {
//         print('[WebrtcSender.haungUp] closing peerConnection');
//         await peerConnection!.close();
//       }
//       FirebaseFirestore db = FirebaseFirestore.instance;
//       DocumentReference roomRef = db
//           .collection('sessions')
//           .doc(receiverEmail)
//           .collection(userEmail)
//           .doc('videoStream');

//       DocumentSnapshot<Object?> roomSnapshot = await roomRef.get();

//       if (roomSnapshot.exists) {
//         var calleeCandidates =
//             await roomRef.collection('calleeCandidates').get();
//         calleeCandidates.docs
//             .forEach((document) => document.reference.delete());

//         var callerCandidates =
//             await roomRef.collection('callerCandidates').get();
//         callerCandidates.docs
//             .forEach((document) => document.reference.delete());

//         await roomRef.delete();
//       }
//     } catch (e) {
//       print('[WebrtcSender.hangup] error ${e.toString()}');
//       // DebugFile.saveTextData(
//       //     '[WebrtcSender.hangup] error ${e.toString()}');
//     }
//   }

//   void registerPeerConnectionListeners(bool isJoinRoom) {
//     // peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
//     //   print('[WebrtcReceiver] ICE gathering state changed: $state');
//     //   DebugFile.saveTextData(
//     //       '[WebrtcReceiver] ICE gathering state changed: $state');
//     // };

//     // peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
//     //   print('[WebrtcReceiver] Connection state change: $state');
//     //   DebugFile.saveTextData(
//     //       '[WebrtcReceiver] Connection state change: $state');
//     // };

//     // peerConnection?.onSignalingState = (RTCSignalingState state) {
//     //   print('[WebrtcReceiver] Signaling state change: $state');
//     //   DebugFile.saveTextData(
//     //       '[WebrtcReceiver] Signaling state change: $state');
//     // };
//   }
// }

// class VSSController {
//   static late String userEmail;
//   static late String receiverEmail;
//   static late String options;
//   static Isolate? _videoStreamIsolate;
//   static SendPort? _childSendPort;
//   static ReceivePort? _receivePort;
//   static StreamController<dynamic>? _streamController;
//   static StreamController<SendPort>? _streamController2;
//   static Stream<SendPort>? spStream;
//   static Stream<String>? strStream;
//   static bool get isActive => _videoStreamIsolate != null ? true : false;
//   static void feedParams(
//       {required String rEmail,
//       required String uEmail,
//       required String ops}) async {
//     receiverEmail = rEmail;
//     userEmail = uEmail;
//     options = ops;
//   }

//   static Future<SendPort> _init() async {
//     Future<SendPort>? port;
//     _streamController = StreamController<String>();
//     _streamController2 = StreamController<SendPort>();
//     spStream = _streamController2!.stream;
//     strStream = _streamController!.stream as Stream<String>?;
//     _receivePort = ReceivePort();

//     _receivePort!.listen((data) {
//       if (data is SendPort) {
//         print('got child send port');
//         // port = Future.value(data);
//         _streamController2!.add(data);
//       }
//       if (data is String) {
//         print('message from child: $data');
//         _streamController!.add(data);
//       }
//     });
//     print('spawning child');
//     _videoStreamIsolate =
//         await Isolate.spawn(videoStreamIsolate, _receivePort!.sendPort);
//     final returnValue = await spStream!.first;

//     return returnValue!;
//   }

//   static Future<String> createRoom() async {
//     print('performing init');
//     _childSendPort = await _init();

//     print('sending create room to child');
//     final message = {
//       'command': 'CREATE_ROOM',
//       'params': [userEmail, receiverEmail, options]
//     };
//     _childSendPort!.send(message);

//     final msg = await strStream!.first;
//     await strStream!.drain();

//     return msg;
//   }

//   static Future<String> hangUp() async {
//     if (_childSendPort == null)
//       throw 'child seems to be not spawned yet. send port of child has not been obtained';

//     _childSendPort!.send('HANG_UP');
//     print('hang up sent');

//     final msg = await strStream!.first;
//     await strStream!.drain();
//     cleanUp();
//     return msg;
//   }

//   static cleanUp() {
//     _streamController!.close();
//     _streamController2!.close();
//     _receivePort!.close();
//     _childSendPort = null;
//   }
// }

// videoStreamIsolate(SendPort sendPort) {
//   BackgroundIsolateBinaryMessenger.ensureInitialized(
//       ServicesBinding.rootIsolateToken!);
//   ReceivePort childRPort = ReceivePort();
//   print('[child]sending sendPort to parent');
//   sendPort.send(childRPort.sendPort);
//   print('[child]getting vService');
//   WebrtcSender? vService;

//   childRPort.listen((message) async {
//     if (message is Map) {
//       print('[child]message in child $message ');
//       switch (message['command']) {
//         case 'CREATE_ROOM':
//           vService = WebrtcSender(
//               userEmail: message['params']![0],
//               receiverEmail: message['params']![1],
//               options: message['params']![2]);
//           print('[child]creating room');
//           await vService!.createRoom();
//           sendPort.send('ROOM_CREATED');
//           break;
//         case 'HANG_UP':
//           if (vService == null)
//             throw 'room may not have been created. vService is null';
//           print('hanging up');
//           await vService!.hangUp();
//           sendPort.send('HUNG_UP');
//           print('[child]stopping child');
//           Isolate.exit();
//       }
//     }
//   });
// }
