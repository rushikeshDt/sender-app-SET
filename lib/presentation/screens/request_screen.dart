import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:sender_app/domain/local_firestore.dart';
import 'package:sender_app/domain/services/call_native_code.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';

import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/domain/experimental/legacy_fl_background_service.dart';
import 'package:sender_app/presentation/screens/about_screen.dart';

import 'package:sender_app/presentation/screens/login.dart';
import 'package:sender_app/presentation/screens/notification_screen.dart';
import 'package:sender_app/presentation/screens/sender_list_page.dart';
import 'package:sender_app/utils/sort.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:sender_app/utils/extensions/time_of_day_extension.dart';
import 'package:sender_app/utils/validate_email.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestPage extends StatefulWidget {
  RequestPage();
  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  TextEditingController rIdTxtCntrl = new TextEditingController();
  late TimeOfDay startTime = TimeOfDay.now();
  late TimeOfDay endTime = TimeOfDay.now();
  String _status = "validation message will be displayed here";
  bool _isLoading = false;

  List<String> services = [];

  _selectTime(BuildContext context, int startEndType) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    print("picked time" + pickedTime.toString());
    if (pickedTime != null) {
      setState(() {
        startEndType == 0 ? startTime = pickedTime : endTime = pickedTime;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //fires sendData when locsendtime is present
  }

  bool checkStartEndTime(TimeOfDay time1, TimeOfDay time2) {
    int code = time1.CompareTo(time2);
    debugPrint("code is $code");
    switch (code) {
      case 1:
        setState(() {
          _status = "Start time is more than end time";
        });
        return false;
      case 2:
        setState(() {
          _status = "Please choose start and end time";
        });
        return false;
      case 3:
        setState(() {
          _status =
              'Start time & end time differrence should be more than 5 minutes';
        });
        return false;
      case 4:
        setState(() {
          _status =
              "Please choose start time atleast 1 minute after present time";
        });
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Location Request'),
          actions: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationPage(),
                        ));
                    // await callNativeMethod();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    var service = FlutterBackgroundService();
                    bool status = await service.isRunning();
                    if (status) {
                      service.invoke('stopService');
                    }
                    await FirebaseAuth.instance.signOut();
                    final prefs = await SharedPreferences.getInstance();

                    prefs.clear();

                    // TODO: Navigate to the notifications screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.location_history),
                  onPressed: () {
                    // //TODO: Navigate to the notifications screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SenderListPage(),
                        ));
                  },
                ),
                PopupMenuButton(
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'item1',
                      child: TextButton(
                          onPressed: () async {
                            DebugFile.saveTextData(
                                '[RequestPage] User manually stopping service');

                            FlutterBackgroundService service =
                                FlutterBackgroundService();
                            var status = await service.isRunning();

                            if (status) {
                              DebugFile.saveTextData(
                                  "[RequestPage] service is running stopping service");
                              service.invoke("stopService");
                              setState(() {
                                _status =
                                    'service is running stopping service\n this will disconnect from receiver.';
                              });
                              DebugFile.saveTextData(
                                  "[RequestPage] service is not running ");

                              return;
                            } else {
                              print('[print] starting service');
                              setState(() {
                                _status =
                                    'starting service this will reconnect to receiver';
                              });

                              service.startService();
                            }

                            setState(() {
                              _status = 'service is not running';
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey)),
                            child: Text(
                              'stop sending',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                          )),
                    ),
                    PopupMenuItem<String>(
                      value: 'item2',
                      child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => AboutPage()));
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey)),
                            child: Text(
                              'About page',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                          )),
                    ),

                    // Divider between regular items and custom TextButton
                    // Custom TextButton as a menu item
                  ],
                ),
              ],
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            InputDecoration(labelText: 'Enter user email'),
                        controller: rIdTxtCntrl,
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _selectTime(context, 0),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(
                              text: startTime.format(context),
                            ),
                            decoration: const InputDecoration(
                                labelText: 'Select Start Time'),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _selectTime(context, 1),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(
                              text: endTime.format(context),
                            ),
                            decoration:
                                InputDecoration(labelText: 'Select End Time'),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Choose Services',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        child: Column(
                          children: [
                            Text('Video Streaming'),
                            Checkbox(
                                value: services.contains('VIDEO_STREAM'),
                                onChanged: (bool? value) {
                                  setState(() {
                                    value!
                                        ? services.add('VIDEO_STREAM')
                                        : services.remove('VIDEO_STREAM');
                                  });
                                }),
                            Text('Live Location'),
                            Checkbox(
                                value: services.contains('LIVE_LOCATION'),
                                onChanged: (bool? value) {
                                  setState(() {
                                    value!
                                        ? services.add('LIVE_LOCATION')
                                        : services.remove('LIVE_LOCATION');
                                  });
                                }),
                            Text('Audio Streaming'),
                            Checkbox(
                                value: services.contains('AUDIO_STREAM'),
                                onChanged: (bool? value) {
                                  setState(() {
                                    value!
                                        ? services.add('AUDIO_STREAM')
                                        : services.remove('AUDIO_STREAM');
                                  });
                                })
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            setState(() {
                              _isLoading = true;
                            });
                            if (rIdTxtCntrl.text.isEmpty) {
                              setState(() {
                                _status = 'user email is required';
                                _isLoading = false;
                              });
                              return;
                            }
                            if (services.isEmpty) {
                              setState(() {
                                _isLoading = false;
                                _status = 'Choose atleast one service';
                              });
                              return;
                            }
                            if (!checkStartEndTime(startTime, endTime)) {
                              setState(() {
                                _isLoading = false;
                              });
                              return;
                            }

                            var validatorMsg =
                                validateEmail(rIdTxtCntrl.text.trim());

                            if (validatorMsg != null) {
                              setState(() {
                                _status = validatorMsg;
                                _isLoading = false;
                              });
                              return;
                            }
                            DebugFile.saveTextData(
                                '[RequestPage] Sending request');
                            var newStartTime =
                                "${startTime.hour}:${startTime.minute}";
                            var newEndTime =
                                "${endTime.hour}:${endTime.minute}";
                            print("starttime $newStartTime $newEndTime");
                            //creating notification
                            final Map<String, dynamic> data = {
                              "userEmail": CurrentUser.user['userEmail'],
                              "receiverEmail": rIdTxtCntrl.text,
                              "startTime": newStartTime,
                              "endTime": newEndTime,
                              'services': services,
                              "type": "REQUEST"
                            };

                            await FirestoreOps.sendNotification(data)
                                .then((value) {
                              if (value == 'SUCCESS') {
                                setState(() {
                                  services.clear();
                                  _status = 'Request sent';
                                });
                              } else {
                                setState(() {
                                  services.clear();
                                  _status = value;
                                });
                              }
                            });
                            setState(() {
                              _isLoading = false;
                            });
                          } catch (e) {
                            DebugFile.saveTextData(
                                '[RequestPage] Error while sending request: ${e.toString()}');
                          }
                        },
                        child: Text('Send  Request'),
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(16.0),
                        color: Colors.grey,
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
  }
}
