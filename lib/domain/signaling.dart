import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sender_app/domain/debug_printer.dart';

typedef void StreamStateCallback(MediaStream stream);

class Signaling {
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

  static RTCPeerConnection? peerConnection;
  static MediaStream? localStream;
  static MediaStream? remoteStream;
  static String? roomId;
  static String? currentRoomText;
  static StreamStateCallback? onAddRemoteStream;

  static Future<String> createRoom({RTCVideoRenderer? remoteRenderer}) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    print(
        '[Signaling.createRoom] Create PeerConnection with configuration: $configuration');
    DebugFile.saveTextData(
        '[Signaling.createRoom] Create PeerConnection with configuration: $configuration');

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners(false);
    if (localStream == null) {
      await openUserMedia();
    }
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('[Signaling.createRoom]  Got candidate: ${candidate.toMap()}');
      DebugFile.saveTextData(
          '[Signaling.createRoom] Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };
    // Finish Code for collecting ICE candidate

    // Add code for creating a room
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    print('[Signaling.createRoom] Created offer: $offer');
    DebugFile.saveTextData('[Signaling.createRoom] Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    print(
        '[Signaling.createRoom] New room created with SDK offer. Room ID: $roomId');
    DebugFile.saveTextData(
        '[Signaling.createRoom] New room created with SDK offer. Room ID: $roomId');

    // Created a Room

    // peerConnection?.onTrack = (RTCTrackEvent event) {
    //   print('Got remote track: ${event.streams[0]}');

    //   event.streams[0].getTracks().forEach((track) {
    //     print('Add a track to the remoteStream $track');
    //     remoteStream?.addTrack(track);
    //   });
    // };

    // Listening for remote session description below
    roomRef.snapshots().listen((snapshot) async {
      print('Got updated room: ${snapshot.data()}');

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        print("[Signaling.createRoom] Someone tried to connect");
        DebugFile.saveTextData(
            "[Signaling.createRoom] Someone tried to connect");
        await peerConnection?.setRemoteDescription(answer);
      }
    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          print(
              '[Signaling.createRoom] Got new remote ICE candidate: ${jsonEncode(data)}');
          DebugFile.saveTextData(
              '[Signaling.createRoom] Got new remote ICE candidate: ${jsonEncode(data)}');
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

    return roomId;
  }

  static Future<void> joinRoom(
      {required String roomId, RTCVideoRenderer? remoteVideo}) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    print(roomId);
    DocumentReference roomRef = db.collection('rooms').doc('$roomId');
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      print(
          '[Signaling.joinRoom] Create PeerConnection with configuration: $configuration');
      DebugFile.saveTextData(
          '[Signaling.joinRoom] Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners(true);

      // localStream?.getTracks().forEach((track) {
      //   peerConnection?.addTrack(track, localStream!);
      // });

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          print('[Signaling.joinRoom] onIceCandidate: No IceCandidate');
          DebugFile.saveTextData(
              '[Signaling.joinRoom] onIceCandidate: No IceCandidate');
          return;
        }
        print('[Signaling.joinRoom] onIceCandidate: ${candidate.toMap()}');
        DebugFile.saveTextData(
            '[Signaling.joinRoom] onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      peerConnection?.onTrack = (RTCTrackEvent event) {
        print('[Signaling.joinRoom] Got remote track: ${event.streams[0]}');
        DebugFile.saveTextData(
            '[Signaling.joinRoom] Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          print('[Signaling.joinRoom] Add a track to the remoteStream: $track');
          DebugFile.saveTextData(
              '[Signaling.joinRoom] Add a track to the remoteStream: $track');
          remoteStream?.addTrack(track);
        });
      };

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      print('[Signaling.joinRoom] Got offer $data');
      DebugFile.saveTextData('[Signaling.joinRoom] Got offer $data');
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();
      print('[Signaling.joinRoom] Created Answer $answer');
      DebugFile.saveTextData('[Signaling.joinRoom] Created Answer $answer');

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((document) {
          var data = document.doc.data() as Map<String, dynamic>;

          print('[Signaling.joinRoom] Got new remote ICE candidate: $data');
          DebugFile.saveTextData(
              '[Signaling.joinRoom] Got new remote ICE candidate: $data');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        });
      });
    }
  }

  static Future<void> openUserMedia(
      {RTCVideoRenderer? localVideo, RTCVideoRenderer? remoteVideo}) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});
    if (localVideo != null) {
      localVideo.srcObject = stream;
    }

    localStream = stream;
    print('[Signaling.openMedia] geting localStream');
    DebugFile.saveTextData('[Signaling.openMedia] geting localStream');

    // remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  static Future<void> hangUp(
      {RTCVideoRenderer? localVideo, required String roomId}) async {
    print('[Signaling.hangup] hanging up for roomId $roomId');
    DebugFile.saveTextData('[Signaling.hangup] hanging up for roomId $roomId');
    try {
      if (localVideo != null) {
        List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
        tracks.forEach((track) {
          track.stop();
        });
      }

      if (remoteStream != null) {
        remoteStream!.getTracks().forEach((track) => track.stop());
      }
      if (peerConnection != null) peerConnection!.close();

      if (roomId != null) {
        var db = FirebaseFirestore.instance;
        var roomRef = db.collection('rooms').doc(roomId);
        var calleeCandidates =
            await roomRef.collection('calleeCandidates').get();
        calleeCandidates.docs
            .forEach((document) => document.reference.delete());

        var callerCandidates =
            await roomRef.collection('callerCandidates').get();
        callerCandidates.docs
            .forEach((document) => document.reference.delete());

        await roomRef.delete();
      }
      if (localStream != null) localStream!.dispose();
      if (remoteStream != null) remoteStream?.dispose();
    } catch (e) {
      print('[Signaling.hangup] error ${e.toString()}');
      DebugFile.saveTextData('[Signaling.hangup] error ${e.toString()}');
    }
  }

  static void registerPeerConnectionListeners(bool isJoinRoom) {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('[signaling] ICE gathering state changed: $state');
      DebugFile.saveTextData('[Signaling] ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('[Signaling] Connection state change: $state');
      DebugFile.saveTextData('[Signaling] Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('[Signaling] Signaling state change: $state');
      DebugFile.saveTextData('[Signaling] Signaling state change: $state');
    };

    if (isJoinRoom) {
      print('[Signaling] registering MediaStream to ui RTCVideoRenderer');
      DebugFile.saveTextData(
          '[Signaling] registering MediaStream to ui RTCVideoRenderer');
      peerConnection?.onAddStream = (MediaStream stream) {
        print("[Signaling] Adding remote Stream.");
        DebugFile.saveTextData('[Signaling] Adding remote Stream.');
        onAddRemoteStream?.call(stream);
        remoteStream = stream;
      };
    }
  }
}
