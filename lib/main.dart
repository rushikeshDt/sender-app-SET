import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';
import 'package:sender_app/firebase_options.dart';
import 'package:sender_app/presentation/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final datetime = DateTime.now().toLocal().toString();
  await DebugFile.createFile();
  DebugFile.saveTextData(
      '\n##############[main] Starting app at $datetime##############');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  await _geoServices();
  await requestPermissions();
  await initializeService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: LoginPage());
  }
}

_geoServices() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    print('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      print('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    print(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
}

Future<bool> requestPermissions() async {
  // Request camera permission
  var cameraStatus = await Permission.camera.request();

  // Request microphone permission
  var microphoneStatus = await Permission.microphone.request();

  var storagePerm = await Permission.storage.request();
  // Request media volume permission (Note: This permission is not directly available, you might want to handle this differently based on your requirement)
  // For example, you can check if the device supports audio recording using audio_service package.

  // Check if all permissions are granted
  bool permissionsGranted =
      cameraStatus.isGranted && microphoneStatus.isGranted;

  return permissionsGranted;
}
