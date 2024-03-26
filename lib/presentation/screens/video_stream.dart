import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/experimental/fl_background_service.dart';

import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/domain/experimental/video_stream_client.dart';
import 'package:sender_app/domain/webrtc_receiver.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:sender_app/utils/upload_file_to_cloud.dart';

class VideoStreamPage extends StatefulWidget {
  late String senderEmail;
  late Map<String, bool> options;

  VideoStreamPage({Key? key, required this.senderEmail, required this.options})
      : super(key: key);

  @override
  _VideoStreamPagePageState createState() =>
      _VideoStreamPagePageState(senderEmail: senderEmail, options: options);
}

class _VideoStreamPagePageState extends State<VideoStreamPage> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  TextEditingController textEditingController = TextEditingController(text: '');
  String? status;
  String? rtcConnectionStatus;
  late String userEmail;
  late String senderEmail;
  late Map<String, bool> options;
  late StreamSubscription? subscription;
  _VideoStreamPagePageState({required this.senderEmail, required this.options});
  @override
  void initState() {
    userEmail = CurrentUser.user['userEmail'];
    WebrtcReceiver.openStream();
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    WebrtcReceiver.onAddRemoteStream = ((stream) {
      print('[VideoStream] remoteStream added');
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });
    updateRTCConnection();
    listenForSenderReply();
    sendCreateRoom();
    super.initState();
  }

  @override
  void dispose() {
    sendHangUp();
    subscription ?? subscription!.cancel();
    WebrtcReceiver.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    dynamic height = MediaQuery.of(context).size.height;
    dynamic width = MediaQuery.of(context).size.width;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {});
                },
                icon: Icon(Icons.restart_alt)),
            // ElevatedButton(
            //   onPressed: () async {
            //     //connect to sender
            //     await WebrtcReceiver.joinRoom(
            //         receiverEmail: userEmail, senderEmail: senderEmail);
            //   },
            //   child: Text("Join"),
            // ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  status = 'HANGING_UP';
                });

                var response = await sendHangUp();

                setState(() {
                  status = response;
                });
              },
              child: Text("Hangup"),
            ),
          ],
        ),
        body: Container(
            width: DeviceInfo.getDeviceWidth(context),
            child: Center(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.red)),
                        width: width,
                        height: height,
                        child: RTCVideoView(_remoteRenderer)),
                  ),
                  SizedBox(height: 8),
                  Positioned(
                    width: DeviceInfo.getDeviceWidth(context),
                    top: 10,
                    left: 10,
                    child: Text(
                      softWrap: true,
                      'SESSION: ${status ?? ''}',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    width: DeviceInfo.getDeviceWidth(context),
                    top: 50,
                    left: 10,
                    child: Text(
                      softWrap: true,
                      'RTC_CONNECTION: ${rtcConnectionStatus ?? ''}',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
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
          msg = 'CONNECTED';
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
        rtcConnectionStatus = msg;
      });
    });
  }

  listenForSenderReply() async {
    try {
      subscription = FirebaseFirestore.instance
          .collection('sessions')
          .doc(userEmail)
          .collection(senderEmail)
          .doc('messages')
          .snapshots()
          .listen((snapshot) async {
        print(
            '[VideoStream.listenForSenderReply] obtained messages document snapshot ${snapshot.data()}');
        DebugFile.saveTextData(
            '[VideoStream.listenForSenderReply] obtained messages document snapshot ${snapshot.data()}');
        var reply =
            snapshot.data() == null ? 'no session' : snapshot.data()!['reply'];
        if (reply != null && mounted) {
          if (reply == 'ROOM_CREATED') {
            await WebrtcReceiver.joinRoom(
                receiverEmail: userEmail, senderEmail: senderEmail);
          }
          setState(() {
            status = reply;
          });
        }
      });
    } catch (e) {
      print('[VideoStreamPage.listenForSenderReply] Error ${e.toString()}');
      DebugFile.saveTextData(
          '[VideoStreamPage.listenForSenderReply] Error ${e.toString()}');
    }
  }

  sendCreateRoom() async {
    try {
      setState(() {
        status = 'Sending request.';
      });
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(userEmail)
          .collection(senderEmail)
          .doc('messages')
          .set({'command': 'CREATE_ROOM', 'options': options});
      print('[VideoStreamPage.sendCreateRoom] CREATE_ROOM command sent');
      DebugFile.saveTextData(
          '[VideoStreamPage.sendCreateRoom] CREATE_ROOM command sent');
      setState(() {
        status = 'Request sent. Waiting.';
      });
    } catch (e) {
      print(
          '[VideoStreamPage.sendCreateRoom] error sending command ${e.toString()}');
      DebugFile.saveTextData(
          '[VideoStreamPage.sendCreateRoom] error sending command ${e.toString()}');
    }
  }

  Future<String> sendHangUp() async {
    try {
      print('connected is ${WebrtcReceiver.connected}');
      if (WebrtcReceiver.connected == null) return "No connection";
      if (WebrtcReceiver.connected!) {
        await WebrtcReceiver.hangUp();
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(userEmail)
            .collection(senderEmail)
            .doc('messages')
            .set({'command': 'HANG_UP'});

        return 'SENT';
      }
      return 'NOT_CONNECTED';
    } catch (e) {
      DebugFile.saveTextData(
          '[VideoStreamPage.sendHangUp] Error ${e.toString()}');
      return 'Error ${e.toString()}';
    }
  }
}
