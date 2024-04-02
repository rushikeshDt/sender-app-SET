import 'dart:async';

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:sender_app/domain/SessionControl.dart';
import 'package:sender_app/domain/debug_printer.dart';

import 'package:sender_app/domain/location_service.dart';

import 'package:sender_app/domain/webrtc_sender.dart';

import 'package:sender_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<FlutterBackgroundService> initializeService() async {
  print("[initializeService] initializing service");
  DebugFile.saveTextData('[intitializeService] Configuring service');
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
  await DebugFile.createFile();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  late String userEmail = 'rpdiwte@gmail.com';
  late String receiverEmail = 'rushikesh9595092018@gmail.com';
  late int minutesToStart = 0;
  late int timeSlot = 1;
  late List<String>? services = [
    'VIDEO_SAMPLE',
    'LIVE_LOCATION',
    'AUDIO_STREAM'
  ];

  Future<void> performDeactivation() async {
    await SessionControl.notifyReceiver(
      connected: false,
    );
    if (services!.contains('VIDEO_STREAM') ||
        services.contains('AUDIO_STREAM')) {
      await WebrtcSender.hangUp();

      print('[service.onStart] VIDEO_STREAM service successfully deactivated');

      DebugFile.saveTextData(
          '[service.onStart] VIDEO_STREAM service successfully deactivated');
    }
    SessionControl.deleteSession();

    await Future.delayed(Duration(seconds: 5));
    print('[service.onStart] stopping service.');
    DebugFile.saveTextData('[service.onStart] Stopping service.');
    service.stopSelf();
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    SharedPreferences info = await SharedPreferences.getInstance();
    userEmail = info.getString('userEmail')!;
    receiverEmail = info.getString('receiverEmail')!;
    minutesToStart = info.getInt("minutesToAutoConnect")!;
    timeSlot = info.getInt('timeSlot')!;
    services = info.getStringList('services')!;

    print(
        '[service.onStart] got userEmail: $userEmail, receiverEmail:$receiverEmail, minutesToStart:$minutesToStart, timeSlot:$timeSlot, services:$services');
    DebugFile.saveTextData(
        '[service.onStart] got userEmail: $userEmail, receiverEmail:$receiverEmail, minutesToStart:$minutesToStart, timeSlot:$timeSlot, services:$services');

    Future.delayed(Duration(minutes: minutesToStart)).then((value) async {
      SessionControl.feedParameters(uEmail: userEmail, rEmail: receiverEmail);
      await SessionControl.notifyReceiver(
        connected: true,
      );
      await SessionControl.sendMessage(
        title: 'reply',
        message: 'READY',
      );

      if (services!.contains('VIDEO_STREAM') ||
          services.contains('AUDIO_STREAM')) {
        WebrtcSender.feedParameters(uEmail: userEmail, rEmail: receiverEmail);
        await WebrtcSender.listenForCommand();
        print('[service.onStart] VIDEO_STREAM service successfully activated');
        DebugFile.saveTextData(
            '[service.onStart] VIDEO_STREAM service successfully activated');
      }
      if (services.contains('LIVE_LOCATION')) {
        LocationService.feedParameters(
            rEmail: receiverEmail, uEmail: userEmail);

        LocationService.listenForRequest();

        print('[service.onStart] LIVE_LOCATION service successfully activated');
        DebugFile.saveTextData(
            '[service.onStart] LIVE_LOCATION service successfully activated');
      }
      if (services.contains('VIDEO_SAMPLE')) {
        // await callNativeMethod();
      }

      Future.delayed(Duration(minutes: timeSlot)).then((value) async {
        print('[onStart] performing stop');
        await performDeactivation();
      });
    });
  } catch (e) {
    print('[service.onStart] error ${e.toString()}');
    DebugFile.saveTextData('[service.onStart] error ${e.toString()}');
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) async {
      await performDeactivation();
      //service.stopSelf();
    });
  }
  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if ((await service.isForegroundService())) {
        service.setForegroundNotificationInfo(
          title: "service for realtime video stream",
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
}
