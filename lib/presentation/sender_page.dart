// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';

// import 'package:sender_app/configs/device_info.dart';
// import 'package:sender_app/domain/set_auto_connect.dart';

// import 'package:sender_app/presentation/receiver_page.dart';

// class SenderPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   TextEditingController textController1 = TextEditingController();
//   TextEditingController textController2 = TextEditingController();
//   String? senderId;
//   TimeOfDay? _startTime;
//   TimeOfDay? _endTime;
//   final DeviceInfo _deviceInfo = DeviceInfo;
//   String? serverIP;

//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null && picked != _startTime) {
//       setState(() {
//         _startTime = picked;
//       });
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null && picked != _endTime) {
//       setState(() {
//         _endTime = picked;
//       });
//     }
//   }

//   Container _responseTile() {
//     return Container(
//       decoration: const BoxDecoration(color: Colors.black45),
//       child: Column(
//         children: [
//           const Text('response from server'),
//           senderId != null
//               ? Text("senderId is $senderId")
//               // ? StreamBuilder(
//               //     stream: _sender.getStream(),
//               //     builder: (context, snapshot) {
//               //       if (snapshot.hasData) {
//               //         // Use the data from the stream to build your UI
//               //         return Center(
//               //           child: Text('${snapshot.data}'),
//               //         );
//               //       } else {
//               //         return const Center(
//               //           child: Text('No data yet'),
//               //         );
//               //       }
//               //     },
//               //   )
//               : const Text('please enter senderId to connect'),
//         ],
//       ),
//     );
//   }

//   // Container _senderIdInput() {
//   //   return Container(
//   //     height: _deviceInfo.getDeviceHeight(context) / 5,
//   //     width: _deviceInfo.getDeviceWidth(context),
//   //     child: Row(
//   //       children: [
//   //         ConstrainedBox(
//   //           constraints: BoxConstraints(
//   //             maxWidth: _deviceInfo.getDeviceWidth(context) /
//   //                 4, // set the maximum width
//   //           ),
//   //           child: T
//   //         ),
//   //         // SizedBox(width: _deviceInfo.getDeviceWidth(context) / 20),

//   //       ],
//   //     ),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             Text("Sender Page"),
//             IconButton(
//                 onPressed: () {
//                   Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute<void>(
//                           builder: (BuildContext context) => ReceiverPage()),
//                       (route) => false);
//                 },
//                 icon: const Icon(Icons.change_circle))
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: textController1,
//               decoration: InputDecoration(labelText: 'sender id'),
//             ),
//             const SizedBox(height: 10.0),
//             ElevatedButton(
//                 onPressed: () => _selectStartTime(context),
//                 child: Text(_startTime == null
//                     ? "select start time "
//                     : _startTime!.format(context).toString())),
//             const SizedBox(height: 10.0),
//             ElevatedButton(
//                 onPressed: () => _selectEndTime(context),
//                 child: Text(_endTime == null
//                     ? "select end time "
//                     : _endTime!.format(context).toString())),
//             const SizedBox(height: 10.0),
//             ElevatedButton(
//               style: ButtonStyle(),
//               onPressed: () {
//                 setState(() {
//                   senderId = textController1.text;
//                 });
//                 // Add your button functionality here
//                 print('Button Pressed');
//                 print('''senderId : ${textController1.text} 
//                     startTIme: ${_startTime!.format(context).toString()} 
//                     endTIme:${_endTime!.format(context).toString()} ''');
//                 if (senderId != null &&
//                     _startTime != null &&
//                     _endTime != null) {
//                   setAutoConnect(
//                     startTime: _startTime!,
//                     endTime: _endTime!,
//                     senderId: senderId!,
//                   );
//                 } else {
//                   if (senderId == null) {
//                     print("senderId has not been entered");
//                   }
//                   if (_startTime == null) {
//                     print("startTime has not been entered");
//                   }
//                   if (_endTime == null) {
//                     print("endTime has not been entered");
//                   }
//                 }
//               },
//               child: const Text('Click to set auto connect'),
//             ),
//             const SizedBox(height: 10.0),
//             _responseTile(),
//             const SizedBox(height: 10.0),
//             ElevatedButton(
//                 onPressed: () async {
//                   FlutterBackgroundService service = FlutterBackgroundService();
//                   await service.isRunning()
//                       ? service.invoke("stopService")
//                       : print("service already stopr");
//                 },
//                 child: Text("stop service"))
//           ],
//         ),
//       ),
//     );
//   }
// }


//                   }
//                 }
//               },
//               child: const Text('Click to set auto connect'),
//             ),
//             const SizedBox(height: 10.0),
//             _responseTile(),
//             const SizedBox(height: 10.0),
//             ElevatedButton(
//                 onPressed: () async {
//                   FlutterBackgroundService service = FlutterBackgroundService();
//                   await service.isRunning()
//                       ? service.invoke("stopService")
//                       : print("service already stopr");
//                 },
//                 child: Text("stop service"))
//           ],
//         ),
//       ),
//     );
//   }
// }