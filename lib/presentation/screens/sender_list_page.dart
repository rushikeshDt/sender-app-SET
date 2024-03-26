import 'package:flutter/material.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/domain/local_firestore.dart';
import 'package:sender_app/presentation/choose_service.dart';

import 'package:sender_app/presentation/screens/location_page.dart';
import 'package:sender_app/user/user_info.dart';

class SenderListPage extends StatefulWidget {
  @override
  _SenderListPageState createState() => _SenderListPageState();
}

class _SenderListPageState extends State<SenderListPage> {
  String? error;

  @override
  void initState() {
    super.initState();
  }

  Future<List<SenderModel>?> fetchSenderList() async {
    try {
      Map<String, dynamic>? data = await FirestoreOps.getAvaialableSenders(
          CurrentUser.user['userEmail']);

      if (data == null) {
        return [];
      }
      List<SenderModel> modelList = data!.entries.map((e) {
        return SenderModel.fromMap(e.key, e.value);
      }).toList();
      DebugFile.saveTextData(
          '[SenderListPage.fetchSenderList] Successfully got senders ');
      return modelList;
    } catch (e) {
      DebugFile.saveTextData(
          '[SenderListPage.fetchSenderList] Error getting senders:${e.toString()} ');
    }
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
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {});
                },
                icon: Icon(Icons.restart_alt))
          ],
        ),
        body: error == null
            ? FutureBuilder<List<SenderModel>?>(
                future: fetchSenderList(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<SenderModel>?> snapshot) {
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
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    // If an error occurs during data loading, show an error message
                    return Center(
                      child: Text("No Senders"),
                    );
                  } else {
                    // Data has been loaded successfully, display it
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return SenderCard(
                          senderEmail: snapshot.data![index].sender,
                          eTime: snapshot.data![index].eTime,
                          sTime: snapshot.data![index].sTime,
                          connected: snapshot.data![index].connected,
                          services: snapshot.data![index].services,
                        );
                      },
                    ); // Replace "No data" with your desired default text
                  }
                })
            : Center(
                child: Text(error!),
              ));
  }
}

class SenderCard extends StatelessWidget {
  final String senderEmail;
  final String sTime;
  final String eTime;
  final bool connected;
  final List<String> services;

  SenderCard(
      {required this.senderEmail,
      required this.eTime,
      required this.sTime,
      required this.connected,
      required this.services});

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sender-email',
              style: TextStyle(color: Colors.green, fontSize: 18),
              softWrap: true,
            ),
            Text(senderEmail),
            Text(
              'Services',
              style: TextStyle(color: Colors.green, fontSize: 18),
              softWrap: true,
            ),
            Text(services.toString()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'start-time: $sTime',
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(
                  width: DeviceInfo.getDeviceWidth(context) / 8,
                ),
                Text(
                  'end-Time: $eTime',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            connected
                ? ElevatedButton(
                    onPressed: () {
                      // Navigate to the location page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServicePage(
                            senderEmail: senderEmail,
                            services: services,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'connect',
                      softWrap: true,
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {},
                    child: Text(
                      'Not available',
                      softWrap: true,
                    ),
                  ),
          ],
        ));
  }
}

class SenderModel {
  late String sender;
  late String sTime;
  late String eTime;
  late List<String> services;
  late bool connected;

  SenderModel(
      {required this.sender,
      required this.sTime,
      required this.eTime,
      required this.connected,
      required this.services});

  factory SenderModel.fromMap(String key, Map<String, dynamic> value) {
    DebugFile.saveTextData(
        '[sender_list.SenderModel] Got data for SenderModel key:$key value:$value');
    List<String> serv = [];
    List<dynamic> list = value['services'] ?? [];
    list.forEach(
      (element) {
        serv.add(element);
      },
    );
    return SenderModel(
        sender: key,
        sTime: value['startTime'], // Assuming 'sTime' is a Firestore Timestamp
        eTime: value['endTime'],
        connected: value['connected'],
        services: serv);
  }
}
