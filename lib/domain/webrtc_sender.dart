import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sender_app/domain/SessionControl.dart';

import 'debug_printer.dart';

class WebrtcSender {
  static Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };
  static late String userEmail;
  static late String receiverEmail;

  static RTCPeerConnection? peerConnection;
  static MediaStream? localStream;
  static bool parametersReady = false;
  static bool answerSet = false;
  static feedParameters({required String uEmail, required String rEmail}) {
    receiverEmail = rEmail;
    userEmail = uEmail;
    parametersReady = true;
  }

  static Future<void> createRoom(
      {required Map<String, dynamic> options}) async {
    if (!parametersReady)
      throw '[WebrtcSender.createRoom] feedParameters was not called';
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db
          .collection('sessions')
          .doc(receiverEmail)
          .collection(userEmail)
          .doc('videoStream');

      print(
          '[WebrtcSender.createRoom] Creating PeerConnection for options: ${options} and answerSet: $answerSet');
      DebugFile.saveTextData(
          '[WebrtcSender.createRoom] Creating PeerConnection for options: ${options} and answerSet: $answerSet');

      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners(false);
      print('new code');

      await _openUserMedia(
          front: options['FRONT_CAM']!, audioOnly: options['AUDIO_ONLY']!);

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for collecting ICE candidates below
      var callerCandidatesCollection = roomRef.collection('callerCandidates');

      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        callerCandidatesCollection.add(candidate.toMap());
      };
      // Finish Code for collecting ICE candidate

      // Add code for creating a room

      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);
      print('[WebrtcSender.createRoom] Created offer: $offer');
      DebugFile.saveTextData('[WebrtcSender.createRoom] Created offer');

      Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

      await roomRef.set(roomWithOffer);

      // Listening for remote sessions description below
      roomRef.snapshots().listen((snapshot) async {
        if (snapshot.exists) {
          print(
              "[WebrtcSender.createRoom] Someone tried to connect snapshot is ${snapshot.data()}");
          DebugFile.saveTextData(
              "[WebrtcSender.createRoom] Someone tried to connect (videoStream room has been updated)");

          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          if (peerConnection?.getRemoteDescription() != null &&
              data['answer'] != null &&
              !answerSet) {
            answerSet = true;
            print('[WebrtcSender.createRoom] Setting remote description');
            DebugFile.saveTextData(
                '[WebrtcSender.createRoom] Setting remote description');
            var answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );

            await peerConnection?.setRemoteDescription(answer);
          }
        }
      });
      // Listening for remote sessions description above

      // Listen for remote Ice candidates below
      roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((change) {
          if (change.type == DocumentChangeType.added) {
            print("[Webrtc.createRoom] calleeCandidate obtained");
            DebugFile.saveTextData(
                "[Webrtc.createRoom] calleeCandidate obtained");
            Map<String, dynamic> data =
                change.doc.data() as Map<String, dynamic>;

            peerConnection!.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }
        });
      });
      // Listen for remote ICE candidates above
    } catch (e) {
      print('[VideoStream.createRoom] Error: ${e.toString()}');
      DebugFile.saveTextData('[VideoStream.createRoom] Error: ${e.toString()}');
    }
  }

  static listenForCommand() async {
    if (!parametersReady)
      throw '[WebrtcSender.listenForCommand] feedParameters was not called';
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(receiverEmail)
        .collection(userEmail)
        .doc('messages')
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (data['command'] == 'CREATE_ROOM') {
        print(
            '[WebrtcSender.listenForCommand] CREATE_ROOM command from sender.');
        DebugFile.saveTextData(
            '[WebrtcSender.listenForCommand] CREATE_ROOM command from sender.');
        await createRoom(options: data['options']);

        await SessionControl.sendMessage(
          title: 'reply',
          message: 'ROOM_CREATED',
        );
      } else if (data['command'] == 'HANG_UP') {
        print('[WebrtcSender.listenForCommand] HANG_UP from sender.');
        DebugFile.saveTextData(
            '[WebrtcSender.listenForCommand] HANG_UP from sender.');
        await hangUp();
        await SessionControl.sendMessage(
          title: 'reply',
          message: 'HUNG_UP',
        );
      }
    });
  }

  static Future<void> _openUserMedia(
      {required bool front, required bool audioOnly}) async {
    Map<String, dynamic> mediaConstraints = {
      'video': audioOnly
          ? false
          : {
              'facingMode': front
                  ? 'user'
                  : 'environment', //front ? 'user' : 'environment'
            },
      'audio': true
    };
    var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    localStream = stream;
    print('[WebrtcSender.openMedia] got localStream');
    DebugFile.saveTextData('[WebrtcSender.openMedia] got localStream');

    // remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  static Future<void> hangUp() async {
    if (!parametersReady)
      throw '[WebrtcSender.hangUp] feedParameters was not called';
    print(
        '[WebrtcSender.hangup] hanging up for  receiver $receiverEmail sender $userEmail');
    DebugFile.saveTextData(
        '[WebrtcSender.hangup] hanging up for receiver $receiverEmail sender $userEmail');
    try {
      if (localStream != null) {
        localStream!.getTracks().forEach((track) {
          track.stop();
        });
        localStream!.dispose();
      }
      if (peerConnection != null) {
        print('[WebrtcSender.haungUp] closing peerConnection');
        await peerConnection!.close();
      }
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db
          .collection('sessions')
          .doc(receiverEmail)
          .collection(userEmail)
          .doc('videoStream');

      DocumentSnapshot<Object?> roomSnapshot = await roomRef.get();

      if (roomSnapshot.exists) {
        var calleeCandidates =
            await roomRef.collection('calleeCandidates').get();
        calleeCandidates.docs
            .forEach((document) => document.reference.delete());

        var callerCandidates =
            await roomRef.collection('callerCandidates').get();
        callerCandidates.docs
            .forEach((document) => document.reference.delete());
        answerSet = false;
        await roomRef.delete();
      }
    } catch (e) {
      print('[WebrtcSender.hangup] error ${e.toString()}');
      DebugFile.saveTextData('[WebrtcSender.hangup] error ${e.toString()}');
    }
  }

  static void registerPeerConnectionListeners(bool isJoinRoom) {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('[WebrtcReceiver] ICE gathering state changed: $state');
      DebugFile.saveTextData(
          '[WebrtcReceiver] ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('[WebrtcReceiver] Connection state change: $state');
      DebugFile.saveTextData(
          '[WebrtcReceiver] Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('[WebrtcReceiver] Signaling state change: $state');
      DebugFile.saveTextData('[WebrtcReceiver] Signaling state change: $state');
    };
  }
}
