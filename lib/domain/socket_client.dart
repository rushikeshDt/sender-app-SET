import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketClient {
  static Socket socket =
      io('https://websocket-server-set.glitch.me', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false
  });
  static late String userEmail;
  static late String receiverEmail;
  static feedParameters({required String uEmail, required String rEmail}) {
    userEmail = uEmail;
    receiverEmail = rEmail;
  }

  static registerEvents() {
    socket.onConnectError((data) {});

    socket.onConnect((_) {
      print('Connected: ${socket.id}');

      var socketId = socket.id ?? 'null socketId';

      socket.emit('senderHello', {
        'userEmail': userEmail,
        'socketId': socketId,
        'receiverEmail': receiverEmail
      });

      // sendLocation from server
      socket.on('sendLocation', (data) async {
        print('Received data from server: $data');

        Position pos = await Geolocator.getCurrentPosition();

        // sending to server
        socket.emit('myLocation', {
          'location': {
            'lat': pos.latitude.toString(),
            'lang': pos.longitude.toString()
          },
          'time': DateTime.now().toLocal().toString(),
          'userEmail': userEmail,
          'receiverEmail': data['receiverEmail'],
          'receiverSocketId': data['receiverSocketId']
        });
      });
    });
  }
}

connectToSocketServer() {
  // notifyReceiver(bool connected) async {
  //   print("[print] notifyReceiver called");
  //   print("[print] updating document");
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  //   CollectionReference collectionReference =
  //       FirebaseFirestore.instance.collection('availableSenders');
  //   DocumentReference documentReference =
  //       collectionReference.doc(receiverEmail);
  //   documentReference.set({
  //     userEmail: {
  //       'connected': connected,
  //     }
  //   }, SetOptions(merge: true));

  //print("[print] document updated");}

  // Future.delayed(Duration(seconds: minutesToStart * 60 - 30))
  //     .then((value) async {
  //   await notifyReceiver(true);
  //   socket.connect();
  // });

  // Future.delayed(Duration(seconds: minutesToStop * 60)).then((value) async {
  //   await notifyReceiver(false);
  //   socket.disconnect();
  //   service.stopSelf();
  // });
}
