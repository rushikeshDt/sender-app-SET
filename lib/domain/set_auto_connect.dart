import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

setAutoConnect({
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required String receiverId,
}) {
  late int minutesToAutoConnect;
  late int minutesToDissconnect;
  late int timeSlot;
  final service = FlutterBackgroundService();

  int _calculateTimeDifference(TimeOfDay startTime, TimeOfDay endTime) {
    // Convert time to minutes
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;

    // Calculate the time difference
    int difference = endMinutes - startMinutes;
    print(
        'calculating difference in autoConnect. start time is $startTime & endTime is $endTime');
    return difference;
  }

  Future<void> saveToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setInt('timeSlot', timeSlot);
    prefs.setString('uId', UserInfo.userId);
    prefs.setString('receiverId', receiverId);

    prefs.setInt('minutesToAutoConnect',
        minutesToAutoConnect > 1 ? minutesToAutoConnect : 0);
    prefs.setInt('minutesToDissconnect', minutesToDissconnect);
  }

  timeSlot = _calculateTimeDifference(startTime, endTime);
  //setting auto connect 5 minutes earlier
  minutesToAutoConnect =
      _calculateTimeDifference(TimeOfDay.now(), startTime); //-5
  minutesToDissconnect = _calculateTimeDifference(TimeOfDay.now(), endTime);
  saveToSharedPreferences().then(
      (value) => print("successfully stored values in sharedpreferences"));
  initializeService();
  service.startService();
}
