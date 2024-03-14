// class FetchLocation {
//   // late final DocumentSnapshot senderMessagesDocument;
//   late StreamController<Map<String, dynamic>> _myStreamController;
//   late Stream<Map<String, dynamic>> _locationStream;

//   late String senderEmail;
//   late String userEmail;
//   static late FetchLocation? _instance;
//   static getInstance({required String senderEmail}) {
//     _instance ??= FetchLocation();
//     _instance!.userEmail = CurrentUser.user['userEmail'];
//     _instance!.senderEmail = senderEmail;

//     return _instance;
//   }

//   closeLocationStream() {
//     _myStreamController.close();
//   }

//   openLocationStream() {
//     _myStreamController = StreamController<Map<String, dynamic>>();
//     _locationStream = _myStreamController.stream;
//   }

//   Stream<Map<String, dynamic>> get locationStream => _locationStream;

//   // getMessageChannel() async {
//   //   try {
//   //     senderMessagesDocument = await FirebaseFirestore.instance
//   //         .collection('session')
//   //         .doc(userEmail)
//   //         .collection(senderEmail)
//   //         .doc('messages')
//   //         .get();
//   //     print('[FetchLocation.getSession] Got senderMessagesDocument');
//   //     DebugFile.saveTextData(
//   //         '[FetchLocation.getSession] Got senderMessagesDocument');
//   //   } catch (e) {
//   //     print(
//   //         '[FetchLocation.getSession] Error getting senderMessagesDocument: ${e.toString()}');
//   //     DebugFile.saveTextData(
//   //         '[FetchLocation.getSession] Error getting senderMessagesDocument: ${e.toString()}');
//   //   }
//   // }

//   sendLocationRequest() async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('session')
//           .doc(userEmail)
//           .collection(senderEmail)
//           .doc('messages')
//           .set({'command': 'SEND_ONE_TIME_LOCATION'});
//       print('[FetchLocation.sendLocationRequest] Request sent');
//       DebugFile.saveTextData(
//           '[FetchLocation.sendLocationRequest] Request sent');

//       await FirebaseFirestore.instance
//           .collection('session')
//           .doc(userEmail)
//           .collection(senderEmail)
//           .doc('LiveLocation')
//           .snapshots()
//           .listen((snapshot) {
//         print(
//             '[fetchLocation.sendLocationRequest] Got response ${snapshot.data()}');
//         DebugFile.saveTextData(
//             '[fetchLocation.sendLocationRequest] Got response ${snapshot.data()}');
//         if (snapshot.exists) {
//           _myStreamController.add({'STATUS':'SENDER_ONE_TIME_LOCATION','LOCATION':snapshot.data()!['location']});
//         } else {
//           print('[FetchLocation.sendLocationRequest] snapshot does not exist');
//           DebugFile.saveTextData(
//               '[FetchLocation.sendLocationRequest] snapshot does not exist');
//           _myStreamController.add({'ERROR': "snapshot does not exist"});
//         }
//       });
//     } catch (e) {
//       print(
//           '[FetchLocation.sendLocationRequest] Error sending request: ${e.toString()}');
//       DebugFile.saveTextData(
//           '[FetchLocation.sendLocationRequest] Error sending request: ${e.toString()}');
//       _myStreamController
//           .add({'ERROR': "Error sending request: ${e.toString()}"});
//     }
//   }
// }