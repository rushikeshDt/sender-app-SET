import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:sender_app/domain/set_auto_connect.dart';
import 'package:sender_app/network/client.dart';
import 'package:sender_app/presentation/screens/request_screen.dart';
import 'package:sender_app/user/user_info.dart';

class NotificationPage extends StatefulWidget {
  NotificationPage();
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Future<List<NotificationItem>?> getData() async {
    Client clnt = Client.getInstance();
    late List<NotificationItem>? notifications = [];

    try {
      Map<String, dynamic> jsonMap =
          await clnt.post("accessNotifications/", {"userId": UserInfo.userId});

      List<MyModel> modelList = jsonMap.entries.map((entry) {
        return MyModel.fromJson(entry.key, entry.value);
      }).toList();

      // Print the list of models
      modelList.forEach((model) {
        print(model);
      });

      modelList.forEach((element) {
        notifications.add(NotificationItem(
            senderId: element.senderId,
            message: element.message,
            startTime: element.startTime,
            endTime: element.endTime,
            id: element.key,
            reqFlag: element.reqFlag));
      });
      return notifications!;
    } catch (err) {
      return Future.error(err);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                // Refresh the screen by rebuilding it
                setState(() {});
              },
            ),
          ],
        ),
        body: FutureBuilder<List<NotificationItem>?>(
          future: getData(),
          builder: (BuildContext context,
              AsyncSnapshot<List<NotificationItem>?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While data is loading, show a loading indicator or any other widget
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // If an error occurs during data loading, show an error message
              return Text("Error loading data: ${snapshot.error}");
            } else {
              // Data has been loaded successfully, display it
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  if (snapshot.data![index].reqFlag == "true") {
                    return NotificationCard(
                      id: snapshot.data![index].id,
                      message: snapshot.data![index].message,
                      startTime: snapshot.data![index].startTime,
                      endTime: snapshot.data![index].endTime,
                      senderId: snapshot.data![index].senderId,
                      context: context,
                    );
                  } else {
                    return SimpleNotification(
                        msg: snapshot.data![index].message);
                  }
                },
              ); // Replace "No data" with your desired default text
            }
          },
        ));
  }
}

class NotificationCard extends StatelessWidget {
  final String id;
  final String senderId;
  final String message;
  final String startTime;
  final String endTime;
  final BuildContext context;

  const NotificationCard(
      {required this.senderId,
      required this.message,
      required this.startTime,
      required this.id,
      required this.endTime,
      required this.context});

  approveRequest() {
    // Handle "Approve" button press
    Client clnt = Client.getInstance();
    clnt.post("notificationResponse/", {
      "userId": UserInfo.userId,
      "notification": {
        this.id: {
          "message": this.message,
          "startTime": this.startTime,
          "endTime": this.endTime,
          "senderId": this.senderId
        }
      },
      "userResponse": "APPROVE"
    });
    DateTime sdt = DateFormat("h:mm a").parse(startTime);
    DateTime edt = DateFormat("h:mm a").parse(endTime);
    print('sdt and edt is $sdt $edt');
    var newEndTime = TimeOfDay.fromDateTime(edt);
    var newStartTime = TimeOfDay.fromDateTime(sdt);
    print("newEndTime is ${newEndTime} newStartTime is ${newStartTime}");
    setAutoConnect(
        endTime: newEndTime,
        startTime: newStartTime,
        receiverId: this.senderId);

    Toast(
      child: Text("allowed for user ${this.senderId}"),
    );
  }

  rejectRequest() {
    // Handle "Reject" button press
    Client clnt = Client.getInstance();
    clnt.post("notificationResponse/", {
      "userId": UserInfo.userId,
      "notification": {
        this.id: {
          "message": this.message,
          "startTime": this.startTime,
          "endTime": this.endTime,
          "senderId": this.senderId
        }
      },
      "userResponse": "DENY"
    });

    Toast(
      child: Text("Denied for user ${this.senderId}"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${this.senderId}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            Text('msg: $message'),
            Text('location start time: $startTime'),
            Text('location end time: $endTime'),
            Text('request id: $id'),
            SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      approveRequest();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RequestPage()));
                    },
                    child: const Text('Approve'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      rejectRequest();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RequestPage()));
                    },
                    child: const Text('Reject'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String senderId;
  final String message;
  final String startTime;
  final String endTime;
  final String? reqFlag;

  NotificationItem(
      {required this.senderId,
      required this.message,
      required this.startTime,
      required this.endTime,
      required this.id,
      required this.reqFlag});
}

//for each notification received from server( { id:{ details... }, id:...} )
class MyModel {
  final String key;
  final String message;
  final String startTime;
  final String endTime;
  final String senderId;
  final String reqFlag;

  MyModel(
      {required this.key,
      required this.message,
      required this.startTime,
      required this.endTime,
      required this.senderId,
      required this.reqFlag});

  factory MyModel.fromJson(String key, Map<String, dynamic> json) {
    return MyModel(
      key: key,
      message: json['message'] ?? '',
      startTime: json['startTime'] ?? '',
      senderId: json['senderId'] ?? '',
      reqFlag: json['reqFlag'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  @override
  String toString() {
    return 'MyModel(key: $key, msg: $message, ltime: $startTime $endTime, senderId: $senderId, req: $reqFlag)';
  }
}

class SimpleNotification extends StatelessWidget {
  final String msg;

  const SimpleNotification({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "general",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              msg,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
