import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:socket_io_client/socket_io_client.dart';

class RequestWebSocket {
  static RequestWebSocket? _instance;
  final Socket socket =
      io('https://websocket-server-set.glitch.me', <String, dynamic>{
    'transports': ['websocket'],
  });
  static RequestWebSocket getInstance() {
    _instance ??= RequestWebSocket();
    return _instance!;
  }

  Stream<Map<String, dynamic>> sendRequest(
      String userEmail, String senderEmail) {
    final Socket socket =
        io('https://websocket-server-set.glitch.me', <String, dynamic>{
      'transports': ['websocket'],
    });
    var socketId;
    var tries = 0;

    // Create a StreamController
    final _myStreamController = StreamController<Map<String, dynamic>>();
    Stream<Map<String, dynamic>> responseStream = _myStreamController.stream;

    // Function to add data to the stream
    void addDataToStream(Map<String, dynamic> data) {
      _myStreamController.add(data);
    }

    // Close the StreamController when it's no longer needed
    void dispose() {
      _myStreamController.close();
    }

    // Connect to the server
    socket.connect();

    socket.onConnectError((data) {
      print("could not connect");
      addDataToStream({
        "status": "COULD_NOT_CONNECT",
        "message": "failed to connect to server"
      });
    });

    socket.onConnect((_) {
      socketId = socket.id;
      print('Connected: $socketId');

      //sending location request to server
      socket.emit('locationRequest', {
        'userEmail': userEmail,
        'socketId': socketId,
        'senderEmail': senderEmail
      });

      //senderLocation received from server
      socket.once('senderLocation', (data) {
        print('Received data from server: $data');
        addDataToStream(
            {"status": "SENDER_LOCATION", "data": data['data']['location']});
        socket.disconnect();
        socket.destroy();
      });

      //server message
      socket.on('serverMessage', (data) async {
        print('server message: $data');
        addDataToStream(
            {"status": 'SERVER_MESSAGE', "message": data.toString()});

        if (data['code'] == "NO_RECEIVER_CONNECTED") {
          if (tries <= 4) {
            print(
                'receiver is yet to connect to server. retrying in 10 secs, remianing tries: ${4 - tries}');
            addDataToStream({
              'status': "NO_RECEIVER_CONNECTED",
              'message':
                  'receiver is yet to connect to server. retrying in 10 secs, remianing tries: ${4 - tries}'
            });
            await Future.delayed(const Duration(seconds: 10));

            socket.emit('locationRequest', {
              'userEmail': userEmail,
              'socketId': socketId,
              'senderEmail': senderEmail
            });
          }

          tries++;
        }
      });
    });

    return responseStream;
  }

  disconnect() {
    if (socket.connected) {
      print("socket happens to be connected");
      print("disconnecting");
      socket.disconnect();
      print("disconnected");
    }
  }

  bool isConnected() {
    return socket.connected;
  }
}
