import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:sender_app/network/client.dart';
import 'package:sender_app/presentation/screens/notification_screen.dart';
import 'package:sender_app/presentation/screens/sender_list_page.dart';
import 'package:sender_app/user/user_info.dart';

class RequestPage extends StatefulWidget {
  RequestPage();
  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  TextEditingController rIdTxtCntrl = new TextEditingController();
  late TimeOfDay startTime = TimeOfDay.now();
  late TimeOfDay endTime = TimeOfDay.now();
  String status = "validation message will be displayed here";

  _RequestPageState();

  Future<void> _selectTime(BuildContext context, int startEndType) async {
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
        status = "Start time is less than end time";
      });
      return false;
    }
    if (minutes1 == minutes2) {
      setState(() {
        status = "plz choose start and end time";
      });

      return false;
    }
    // Calculate absolute difference in minutes
    int difference = (minutes1 - minutes2).abs();

    // Check if the difference is at least 30 minutes
    if (difference <= 5) {
      setState(() {
        status = '''Start time & end time differrence should be more than 
                  or equals to 5 minutes''';
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
                onPressed: () {
                  // TODO: Navigate to the notifications screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationPage(),
                      ));
                },
              ),
              IconButton(
                icon: Icon(Icons.location_history),
                onPressed: () {
                  // TODO: Navigate to the notifications screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SenderListPage(),
                      ));
                },
              ),
              IconButton(
                icon: Icon(Icons.stop_circle_outlined),
                onPressed: () async {
                  FlutterBackgroundService service = FlutterBackgroundService();
                  var status = await service.isRunning();
                  if (status) {
                    print("service is running stopping service");
                    service.invoke("stopService");

                    const Toast(
                      child: Text("service stopped"),
                    );
                    return;
                  }
                  print("service is not running");
                  const Toast(
                    child: Text("service is not running"),
                  );
                },
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Enter User ID'),
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
                  decoration:
                      const InputDecoration(labelText: 'Select Start Time'),
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
                  decoration: InputDecoration(labelText: 'Select End Time'),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!checkStartEndTime(startTime, endTime)) {
                  return;
                }

                // TODO: Handle the button press (send location request)
                print("send location pressed");
                //json for server

                final Map<String, String> data = {
                  "userId": UserInfo.userId,
                  "receiverId": rIdTxtCntrl.text,
                  "startTime": startTime.format(context),
                  "endTime": endTime.format(context),
                  "reqFlag": "true"
                };
                Client clnt = Client.getInstance();

                //creating notification
                clnt.post("sendNotification/", data).then((value) async {
                  print("response is ${value}");
                  await showTextToast(
                    text: value['message'],
                    context: context,
                  );
                });
              },
              child: Text('Send Location Request'),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.grey,
              child: Text(
                status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
