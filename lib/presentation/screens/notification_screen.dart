import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/local_firestore.dart';
import 'package:sender_app/domain/set_auto_connect.dart';

import 'package:sender_app/presentation/screens/request_screen.dart';
import 'package:sender_app/user/user_info.dart';

class NotificationPage extends StatefulWidget {
  NotificationPage();
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Future<List<NotificationItem>> getData() async {
    // Client clnt = Client.getInstance();
    late List<NotificationItem> notifications = [];
    final String userEmail = CurrentUser.user['userEmail'];
    print(" currentUser.user['usermail'] ${CurrentUser.user['userEmail']}");

    try {
      Map<String, dynamic>? map =
          await FirestoreOps.accessNotification(userEmail);
      if (map == null) {
        return notifications;
      }
      List<MyModel> modelList = map!.entries.map((entry) {
        return MyModel.fromJson(entry.key, entry.value);
      }).toList();

      // Print the list of models
      modelList.forEach((model) {
        print(model);
      });

      modelList.forEach((element) {
        notifications.add(NotificationItem(
            senderEmail: element.senderEmail,
            message: element.message,
            startTime: element.startTime,
            endTime: element.endTime,
            id: element.key,
            type: element.type));
      });

      return notifications;
    } catch (err) {
      Toast(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              0, 0, 0, DeviceInfo.getDeviceHeight(context) / 4),
          child: Text(err.toString()),
        ),
      );
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
        body: FutureBuilder<List<NotificationItem>>(
          future: getData(),
          builder: (BuildContext context,
              AsyncSnapshot<List<NotificationItem>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While data is loading, show a loading indicator or any other widget
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              // If an error occurs during data loading, show an error message
              return Center(
                child: Text("Error loading data: ${snapshot.error}"),
              );
            } else if (snapshot.data == null) {
              return Center(
                child: Text("No notifications"),
              );
            } else {
              // Data has been loaded successfully, display it
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  if (snapshot.data![index].type == "REQUEST") {
                    return NotificationCard(
                      id: snapshot.data![index].id,
                      message: snapshot.data![index].message,
                      startTime: snapshot.data![index].startTime,
                      endTime: snapshot.data![index].endTime,
                      senderEmail: snapshot.data![index].senderEmail,
                      context: context,
                    );
                  } else {
                    print(
                        '[print] message is ${snapshot.data![index].message}');
                    return SimpleNotification(
                      message: snapshot.data![index].message,
                      notId: snapshot.data![index].id,
                      userEmail: CurrentUser.user['userEmail'],
                      callback: () => this.setState(() {}),
                    );
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
  final String senderEmail;
  final String message;
  final String startTime;
  final String endTime;
  final BuildContext context;

  const NotificationCard(
      {required this.senderEmail,
      required this.message,
      required this.startTime,
      required this.id,
      required this.endTime,
      required this.context});

  approveRequest() async {
    await FirestoreOps.respondNotification({
      "userEmail": CurrentUser.user['userEmail'],
      "receiverEmail": senderEmail,
      "userResponse": "APPROVE",
      "requestNotificationId": id,
      "startTime": startTime,
      "endTime": endTime
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
        receiverEmail: this.senderEmail,
        services: ['LIVE_LOCATION']);

    Toast(
      child: Text("allowed for user ${this.senderEmail}"),
    );
  }

  rejectRequest() async {
    await FirestoreOps.respondNotification({
      "userEmail": CurrentUser.user['userEmail'],
      "receiverEmail": senderEmail,
      "userResponse": "DENY",
      "requestNotificationId": id,
      "startTime": startTime,
      "endTime": endTime
    });

    Toast(
      child: Text("Denied for user ${this.senderEmail}"),
    ).show(context);
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
            Text('From: ${this.senderEmail}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            Text('message: $message'),
            Text('location start time: $startTime'),
            Text('location end time: $endTime'),
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
  final String senderEmail;
  final String message;
  final String startTime;
  final String endTime;
  final String? type;

  NotificationItem(
      {required this.senderEmail,
      required this.message,
      required this.startTime,
      required this.endTime,
      required this.id,
      required this.type});
}

//for each notification received from server( { id:{ details... }, id:...} )
class MyModel {
  final String key;
  final String message;
  final String startTime;
  final String endTime;
  final String senderEmail;
  final String type;

  MyModel(
      {required this.key,
      required this.message,
      required this.startTime,
      required this.endTime,
      required this.senderEmail,
      required this.type});

  factory MyModel.fromJson(String key, Map<String, dynamic> map) {
    return MyModel(
      key: key,
      message: map['message'] ?? '',
      startTime: map['startTime'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      type: map['type'] ?? '',
      endTime: map['endTime'] ?? '',
    );
  }

  @override
  String toString() {
    return 'MyModel(key: $key, message: $message, ltime: $startTime $endTime, senderEmail: $senderEmail, req: $type)';
  }
}

class SimpleNotification extends StatelessWidget {
  final String message;
  final String notId;
  final String userEmail;
  final Function callback;

  const SimpleNotification(
      {required this.message,
      required this.notId,
      required this.userEmail,
      required this.callback});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "general",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      FirestoreOps.deleteNotification(notId, userEmail);
                      callback();
                    },
                    icon: Icon(Icons.delete))
              ],
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
