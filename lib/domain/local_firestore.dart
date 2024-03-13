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
      print("notId $notId");

      // Adding to document
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(receiverEmail)
          .set(
        {
          '$notId': {
            'message': message,
            'startTime': startTime,
            'endTime': endTime,
            'senderEmail': userEmail,
            'type': type,
            'services': services
          }
        },
        SetOptions(merge: true),
      );

      print('Data added to the document.');

      return 'SUCCESS'; // You can replace 'value' with the desired response.
    } catch (error) {
      print('Error adding data to document: $error');

      return error
          .toString(); // You can replace this message with the desired response.
    }
  }

  static Future<dynamic> accessNotification(String userEmail) async {
    String _userEmail = userEmail;
    try {
      print("userEmail is $_userEmail");
      DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userEmail)
          .get();
      Map<String, dynamic>? response =
          userDocSnapshot.data() as Map<String, dynamic>?;

      print(response);
      if (response == null) {
        print('no data in notifications');
      }

      // You can return the response if needed
      return response;
    } catch (error) {
      print('Error: $error');

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
      if (userResponse == 'APPROVE') {
        print("user allowed perm");

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

        print('Data added to the document.');
      } else {
        print("user denied perm");

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

        print('Data added to the document.');
      }
      await deleteNotification(requestNotificationId, userEmail);
      await _addSender(
          receiverEmail: receiverEmail,
          senderEmail: userEmail,
          eTime: endTime,
          sTime: startTime,
          services: services);
      return 'Data added to the document.';
    } catch (error) {
      print('Error: $error');
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

      print('Value added to the array successfully');
    } catch (e) {
      print('Error adding value to the array: $e');
      throw Exception(e);
    }
  }

  static notifyReceiver(
      {required String receiverEmail,
      required String userEmail,
      required bool connected,
      String? roomId}) async {
    print(
        '[FirestoreOps] notifyReceiver called, receiverEmail: $receiverEmail, userEmail: $userEmail, connected: $connected, roomId: $roomId');
    DebugFile.saveTextData(
        '[FirestoreOps] notifyReceiver called, receiverEmail: $receiverEmail, userEmail: $userEmail, connected: $connected, roomId: $roomId');
    print("[FirestoreOps] updating document");

    late Map<String, dynamic> data;

    try {
      if (connected && roomId != null) {
        data = {
          userEmail: {'connected': connected, 'roomId': roomId}
        };
      } else if (connected && roomId == null) {
        data = {
          userEmail: {
            'connected': connected,
          }
        };
      } else {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(receiverEmail)
            .update({
          userEmail: FieldValue.delete(),
        });
      }

      CollectionReference collectionReference =
          FirebaseFirestore.instance.collection('availableSenders');
      DocumentReference documentReference =
          collectionReference.doc(receiverEmail);
      documentReference.set(data, SetOptions(merge: true));
    } catch (e) {
      print('[FirestoreOps] error in notifyUser ${e.toString()}');
      DebugFile.saveTextData(
          '[FirestoreOps] error in notifyUser ${e.toString()}');
    }

    print("[print] document updated");
  }

  static getAvaialableSenders(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('availableSenders')
          .doc(email)
          .get();

      return doc.data();
    } catch (e) {
      print("[print] exception in availableSenders ${e.toString()}");
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
        throw Exception('user data not found');
      }
    } catch (e) {
      print("Error getting document: $e");
      return e.toString();
    }
  }
}
