import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:sender_app/domain/local_firestore.dart';
import 'package:sender_app/domain/services/fl_background_service.dart';

import 'package:sender_app/domain/debug_printer.dart';

import 'package:sender_app/presentation/screens/login.dart';
import 'package:sender_app/presentation/screens/notification_screen.dart';
import 'package:sender_app/presentation/screens/sender_list_page.dart';
import 'package:sender_app/user/user_info.dart';
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
  bool _videoStreamRequest = false;
  bool _locationRequest = false;

  _selectTime(BuildContext context, int startEndType) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        startEndType == 0 ? startTime = pickedTime : endTime = pickedTime;
      });
    }
  }

  @override
  void initState() {
    print("request screen init fired");
    // TODO: implement initState
    super.initState();

    //fires sendData when locsendtime is present
  }

  bool checkStartEndTime(TimeOfDay time1, TimeOfDay time2) {
    // Convert TimeOfDay to minutes
    int minutes1 = time1.hour * 60 + time1.minute;
    int minutes2 = time2.hour * 60 + time2.minute;

    if (minutes1 > minutes2) {
      setState(() {
        _status = "Start time is less than end time";
      });
      return false;
    }
    if (minutes1 == minutes2) {
      setState(() {
        _status = "plz choose start and end time";
      });

      return false;
    }
    // Calculate absolute difference in minutes
    int difference = (minutes1 - minutes2).abs();

    // Check if the difference is at least 30 minutes
    if (difference <= 5) {
      setState(() {
        _status =
            '''Start time & end time differrence should be more than 5 minutes''';
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
                  },
                ),
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    final prefs = await SharedPreferences.getInstance();

                    prefs.clear();
                    print(" email in prefs ${prefs.getString('email')}");
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
                    //TODO: Navigate to the notifications screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SenderListPage(),
                        ));
                  },
                ),
                // IconButton(
                //   icon: Icon(Icons.stop_circle_outlined),
                //   onPressed: () async {
                //     await initializeService();
                //     FlutterBackgroundService service = FlutterBackgroundService();
                //     var status = await service.isRunning();
                //     print("status is $status");
                //     if (status) {
                //       print("service is running stopping service");
                //       service.invoke("stopService");

                //       const Toast(
                //         child: Text("service stopped"),
                //       );
                //       return;
                //     } else {
                //       print('[print] starting service');

                //       service.startService();
                //     }
                //     print("service is not running");
                //     const Toast(
                //       child: Text("service is not running"),
                //     );
                //   },
                // ),
                PopupMenuButton(
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'item1',
                      child: TextButton(
                          onPressed: () async {
                            await initializeService();
                            FlutterBackgroundService service =
                                FlutterBackgroundService();
                            var status = await service.isRunning();
                            print("status is $status");
                            if (status) {
                              print("service is running stopping service");
                              service.invoke("stopService");
                              setState(() {
                                _status =
                                    'service is running stopping service\n this will disconnect from receiver.';
                              });

                              return;
                            }
                            // } else {
                            //   print('[print] starting service');
                            //   setState(() {
                            //     _status =
                            //         'starting service this will reconnect to receiver';
                            //   });

                            //   service.startService();
                            // }
                            print("service is not running");
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
                    // PopupMenuItem<String>(
                    //   value: 'item2',
                    //   child: TextButton(
                    //       onPressed: () {
                    //         String path = TextDataHandler().localPath;
                    //         print('path is $path');
                    //         setState(() {
                    //           _status = path;
                    //         });
                    //       },
                    //       child: Container(
                    //         width: double.infinity,
                    //         decoration: BoxDecoration(
                    //             border: Border.all(color: Colors.grey)),
                    //         child: Text(
                    //           'click to get debug file path',
                    //           textAlign: TextAlign.center,
                    //           style: TextStyle(color: Colors.red),
                    //         ),
                    //       )),
                    // )

                    // Divider between regular items and custom TextButton
                    // Custom TextButton as a menu item
                  ],
                ),
              ],
            )
          ],
        ),
        body: SingleChildScrollView(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
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
                      Row(
                        children: [
                          Text('Video Streaming'),
                          Checkbox(
                              value: _videoStreamRequest,
                              onChanged: (bool? value) {
                                setState(() {
                                  _videoStreamRequest = value!;
                                });
                              }),
                          Text('Live Location'),
                          Checkbox(
                              value: _locationRequest,
                              onChanged: (bool? value) {
                                setState(() {
                                  _locationRequest = value!;
                                });
                              })
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          print("send location pressed");
                          setState(() {
                            _isLoading = true;
                          });
                          if (!(_locationRequest) && !(_videoStreamRequest)) {
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

                          if (rIdTxtCntrl.text == null) {
                            setState(() {
                              _status = 'user email is required';
                              _isLoading = false;
                            });
                            return;
                          }
                          var validatorMsg =
                              validateEmail(rIdTxtCntrl.text.trim());
                          print('validatorMsg is $validatorMsg');
                          if (validatorMsg != null) {
                            setState(() {
                              _status = validatorMsg;
                              _isLoading = false;
                            });
                            return;
                          }
                          // TODO: Handle the button press (send location request)

                          //json for server
                          List<String> services = [];

                          if (_locationRequest) {
                            services.add('LIVE_LOCATION');
                          }

                          if (_videoStreamRequest) {
                            services.add('VIDEO_STREAM');
                          }
                          //creating notification
                          final Map<String, dynamic> data = {
                            "userEmail": CurrentUser.user['userEmail'],
                            "receiverEmail": rIdTxtCntrl.text,
                            "startTime": startTime.format(context),
                            "endTime": endTime.format(context),
                            'services': services,
                            "type": "REQUEST"
                          };

                          FirestoreOps.sendNotification(data).then((value) {
                            if (value == 'SUCCESS') {
                              setState(() {
                                _status = 'Request sent';
                              });
                            } else {
                              setState(() {
                                _status = value;
                              });
                            }
                          });
                          setState(() {
                            _isLoading = false;
                          });
                        },
                        child: Text('Send Location Request'),
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
