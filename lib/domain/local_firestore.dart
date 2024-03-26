import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/user/user_info.dart';

class FirestoreOps {
  static Future<dynamic> sendNotification(Map notification) async {
    String userEmail = notification["userEmail"];
    String receiverEmail = notification["receiverEmail"];
    String startTime = notification["startTime"];
    String endTime = notification["endTime"];
    String type = notification["type"];
    String message =
        '${userEmail} has requested your location between time ${startTime} and ${endTime}';
    List<String> services = notification["services"];

    try {
      Random random = Random();
      int notId = random.nextInt(100);
      print("[LocalFirestore.sendNotification] notId $notId");
      DebugFile.saveTextData("[LocalFirestore.sendNotification] notId $notId");

      // Adding to document
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(receiverEmail)
          .set(
        {
          '$notId': {
            'senderEmail': userEmail,
            'type': type,
            'message': message,
            'startTime': startTime,
            'endTime': endTime,
            'services': services
          }
        },
        SetOptions(merge: true),
      );

      return 'SUCCESS'; // You can replace 'value' with the desired response.
    } catch (error) {
      print(
          '[LocalFirestore.sendNotification] Error adding data to document: $error');
      DebugFile.saveTextData(
          '[LocalFirestore.sendNotification] Error adding data to document: $error');

      return error
          .toString(); // You can replace this message with the desired response.
    }
  }

  static Future<dynamic> accessNotification(String userEmail) async {
    String _userEmail = userEmail;
    try {
      print("[LocalFirestore.accessNotification] userEmail is $_userEmail");
      DebugFile.saveTextData(
          "[LocalFirestore.accessNotification] userEmail is $_userEmail");
      DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userEmail)
          .get();
      Map<String, dynamic>? response =
          userDocSnapshot.data() as Map<String, dynamic>?;

      print(response);
      if (response == null) {
        print('[LocalFirestore.accessNotification] no data for notifications');
        DebugFile.saveTextData(
            '[LocalFirestore.accessNotification] no data for notifications');
      }

      // You can return the response if needed
      return response;
    } catch (error) {
      print('[LocalFirestore.accessNotification] Error: $error');
      DebugFile.saveTextData(
          '[LocalFirestore.accessNotification] Error: $error');

      // You can return an error message if needed
      return error.toString();
    }
  }

  static Future<String> respondNotification(Map _data) async {
    try {
      String userEmail = _data['userEmail']!;
      String receiverEmail = _data['receiverEmail'];
      String userResponse = _data['userResponse'];
      String requestNotificationId = _data["requestNotificationId"];
      String startTime = _data["startTime"];
      String endTime = _data["endTime"];
      List<String> services = _data['services'];
      print("[LocalFirestore.respondNotification] responding for: $_data");
      DebugFile.saveTextData(
          "[LocalFirestore.respondNotification] responding for: $_data");
      if (userResponse == 'APPROVE') {
        // Update Firestore for approval
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(receiverEmail)
            .set(
          {
            requestNotificationId: {
              'message': '$userEmail has accepted your request for $services',
              'type': 'general',
            },
          },
          SetOptions(merge: true),
        );
        await _addSender(
            receiverEmail: receiverEmail,
            senderEmail: userEmail,
            eTime: endTime,
            sTime: startTime,
            services: services);
      } else {
        // Update Firestore for denial
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(receiverEmail)
            .set(
          {
            requestNotificationId: {
              'message': '$userEmail has denied your request for $services'
            },
          },
          SetOptions(merge: true),
        );
      }
      await deleteNotification(requestNotificationId, userEmail);

      return 'Data added to the document.';
    } catch (error) {
      print('[LocalFirestore.respondNotification] Error: ${error.toString()}');
      DebugFile.saveTextData(
          '[LocalFirestore.respondNotification] Error: ${error.toString()}');

      return error.toString();
    }
  }

  static deleteNotification(String id, String userMail) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userMail)
        .update({
      id: FieldValue.delete(),
    });
  }

  static _addSender(
      {required String receiverEmail,
      required String senderEmail,
      required String sTime,
      required String eTime,
      required List<String> services}) async {
    try {
      // Reference to the collection and document
      CollectionReference collectionReference =
          FirebaseFirestore.instance.collection('availableSenders');
      DocumentReference documentReference =
          collectionReference.doc(receiverEmail);

      documentReference.set({
        senderEmail: {
          'startTime': sTime,
          'endTime': eTime,
          'services': services,
          'connected': false,
        }
      }, SetOptions(merge: true));

      print('[LocaFirestore._addSender] Value added to the array successfully');
      DebugFile.saveTextData(
          '[LocaFirestore._addSender] Value added to the array successfully');
    } catch (e) {
      print(
          '[LocalFirestore._addSender] Error adding value to the array: ${e.toString()}');
      DebugFile.saveTextData(
          '[LocalFirestore._addSender] Error adding value to the array: ${e.toString()}');
      throw Exception(e);
    }
  }

  static getAvaialableSenders(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('availableSenders')
          .doc(email)
          .get();

      return doc.data();
    } catch (e) {
      print("[LocalFirestore.getAvailableSenders] Error ${e.toString()}");
      DebugFile.saveTextData(
          "[LocalFirestore.getAvailableSenders] Error ${e.toString()}");
      return null;
    }
  }

  static Future<dynamic> getUserDetails(String uid) async {
    try {
      // Get the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Reference to the collection
      CollectionReference collectionReference = firestore.collection('users');

      // Get the document snapshot
      DocumentSnapshot documentSnapshot =
          await collectionReference.doc(uid).get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        return documentSnapshot.data();
      } else {
        print("[LocalFirestore.getAvailableSenders] NoData");
        DebugFile.saveTextData("[LocalFirestore.getAvailableSenders] NoData");
        throw Exception('user data not found');
      }
    } catch (e) {
      print(
          "[LocalFirestore.getAvailableSenders] Error getting document: ${e.toString()}");
      DebugFile.saveTextData(
          "[LocalFirestore.getAvailableSenders] Error getting document: ${e.toString()}");
      return e.toString();
    }
  }
}
