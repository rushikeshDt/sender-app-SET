// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sender_app/domain/debug_printer.dart';

// import 'video_stream_service.dart';

// class SessionControl {
//   static late String userEmail;
//   static late String receiverEmail;
//   static bool ready = false;

//   static feedParameters({required String uEmail, required String rEmail}) {
//     receiverEmail = rEmail;
//     userEmail = uEmail;
//     ready = true;
//   }

//   static listenForCommand() async {
//     FirebaseFirestore.instance
//         .collection('sessions')
//         .doc(receiverEmail)
//         .collection(userEmail)
//         .doc('messages')
//         .snapshots()
//         .listen((snapshot) async {
//       if (!snapshot.exists) return;
//       Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//       if (data['command'] == 'CREATE_ROOM') {
//         print(
//             '[SessionControl.listenForCommand] CREATE_ROOM command from sender.');
//         DebugFile.saveTextData(
//             '[SessionControl.listenForCommand] CREATE_ROOM command from sender.');
//         VSSController.feedParams(
//             rEmail: receiverEmail, uEmail: userEmail, ops: data['options']);
//         final msg = await VSSController.createRoom();
//         print('msg obtained from VSSController.createRoom $msg');
//         if (msg == 'ROOM_CREATED') {
//           await sendMessage(
//             title: 'reply',
//             message: 'ROOM_CREATED',
//           );
//         }
//       } else if (data['command'] == 'HANG_UP') {
//         print('[SessionControl.listenForCommand] HANG_UP from sender.');
//         DebugFile.saveTextData(
//             '[SessionControl.listenForCommand] HANG_UP from sender.');

//         await hangUp();

//         // await FirebaseFirestore.instance
//         //     .collection('sessions')
//         //     .doc(receiverEmail)
//         //     .collection(userEmail)
//         //     .doc('messages')
//         //     .set({'reply': 'HUNG_UP'});
//       }
//     });
//   }

//   static Future<void> hangUp() async {
//     if (VSSController.isActive) {
//       final msg = await VSSController.hangUp();
//       print('msg obtained from VSSController.hangUp $msg');

//       if (msg == 'HUNG_UP') {
//         await sendMessage(
//           title: 'reply',
//           message: 'HUNG_UP',
//         );
//       }
//     }
//   }

//   static Future<void> deleteSession() async {
//     if (!ready) {
//       throw '[SessionControl.deleteSession] feedParameters not called. no parameters';
//     }

//     // Get a reference to the collection
//     CollectionReference collectionRef = FirebaseFirestore.instance
//         .collection('sessions')
//         .doc(receiverEmail)
//         .collection(userEmail);

//     // Get all documents in the collection
//     QuerySnapshot querySnapshot = await collectionRef.get();

//     // Create a batch
//     WriteBatch batch = FirebaseFirestore.instance.batch();

//     // Add all delete operations to the batch
//     querySnapshot.docs.forEach((doc) {
//       batch.delete(doc.reference);
//     });

//     // Commit the batch
//     await batch.commit();
//     DebugFile.saveTextData(
//         '[fl_background_services.deleteSession] Session deleted for $userEmail');
//   }

//   static Future<void> sendMessage({
//     required String title,
//     required String message,
//   }) async {
//     if (!ready) {
//       throw '[SessionControl.sendMessage] feedParameters not called. no parameters';
//     }
//     await FirebaseFirestore.instance
//         .collection('sessions')
//         .doc(receiverEmail)
//         .collection(userEmail)
//         .doc('messages')
//         .set({title: message});
//     print('[SessionControl.sendMessage] Message sent $title:$message');
//     DebugFile.saveTextData(
//         '[SessionControl.sendMessage] Message sent $title:$message');
//   }

//   static Future<void> notifyReceiver({
//     required bool connected,
//   }) async {
//     if (!ready) {
//       throw '[SessionControl.notifyReceiver] feedParameters not called. no parameters';
//     }
//     print(
//         '[SessionControl.notifyReceiver] notifyReceiver called, receiverEmail: $receiverEmail, userEmail: $userEmail, connected: $connected,');
//     DebugFile.saveTextData(
//         '[SessionControl.notifyReceiver] notifyReceiver called, receiverEmail: $receiverEmail, userEmail: $userEmail, connected: $connected ');
//     print("[FirestoreOps] updating document");

//     late Map<String, dynamic> data;
//     CollectionReference collectionReference =
//         FirebaseFirestore.instance.collection('availableSenders');
//     DocumentReference documentReference =
//         collectionReference.doc(receiverEmail);
//     final doc = await documentReference.get();
//     print('doc in notify sender ${doc.data()}');
//     try {
//       print('[SessionControl.notifyReceiver] got document');
//       data = {
//         userEmail: {
//           'connected': connected,
//         }
//       };

//       await documentReference.set(data, SetOptions(merge: true));
//     } catch (e) {
//       print(
//           '[SessionControl.notifyReceiver] error in notifyReceiver ${e.toString()}');
//       DebugFile.saveTextData(
//           '[SessionControl.notifyReceiver] error in notifyReceiver ${e.toString()}');
//     }
//   }
// }
