import 'package:flutter/material.dart';

class DeviceInfo {
  double getDeviceWidth(context) => MediaQuery.of(context).size.width;
  double getDeviceHeight(context) => MediaQuery.of(context).size.height;
  static DeviceInfo _instance = DeviceInfo();

  static DeviceInfo getInstance() {
    return _instance;
  }
}
