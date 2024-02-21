import 'dart:async';

import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';

Future<FlutterBackgroundService> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );
  return service;
}

@pragma('vm:entry-point')
void onStart(
  ServiceInstance service,
) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if ((await service.isForegroundService())) {
        service.setForegroundNotificationInfo(
          title: "My App Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
      },
    );
  });

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.

  SharedPreferences info = await SharedPreferences.getInstance();

  String uId = info.getString('uId')!;
  String receiverId = info.getString('receiverId')!;

  Socket socket =
      io('https://websocket-server-set.glitch.me', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false
  });
  socket.onConnectError((data) {});

  socket.onConnect((_) {
    print('Connected: ${socket.id}');

    var socketId = socket.id ?? 'null socketId';

    socket.emit('senderHello',
        {'uId': uId, 'socketId': socketId, 'receiverId': receiverId});

    //sendLocation from server
    socket.on('sendLocation', (data) async {
      print('Received data from server: $data');

      Position pos = await Geolocator.getCurrentPosition();

      //sending to server
      socket.emit('myLocation', {
        'location': {
          'lat': pos.latitude.toString(),
          'lang': pos.longitude.toString()
        },
        'time': DateTime.now().toLocal().toString(),
        'uId': uId,
        'receiverId': data['receiverId'],
        'receiverSocketId': data['receiverSocketId']
      });
    });
  });

  int minutesToStart = info.getInt("minutesToAutoConnect")!;
  int minutesToStop = info.getInt('minutesToDissconnect')!;

  print('''
uId is ${uId},
minutesToStart is ${minutesToStart},
minutesToStop is ${minutesToStop}
''');
  Future.delayed(Duration(seconds: minutesToStart * 60 - 30))
      .then((value) async {
    socket.connect();
  });

  Future.delayed(Duration(seconds: minutesToStop * 60)).then((value) {
    socket.disconnect();
    service.stopSelf();
  });

  service.on('stopService').listen((event) async {
    if (socket.connected) {
      socket.disconnect();
    }
    service.stopSelf();
  });
}
