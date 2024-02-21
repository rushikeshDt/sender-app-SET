import 'package:flutter/material.dart';
import 'package:sender_app/network/send_request.dart';
import 'package:sender_app/user/user_info.dart';

class LocationPage extends StatefulWidget {
  String senderId;
  LocationPage({super.key, required this.senderId});

  @override
  State<LocationPage> createState() =>
      _LocationPageState(senderId: this.senderId);
}

class _LocationPageState extends State<LocationPage> {
  final String senderId;
  RequestWebSocket rws = RequestWebSocket.getInstance();

  _LocationPageState({required this.senderId});

  @override
  Widget build(BuildContext context) {
    // Replace this with the actual implementation for fetching and displaying location
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Page'),
      ),
      body: StreamBuilder(
        stream: rws.sendRequest(UserInfo.userId, senderId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Use the data from the stream to build your UI
            return Center(
              child: Text('Received data:  ${snapshot.data}'),
            );
          } else {
            return const Center(
              child: Text('No data yet'),
            );
          }
        },
      ),
    );
  }
}
