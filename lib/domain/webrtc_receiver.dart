import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:sender_app/domain/debug_printer.dart';

typedef void StreamStateCallback(MediaStream stream);

class WebrtcReceiver {
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
  // static late String userEmail;
  // static late String receiverEmail;

  static RTCPeerConnection? _peerConnection;
  // static MediaStream? localStream;
  static MediaStream? remoteStream;
  static late bool? connected;

  static StreamStateCallback? onAddRemoteStream;

  static late StreamController<RTCPeerConnectionState>? myStreamController;

  static Future<String> joinRoom(
      {required String receiverEmail, required String senderEmail}) async {
    //  print(roomId);
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db
        .collection('sessions')
        .doc(receiverEmail)
        .collection(senderEmail)
        .doc('videoStream');
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      try {
        print(
            '[WebrtcReceiver.joinRoom] Create PeerConnection with configuration: $configuration');
        DebugFile.saveTextData(
            '[WebrtcReceiver.joinRoom] Create PeerConnection with configuration: $configuration');
        _peerConnection = await createPeerConnection(configuration);

        registerPeerConnectionListeners(true);

        // Code for collecting ICE candidates below
        var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
        _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
          if (candidate == null) {
            print('[WebrtcReceiver.joinRoom] onIceCandidate: No IceCandidate');
            DebugFile.saveTextData(
                '[WebrtcReceiver.joinRoom] onIceCandidate: No IceCandidate');
            return;
          }
          print(
              '[WebrtcReceiver.joinRoom] onIceCandidate: ${candidate.toMap()}');
          DebugFile.saveTextData(
              '[WebrtcReceiver.joinRoom] onIceCandidate: ${candidate.toMap()}');
          calleeCandidatesCollection.add(candidate.toMap());
        };
        // Code for collecting ICE candidate above

        _peerConnection?.onTrack = (RTCTrackEvent event) {
          print(
              '[WebrtcReceiver.joinRoom] Got remote track: ${event.streams[0]}');
          DebugFile.saveTextData(
              '[WebrtcReceiver.joinRoom] Got remote track: ${event.streams[0]}');
          event.streams[0].getTracks().forEach((track) {
            print(
                '[WebrtcReceiver.joinRoom] Adding a track to the remoteStream: $track');
            DebugFile.saveTextData(
                '[WebrtcReceiver.joinRoom] Adding a track to the remoteStream: $track');
            remoteStream?.addTrack(track);
          });
        };

        // Code for creating SDP answer below
        var data = roomSnapshot.data() as Map<String, dynamic>;
        print('[WebrtcReceiver.joinRoom] Got offer $data');
        DebugFile.saveTextData('[WebrtcReceiver.joinRoom] Got offer');
        var offer = data['offer'];
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );
        var answer = await _peerConnection!.createAnswer();
        print('[WebrtcReceiver.joinRoom] Created Answer $answer');
        DebugFile.saveTextData(
            '[WebrtcReceiver.joinRoom] Created Answer $answer');

        await _peerConnection!.setLocalDescription(answer);

        Map<String, dynamic> roomWithAnswer = {
          'answer': {'type': answer.type, 'sdp': answer.sdp}
        };

        await roomRef.update(roomWithAnswer);
        // Finished creating SDP answer

        // Listening for remote ICE candidates below
        roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
          snapshot.docChanges.forEach((document) {
            var data = document.doc.data() as Map<String, dynamic>;

            print(
                '[WebrtcReceiver.joinRoom] Got new remote ICE candidate: $data');
            DebugFile.saveTextData(
                '[WebrtcReceiver.joinRoom] Got new remote ICE candidate');
            _peerConnection!.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          });
        });

        connected = true;
        return 'joined';
      } catch (e) {
        print('[WebrtcReceiver.joinRoom] Error : ${e.toString()}');
        DebugFile.saveTextData(
            '[WebrtcReceiver.joinRoom] Error : ${e.toString()}');
      }
    }
    return 'could not join. have you created connection ?';
  }

  static Future<void> hangUp() async {
    try {
      if (remoteStream != null) {
        remoteStream!.getTracks().forEach((track) async {
          await track.stop();
        });
        remoteStream!.dispose();
      }
      if (_peerConnection != null) {
        print('[WebrtcReceiver.haungUp] closing _peerConnection');
        _peerConnection!.close();
      }
      connected = false;
    } catch (e) {
      print('[WebrtcReceiver.hangup] error ${e.toString()}');
      DebugFile.saveTextData('[WebrtcReceiver.hangup] error ${e.toString()}');
    }
  }

  static void registerPeerConnectionListeners(bool isJoinRoom) {
    _peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('[WebrtcReceiver] ICE gathering state changed: $state');
      DebugFile.saveTextData(
          '[WebrtcReceiver] ICE gathering state changed: $state');
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      if (myStreamController != null && !myStreamController!.isClosed)
        myStreamController!.add(state);

      print('[WebrtcReceiver] Connection state change: $state');
      DebugFile.saveTextData(
          '[WebrtcReceiver] Connection state change: $state');
    };

    _peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('[WebrtcReceiver] Signaling state change: $state');
      DebugFile.saveTextData('[WebrtcReceiver] Signaling state change: $state');
    };

    if (isJoinRoom) {
      print('[WebrtcReceiver] registering MediaStream to ui RTCVideoRenderer');
      DebugFile.saveTextData(
          '[WebrtcReceiver] registering MediaStream to ui RTCVideoRenderer');
      _peerConnection!.onAddStream = (MediaStream stream) {
        print("[WebrtcReceiver] Adding remote Stream.");
        DebugFile.saveTextData('[WebrtcReceiver] Adding remote Stream.');
        onAddRemoteStream?.call(stream);
        remoteStream = stream;
      };
    }
  }

  static openStream() {
    myStreamController = StreamController<RTCPeerConnectionState>();
  }

  static dispose() async {
    if (myStreamController != null) await myStreamController!.close();
  }
}
