import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'hello_platform_interface.dart';

/// An implementation of [HelloPlatform] that uses method channels.
class MethodChannelHello extends HelloPlatform {
  /// The method channel used to interact with the native platform.
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
}
