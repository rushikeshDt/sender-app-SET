import 'package:flutter/material.dart';

class DeviceInfo {
  static double getDeviceWidth(context) => MediaQuery.of(context).size.width;
  static double getDeviceHeight(context) => MediaQuery.of(context).size.height;
}
