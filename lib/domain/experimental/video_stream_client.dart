// import 'dart:async';
// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// import 'package:sender_app/domain/debug_printer.dart';

// typedef void StreamStateCallback(MediaStream stream);

// class WebrtcReceiver {
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
//   // static late String userEmail;
//   // static late String receiverEmail;

//   static RTCPeerConnection? peerConnection;
//   // static MediaStream? localStream;
//   static MediaStream? remoteStream;

//   static StreamStateCallback? onAddRemoteStream;

//   static late StreamController<RTCPeerConnectionState>? myStreamController;

//   // feedParameters({required String uEmail, required String rEmail}) {
//   //   receiverEmail = rEmail;
//   //   userEmail = uEmail;
//   // }

//   // static Future<void> createRoom({required String options}) async {
//   //   FirebaseFirestore db = FirebaseFirestore.instance;
//   //   DocumentReference roomRef = db
//   //       .collection('sessions')
//   //       .doc(receiverEmail)
//   //       .collection(userEmail)
//   //       .doc('videoStream');

//   //   print(
//   //       '[WebrtcReceiver.createRoom] Create PeerConnection with configuration: $configuration');
//   //   DebugFile.saveTextData(
//   //       '[WebrtcReceiver.createRoom] Create PeerConnection with configuration: $configuration');

//   //   peerConnection = await createPeerConnection(configuration);

//   //   registerPeerConnectionListeners(false);
//   //   print('new code');

//   //   options == 'BACK_CAM'
//   //       ? await openUserMedia(front: false)
//   //       : await openUserMedia(front: true);

//   //   localStream?.getTracks().forEach((track) {
//   //     peerConnection?.addTrack(track, localStream!);
//   //   });

//   //   // Code for collecting ICE candidates below
//   //   var callerCandidatesCollection = roomRef.collection('callerCandidates');

//   //   peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//   //     print('[WebrtcReceiver.createRoom]  Got candidate: ${candidate.toMap()}');
//   //     DebugFile.saveTextData(
//   //         '[WebrtcReceiver.createRoom] Got candidate: ${candidate.toMap()}');
//   //     callerCandidatesCollection.add(candidate.toMap());
//   //   };
//   //   // Finish Code for collecting ICE candidate

//   //   // Add code for creating a room

//   //   RTCSessionDescription offer = await peerConnection!.createOffer();
//   //   await peerConnection!.setLocalDescription(offer);
//   //   print('[WebrtcReceiver.createRoom] Created offer: $offer');
//   //   DebugFile.saveTextData('[WebrtcReceiver.createRoom] Created offer: $offer');

//   //   Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

//   //   await roomRef.set(roomWithOffer);
//   //   // var roomId = roomRef.id;
//   //   print('[WebrtcReceiver.createRoom] New room created with SDK offer.');
//   //   DebugFile.saveTextData(
//   //       '[WebrtcReceiver.createRoom] New room created with SDK offer');

//   //   // Created a Room

//   //   // peerConnection?.onTrack = (RTCTrackEvent event) {
//   //   //   print('Got remote track: ${event.streams[0]}');

//   //   //   event.streams[0].getTracks().forEach((track) {
//   //   //     print('Add a track to the remoteStream $track');
//   //   //     remoteStream?.addTrack(track);
//   //   //   });
//   //   // };

//   //   // Listening for remote sessions description below
//   //   roomRef.snapshots().listen((snapshot) async {
//   //     print(
//   //         '[WebrtcReceiver.createRoom] For videoStream doc snapshot.exist ${snapshot.exists}');
//   //     if (snapshot.exists) {
//   //       print('Got updated room: ${snapshot.data()}');

//   //       Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//   //       if (peerConnection?.getRemoteDescription() != null &&
//   //           data['answer'] != null) {
//   //         var answer = RTCSessionDescription(
//   //           data['answer']['sdp'],
//   //           data['answer']['type'],
//   //         );

//   //         print("[WebrtcReceiver.createRoom] Someone tried to connect");
//   //         DebugFile.saveTextData(
//   //             "[WebrtcReceiver.createRoom] Someone tried to connect");
//   //         await peerConnection?.setRemoteDescription(answer);
//   //       }
//   //       return;
//   //     }
//   //   });
//   //   // Listening for remote sessions description above

//   //   // Listen for remote Ice candidates below
//   //   roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
//   //     snapshot.docChanges.forEach((change) {
//   //       if (change.type == DocumentChangeType.added) {
//   //         Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
//   //         print(
//   //             '[WebrtcReceiver.createRoom] Got new remote ICE candidate: ${jsonEncode(data)}');
//   //         DebugFile.saveTextData(
//   //             '[WebrtcReceiver.createRoom] Got new remote ICE candidate: ${jsonEncode(data)}');
//   //         peerConnection!.addCandidate(
//   //           RTCIceCandidate(
//   //             data['candidate'],
//   //             data['sdpMid'],
//   //             data['sdpMLineIndex'],
//   //           ),
//   //         );
//   //       }
//   //     });
//   //   });
//   //   // Listen for remote ICE candidates above
//   // }

//   // static listenForCommand() async {
//   //   FirebaseFirestore.instance
//   //       .collection('sessions')
//   //       .doc(receiverEmail)
//   //       .collection(userEmail)
//   //       .doc('messages')
//   //       .snapshots()
//   //       .listen((snapshot) async {
//   //     Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//   //     if (data['command'] == 'CREATE_ROOM') {
//   //       print('[service.onStart] CREATE_ROOM command from sender.');
//   //       DebugFile.saveTextData(
//   //           '[service.onStart] CREATE_ROOM command from sender.');
//   //       await WebrtcReceiver.createRoom(options: data['options']);
//   //       await FirebaseFirestore.instance
//   //           .collection('sessions')
//   //           .doc(receiverEmail)
//   //           .collection(userEmail)
//   //           .doc('messages')
//   //           .set({'reply': 'ROOM_CREATED'});
//   //     } else if (data['command'] == 'HANG_UP') {
//   //       print('[service.onStart] HANG_UP from sender.');
//   //       DebugFile.saveTextData('[service.onStart] HANG_UP from sender.');
//   //       await WebrtcReceiver.hangUp(
//   //           receiverEmail: receiverEmail, senderEmail: userEmail);
//   //       await FirebaseFirestore.instance
//   //           .collection('sessions')
//   //           .doc(receiverEmail)
//   //           .collection(userEmail)
//   //           .doc('messages')
//   //           .set({'reply': 'HUNG_UP'});
//   //     }
//   //   });
//   // }

//   static Future<String> joinRoom(
//       {required String receiverEmail, required String senderEmail}) async {
//     //  print(roomId);
//     FirebaseFirestore db = FirebaseFirestore.instance;
//     DocumentReference roomRef = db
//         .collection('sessions')
//         .doc(receiverEmail)
//         .collection(senderEmail)
//         .doc('videoStream');
//     var roomSnapshot = await roomRef.get();
//     print('Got room ${roomSnapshot.exists}');

//     if (roomSnapshot.exists) {
//       print(
//           '[WebrtcReceiver.joinRoom] Create PeerConnection with configuration: $configuration');
//       DebugFile.saveTextData(
//           '[WebrtcReceiver.joinRoom] Create PeerConnection with configuration: $configuration');
//       peerConnection = await createPeerConnection(configuration);

//       registerPeerConnectionListeners(true);

//       // localStream?.getTracks().forEach((track) {
//       //   peerConnection?.addTrack(track, localStream!);
//       // });

//       // Code for collecting ICE candidates below
//       var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
//       peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
//         if (candidate == null) {
//           print('[WebrtcReceiver.joinRoom] onIceCandidate: No IceCandidate');
//           DebugFile.saveTextData(
//               '[WebrtcReceiver.joinRoom] onIceCandidate: No IceCandidate');
//           return;
//         }
//         print(
//             '[WebrtcReceiver.joinRoom] onIceCandidate: ${candidate.toMap()}');
//         DebugFile.saveTextData(
//             '[WebrtcReceiver.joinRoom] onIceCandidate: ${candidate.toMap()}');
//         calleeCandidatesCollection.add(candidate.toMap());
//       };
//       // Code for collecting ICE candidate above

//       peerConnection?.onTrack = (RTCTrackEvent event) {
//         print(
//             '[WebrtcReceiver.joinRoom] Got remote track: ${event.streams[0]}');
//         DebugFile.saveTextData(
//             '[WebrtcReceiver.joinRoom] Got remote track: ${event.streams[0]}');
//         event.streams[0].getTracks().forEach((track) {
//           print(
//               '[WebrtcReceiver.joinRoom] Adding a track to the remoteStream: $track');
//           DebugFile.saveTextData(
//               '[WebrtcReceiver.joinRoom] Adding a track to the remoteStream: $track');
//           remoteStream?.addTrack(track);
//         });
//       };

//       // Code for creating SDP answer below
//       var data = roomSnapshot.data() as Map<String, dynamic>;
//       print('[WebrtcReceiver.joinRoom] Got offer $data');
//       DebugFile.saveTextData('[WebrtcReceiver.joinRoom] Got offer $data');
//       var offer = data['offer'];
//       await peerConnection?.setRemoteDescription(
//         RTCSessionDescription(offer['sdp'], offer['type']),
//       );
//       var answer = await peerConnection!.createAnswer();
//       print('[WebrtcReceiver.joinRoom] Created Answer $answer');
//       DebugFile.saveTextData(
//           '[WebrtcReceiver.joinRoom] Created Answer $answer');

//       await peerConnection!.setLocalDescription(answer);

//       Map<String, dynamic> roomWithAnswer = {
//         'answer': {'type': answer.type, 'sdp': answer.sdp}
//       };

//       await roomRef.update(roomWithAnswer);
//       // Finished creating SDP answer

//       // Listening for remote ICE candidates below
//       roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
//         snapshot.docChanges.forEach((document) {
//           var data = document.doc.data() as Map<String, dynamic>;

//           print(
//               '[WebrtcReceiver.joinRoom] Got new remote ICE candidate: $data');
//           DebugFile.saveTextData(
//               '[WebrtcReceiver.joinRoom] Got new remote ICE candidate: $data');
//           peerConnection!.addCandidate(
//             RTCIceCandidate(
//               data['candidate'],
//               data['sdpMid'],
//               data['sdpMLineIndex'],
//             ),
//           );
//         });
//       });
//       return 'joined';
//     }
//     return 'could not join. have you created connection ?';
//   }

//   // static Future<void> openUserMedia(
//   //     {RTCVideoRenderer? localVideo,
//   //     RTCVideoRenderer? remoteVideo,
//   //     required bool front}) async {
//   //   var stream = await navigator.mediaDevices.getUserMedia({
//   //     'video': {
//   //       'facingMode': front
//   //           ? 'user'
//   //           : 'environment', // Use 'environment' for the rear camera
//   //     },
//   //     'audio': true
//   //   });
//   //   if (localVideo != null) {
//   //     localVideo.srcObject = stream;
//   //   }

//   //   localStream = stream;
//   //   print('[WebrtcReceiver.openMedia] got localStream');
//   //   DebugFile.saveTextData('[WebrtcReceiver.openMedia] got localStream');

//   //   // remoteVideo.srcObject = await createLocalMediaStream('key');
//   // }

//   static Future<void> hangUp() async {
//     try {
//       if (remoteStream != null) {
//         remoteStream!.getTracks().forEach((track) async {
//           await track.stop();
//         });
//         remoteStream!.dispose();
//       }
//       if (peerConnection != null) {
//         print('[WebrtcReceiver.haungUp] closing peerConnection');
//         peerConnection!.close();
//       }
//     } catch (e) {
//       print('[WebrtcReceiver.hangup] error ${e.toString()}');
//       DebugFile.saveTextData(
//           '[WebrtcReceiver.hangup] error ${e.toString()}');
//     }
//   }

//   static void registerPeerConnectionListeners(bool isJoinRoom) {
//     peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
//       print('[WebrtcReceiver] ICE gathering state changed: $state');
//       DebugFile.saveTextData(
//           '[WebrtcReceiver] ICE gathering state changed: $state');
//     };

//     peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
//       if (myStreamController != null && !myStreamController!.isClosed)
//         myStreamController!.add(state);

//       print('[WebrtcReceiver] Connection state change: $state');
//       DebugFile.saveTextData(
//           '[WebrtcReceiver] Connection state change: $state');
//     };

//     peerConnection?.onSignalingState = (RTCSignalingState state) {
//       print('[WebrtcReceiver] Signaling state change: $state');
//       DebugFile.saveTextData(
//           '[WebrtcReceiver] Signaling state change: $state');
//     };

//     if (isJoinRoom) {
//       print(
//           '[WebrtcReceiver] registering MediaStream to ui RTCVideoRenderer');
//       DebugFile.saveTextData(
//           '[WebrtcReceiver] registering MediaStream to ui RTCVideoRenderer');
//       peerConnection!.onAddStream = (MediaStream stream) {
//         print("[WebrtcReceiver] Adding remote Stream.");
//         DebugFile.saveTextData('[WebrtcReceiver] Adding remote Stream.');
//         onAddRemoteStream?.call(stream);
//         remoteStream = stream;
//       };
//     }
//   }

//   static openStream() {
//     myStreamController = StreamController<RTCPeerConnectionState>();
//   }

//   static dispose() async {
//     if (myStreamController != null) await myStreamController!.close();
//   }
// }
