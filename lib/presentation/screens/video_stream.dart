import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';
import 'package:sender_app/domain/signaling.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:sender_app/utils/upload_file_to_cloud.dart';

class VideoStreamPage extends StatefulWidget {
  late String senderEmail;
  VideoStreamPage({Key? key, required this.senderEmail}) : super(key: key);

  @override
  _VideoStreamPagePageState createState() =>
      _VideoStreamPagePageState(senderEmail: senderEmail);
}

class _VideoStreamPagePageState extends State<VideoStreamPage> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  TextEditingController textEditingController = TextEditingController(text: '');
  String? status;
  String? rtcConnectionStatus;
  late String userEmail;
  late String senderEmail;

  _VideoStreamPagePageState({required this.senderEmail});
  @override
  void initState() {
    userEmail = CurrentUser.user['userEmail'];
    Signaling.restartStream();
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    Signaling.onAddRemoteStream = ((stream) {
      print('[VideoStream] remoteStream added');
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });
    updateStatus();
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(userEmail)
        .collection(senderEmail)
        .doc('messages')
        .snapshots()
        .listen((snapshot) {
      print(
          '[VideoStream] obtained messages document snapshot ${snapshot.data()}');
      DebugFile.saveTextData(
          '[VideoStream] obtained messages document snapshot ${snapshot.data()}');
      var reply = snapshot.data()!['reply'];
      if (reply != null) {
        setState(() {
          status = reply;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(userEmail)
        .collection(senderEmail)
        .doc('messages')
        .set({'command': 'HANG_UP'});
    setState(() {
      status = 'HANG_UP sent to sender';
    });

    Signaling.dispose();
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
            ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('sessions')
                        .doc(userEmail)
                        .collection(senderEmail)
                        .doc('messages')
                        .set({'command': 'CREATE_ROOM'});
                    print('[VideoStreamPage] command sent');

                    setState(() {
                      status = 'REQUEST_SENT';
                    });
                  } catch (e) {
                    print(
                        '[VideoStreamPage] error sending command ${e.toString()}');
                  }
                },
                child: Text('create')),
            ElevatedButton(
              onPressed: () async {
                //connect to sender
                await Signaling.joinRoom(
                    receiverEmail: userEmail, senderEmail: 'senderEmail');
              },
              child: Text("Join"),
            ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () async {
                if (Signaling.peerConnection != null) {
                  await FirebaseFirestore.instance
                      .collection('sessions')
                      .doc(userEmail)
                      .collection(senderEmail)
                      .doc('messages')
                      .set({'command': 'HANG_UP'});
                  setState(() {
                    status = 'HANG_UP sent to sender';
                  });
                } else {
                  setState(() {
                    status = 'NOT_CONNECTED';
                  });
                }
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

  updateStatus() {
    Signaling.myStreamController.stream.listen((event) {
      late String msg;
      switch (event) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          msg = 'CONNECTING';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          msg = 'CONNECTED';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          msg = 'HUNG UP';
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
}
