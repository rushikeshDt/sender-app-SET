import 'package:flutter/material.dart';
import 'package:sender_app/network/client.dart';
import 'package:sender_app/network/send_request.dart';
import 'package:sender_app/presentation/screens/location_page.dart';
import 'package:sender_app/user/user_info.dart';

class SenderListPage extends StatefulWidget {
  @override
  _SenderListPageState createState() => _SenderListPageState();
}

class _SenderListPageState extends State<SenderListPage> {
  List<String> senderList = [];
  String? error;

  @override
  void initState() {
    super.initState();
    fetchSenderList();
  }

  Future<void> fetchSenderList() async {
    dynamic data = await Client.getInstance()
        .post("availableSenders/", {"userId": UserInfo.userId});

    setState(() {
      if (data['senders'] != 0) {
        senderList = List<String>.from(data['senders']);
      } else {
        setState(() {
          error = "no senders available";
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sender List'),
        ),
        body: error == null
            ? ListView.builder(
                itemCount: senderList.length,
                itemBuilder: (context, index) {
                  return SenderCard(senderId: senderList[index]);
                },
              )
            : Text(error!));
  }
}

class SenderCard extends StatelessWidget {
  final String senderId;

  SenderCard({required this.senderId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text('Sender Name: $senderId'),
        trailing: ElevatedButton(
          onPressed: () {
            // Navigate to the location page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPage(senderId: senderId),
              ),
            );
          },
          child: Text('Fetch Location'),
        ),
      ),
    );
  }
}
