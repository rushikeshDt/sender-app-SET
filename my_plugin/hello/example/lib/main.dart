import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hello/hello.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  runApp(const MyApp());
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _helloPlugin = Hello();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _helloPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}

@visibleForTesting
final methodChannel = const MethodChannel('hello');

@override
Future<String?> getPlatformVersion() async {
  Directory dir = await getApplicationDocumentsDirectory();
  String path = dir.path;
  print("got path ${path}");
  final version = await methodChannel
      .invokeMethod<String>('startRecording', {'path': path});
  return version;
}
