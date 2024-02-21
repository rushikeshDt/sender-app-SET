import 'dart:async';

import 'package:sender_app/network/client.dart';
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

  Stream<String> sendRequest(String uId, String senderId) {
    final Socket socket =
        io('https://websocket-server-set.glitch.me', <String, dynamic>{
      'transports': ['websocket'],
    });
    var socketId;
    var tries = 0;

    // Create a StreamController
    final _myStreamController = StreamController<String>();
    Stream<String> responseStream = _myStreamController.stream;

    // Function to add data to the stream
    void addDataToStream(String data) {
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
      addDataToStream("could not connect");
    });

    socket.onConnect((_) {
      socketId = socket.id;
      print('Connected: $socketId');

      //sending location request to server
      socket.emit('locationRequest',
          {'uId': uId, 'socketId': socketId, 'senderId': senderId});

      //senderLocation received from server
      socket.once('senderLocation', (data) {
        print('Received data from server: $data');
        addDataToStream(data.toString() + "\n dissconnecting....");
        socket.disconnect();
        socket.destroy();
      });

      //server message
      socket.on('serverMessage', (data) async {
        print('server message: $data');
        addDataToStream(data.toString());

        if (data['code'] == "NO_RECEIVER_CONNECTED") {
          if (tries <= 4) {
            print(
                'receiver is yet to connect to server. retrying in 10 secs, remianing tries: ${4 - tries}');
            addDataToStream(
                'receiver is yet to connect to server. retrying in 10 secs, remianing tries: ${4 - tries}');
            await Future.delayed(const Duration(seconds: 10));

            socket.emit('locationRequest',
                {'uId': uId, 'socketId': socketId, 'senderId': senderId});
          }

          tries++;
        }
      });
    });

    Client clnt = new Client();

    //creating notification
    clnt.post("sendNotification/", {
      "userId": "r1",
      "receiverId": "s1",
      "startTime": "2:06pm",
      "endTime": "3:06pm",
      "reqFlag": "true"
    }).then((value) async {
      print("response is ${value}");
      print("request sent !");
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
}
