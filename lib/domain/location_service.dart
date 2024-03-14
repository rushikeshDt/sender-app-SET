// class LocationService {
//   static late String userEmail;
//   static late String receiverEmail;
//   static feedParameters({required String uEmail, required String rEmail}) {
//     userEmail = uEmail;
//     receiverEmail = rEmail;
//   }

//   static Future<void> sendReady() async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('sessions')
//           .doc(receiverEmail)
//           .collection(userEmail)
//           .doc('messages')
//           .set({'reply': 'READY'});
//       print('[locationService.sendReady] reply:READY sent');
//       DebugFile.saveTextData('[locationService.sendReady] reply:READY sent');
//     } catch (e) {
//       print('[locationService.sendReady] error ${e.toString()}');
//       DebugFile.saveTextData(
//           '[locationService.sendReady] error ${e.toString()}');
//     }
//   }

//   static Future<void> listenForRequest() async {
//     await FirebaseFirestore.instance
//         .collection('sessions')
//         .doc(receiverEmail)
//         .collection(userEmail)
//         .doc('messages')
//         .snapshots()
//         .listen((snapshot) async {
//       print('[LocationService.listen] got snapshot: ${snapshot.data()}');
//       DebugFile.saveTextData(
//           '[LocationService.listen] got snapshot: ${snapshot.data()}');
//       if (snapshot.exists) {
//         switch (snapshot.data()!['command']) {
//           case 'SEND_ONE_TIME_LOCATION':
//             await sendLocation();
//             break;
//           //case for location stream soon.
//           case '':
//             break;
//           default:
//             break;
//         }
//       }
//     });
//   }

//   static Future<void> sendLocation() async {
//     try {
//       final time = DateTime.now().toLocal().toString();
//       Position pos = await Geolocator.getCurrentPosition();
//       await FirebaseFirestore.instance
//           .collection('sessions')
//           .doc(receiverEmail)
//           .collection(userEmail)
//           .doc('liveLocation')
//           .set({
//         'location': {
//           'lat': pos.latitude.toString(),
//           'lang': pos.longitude.toString(),
//           'time': time,
//         },
        
//       });

//       print('[LocationService.sendLocation] location sent at time $time ');
//       DebugFile.saveTextData(
//           '[LocationService.sendLocation] location sent at time $time ');
//     } catch (e) {
//       print('[LocationService.sendLocation] error sending location');
//       DebugFile.saveTextData(
//           '[LocationService.sendLocation] error sending location');
//     }
//   }
// }
