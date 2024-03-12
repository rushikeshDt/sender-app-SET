// import 'package:flutter/material.dart';
// import 'package:sender_app/network/send_request.dart';
// import 'package:sender_app/presentation/sender_page.dart';

// class ReceiverPage extends StatelessWidget {
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
//   TextEditingController textController3 = TextEditingController();
//   String? senderId;
//   String? receiverEmail;
//   String? serverIP;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             const Text("Receiver Page"),
//             IconButton(
//                 onPressed: () {
//                   Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute<void>(
//                           builder: (BuildContext context) => SenderPage()),
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
//               decoration: InputDecoration(labelText: 'receiver id'),
//             ),
//             SizedBox(height: 16.0),
//             TextField(
//               controller: textController2,
//               decoration: InputDecoration(labelText: 'sender id'),
//             ),
//             SizedBox(height: 24.0),
//             ElevatedButton(
//               onPressed: () {
//                 // Add your button functionality here
//                 print('Button Pressed');
//                 print('Input 1: ${textController1.text}');
//                 print('Input 2: ${textController2.text}');
//                 print("sending request....");
//                 setState(() {
//                   receiverEmail = textController1.text;
//                   senderId = textController2.text;
//                   serverIP = textController3.text;
//                 });
//               },
//               child: Text('Submit'),
//             ),
//             SizedBox(height: 24.0),
//             Container(
//               decoration: BoxDecoration(color: Colors.black45),
//               child: Column(
//                 children: [
//                   const Text('response from server'),
//                   (receiverEmail != null && senderId != null)
//                       ? StreamBuilder(
//                           stream: sendRequest(receiverEmail!, senderId!),
//                           builder: (context, snapshot) {
//                             if (snapshot.hasData) {
//                               // Use the data from the stream to build your UI
//                               return Center(
//                                 child: Text('Received data:  ${snapshot.data}'),
//                               );
//                             } else {
//                               return const Center(
//                                 child: Text('No data yet'),
//                               );
//                             }
//                           },
//                         )
//                       : const Text(
//                           'please enter receiverEmail & senderId to connect'),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
