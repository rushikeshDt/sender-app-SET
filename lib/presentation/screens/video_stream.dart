import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';
import 'package:sender_app/domain/signaling.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/utils/upload_file_to_cloud.dart';

class VideoStreamPage extends StatefulWidget {
  String roomId;
  VideoStreamPage({Key? key, required this.roomId}) : super(key: key);

  @override
  _VideoStreamPagePageState createState() =>
      _VideoStreamPagePageState(roomId: roomId);
}

class _VideoStreamPagePageState extends State<VideoStreamPage> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  TextEditingController textEditingController = TextEditingController(text: '');
  String? status;
  late String roomId;
  _VideoStreamPagePageState({required this.roomId});
  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    Signaling.onAddRemoteStream = ((stream) {
      print('[VideoStream] remoteStream added');
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
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
                setState(() {
                  status = roomId;
                });

                //connect to sender
                Signaling.joinRoom(
                  roomId: roomId,
                );
                setState(() {
                  status = 'room joined';
                });
              },
              child: Text("Join room"),
            ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () async {
                if (Signaling.peerConnection != null) {
                  Signaling.peerConnection!.close();
                  setState(() {
                    status = 'hung up';
                  });
                } else {
                  setState(() {
                    status = 'not connected';
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
                    top: 10,
                    left: 10,
                    child: Text('status ${status ?? 'empty'}'),
                  ),
                ],
              ),
            )));
  }
}
