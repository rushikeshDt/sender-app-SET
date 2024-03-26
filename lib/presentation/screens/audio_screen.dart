import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/domain/webrtc_receiver.dart';
import 'package:sender_app/user/user_info.dart';

class AudioStreamPage extends StatefulWidget {
  late String senderEmail;
  AudioStreamPage({super.key, required this.senderEmail});

  @override
  State<AudioStreamPage> createState() =>
      _AudioStreamPageState(senderEmail: senderEmail);
}

class _AudioStreamPageState extends State<AudioStreamPage> {
  @override
  RTCVideoRenderer _renderer = RTCVideoRenderer();
  late MediaStream _audioStream;
  String senderEmail;
  String userEmail = CurrentUser.user['userEmail'];
  String _status = '';
  String _streamingStatus = '';

  _AudioStreamPageState({required this.senderEmail});
  void initState() {
    _renderer.initialize();
    WebrtcReceiver.onAddRemoteStream = (stream) {
      _audioStream = stream;
    };
    WebrtcReceiver.openStream();
    sendCreateRoom();
    listenForSenderReply();
    updateRTCConnection();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    sendHangUp();
    WebrtcReceiver.dispose();
    _renderer.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  await sendCreateRoom();
                },
                icon: Icon(Icons.restart_alt)),
            SizedBox(
              width: 10,
            ),
            IconButton(
                onPressed: () async {
                  setState(() {
                    _status = 'Hanging up';
                  });
                  bool hangUpSucc = await sendHangUp();

                  setState(() {
                    _status = hangUpSucc ? 'hung up' : 'problem hanging up';
                  });

                  setState(() {
                    _status = 'NOT_CONNECTED';
                  });
                },
                icon: Icon(Icons.stop_circle_outlined))
          ],
        ),
        body: Center(
            child: Padding(
          padding: EdgeInsets.all(5),
          child: Container(
            child: Column(
              children: [
                Text('Session Status: $_status'),
                SizedBox(
                  height: 10,
                ),
                Text('Streaiming Status: $_streamingStatus'),
                Container(
                  height: 1,
                  width: 1,
                  child: RTCVideoView(_renderer),
                )
              ],
            ),
          ),
        )));
  }

  updateRTCConnection() {
    WebrtcReceiver.myStreamController!.stream.listen((event) {
      late String msg;
      switch (event) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          msg = 'CONNECTING';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          msg = 'STREAMING';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          msg = 'FAILED';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          msg = 'DISCONNECTED';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          msg = 'CLOSED';

          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
          msg = 'NEW_CONNECTION';
          break;
        default:
      }
      setState(() {
        _streamingStatus = msg;
      });
    });
  }

  listenForSenderReply() async {
    try {
      FirebaseFirestore.instance
          .collection('sessions')
          .doc(userEmail)
          .collection(senderEmail)
          .doc('messages')
          .snapshots()
          .listen((snapshot) async {
        print(
            '[AudioStreamPage.listenForSenderReply] obtained messages document snapshot ${snapshot.data()}');
        DebugFile.saveTextData(
            '[AudioStreamPage.listenForSenderReply] obtained messages document snapshot ${snapshot.data()}');
        String reply = snapshot.data() == null
            ? 'no session'
            : snapshot.data()!['reply'] ??= 'sender yet to connect';

        if (mounted) {
          print('reply is $reply');
          setState(() {
            _status = reply;
          });
          if (reply == 'ROOM_CREATED') {
            await WebrtcReceiver.joinRoom(
                receiverEmail: userEmail, senderEmail: senderEmail);
          }
        }
      });
    } catch (e) {
      print('[AudioStreamPage.listenForSenderReply] Error ${e.toString()}');
      DebugFile.saveTextData(
          '[AudioStreamPage.listenForSenderReply] Error ${e.toString()}');
    }
  }

  Future<void> sendCreateRoom() async {
    try {
      setState(() {
        _status = 'Sending request.';
      });
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(userEmail)
          .collection(senderEmail)
          .doc('messages')
          .set({
        'command': 'CREATE_ROOM',
        'options': {
          'FRONT_CAM': false,
          'AUDIO_ONLY': true,
        }
      });
      print('[AudioStreamPage.sendCreateRoom] CREATE_ROOM command sent');
      DebugFile.saveTextData(
          '[AudioStreamPage.sendCreateRoom] CREATE_ROOM command sent');
      setState(() {
        _status = 'Request sent. Waiting.';
      });
    } catch (e) {
      print(
          '[AudioStreamPage.sendCreateRoom] error sending command ${e.toString()}');
      DebugFile.saveTextData(
          '[AudioStreamPage.sendCreateRoom] error sending command ${e.toString()}');
    }
  }

  Future<bool> sendHangUp() async {
    try {
      if (WebrtcReceiver.connected == null) return false;
      if (WebrtcReceiver.connected!) {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(userEmail)
            .collection(senderEmail)
            .doc('messages')
            .set({'command': 'HANG_UP'});
        await WebrtcReceiver.hangUp();
        return true;
      }
      return false;
    } catch (e) {
      DebugFile.saveTextData(
          '[AudioStreamPage.sendHangUp] Error ${e.toString()}');
      return false;
    }
  }
}
