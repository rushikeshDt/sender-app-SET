import 'package:flutter/services.dart';
import 'package:hello/hello.dart';
import 'package:sender_app/domain/experimental/video_recorder.dart';

const platform = MethodChannel('com.example/my_channel');

Future<void> callNativeMethod() async {
  try {
    Hello hello = Hello();
    var result = await hello.getPlatformVersion();
    print(result);
  } catch (e) {
    print('Failed to invoke native method: $e');
  }
}
