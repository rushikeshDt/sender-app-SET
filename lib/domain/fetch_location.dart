import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/user/user_info.dart';

class FetchLocation {
  // late final DocumentSnapshot senderMessagesDocument;
  late StreamController<Map<String, dynamic>> _myStreamController;
  late Stream<Map<String, dynamic>> _locationStream;
  late StreamSubscription subscription;
  late String senderEmail;
  late String userEmail;
  static FetchLocation? _instance;
  static FetchLocation getInstance({required String senderEmail}) {
    _instance ??= FetchLocation();
    _instance!.userEmail = CurrentUser.user['userEmail'];
    _instance!.senderEmail = senderEmail;

    return _instance!;
  }

  closeLocationStream() async {
    await subscription.cancel();
    await _myStreamController.close();
  }

  openLocationStream() {
    _myStreamController = StreamController<Map<String, dynamic>>();

    _locationStream = _myStreamController.stream;
  }

  Stream<Map<String, dynamic>> get locationStream => _locationStream;

  // getMessageChannel() async {
  //   try {
  //     senderMessagesDocument = await FirebaseFirestore.instance
  //         .collection('sessions')
  //         .doc(userEmail)
  //         .collection(senderEmail)
  //         .doc('messages')
  //         .get();
  //     print('[FetchLocation.getsessions] Got senderMessagesDocument');
  //     DebugFile.saveTextData(
  //         '[FetchLocation.getsessions] Got senderMessagesDocument');
  //   } catch (e) {
  //     print(
  //         '[FetchLocation.getsessions] Error getting senderMessagesDocument: ${e.toString()}');
  //     DebugFile.saveTextData(
  //         '[FetchLocation.getsessions] Error getting senderMessagesDocument: ${e.toString()}');
  //   }
  // }

  sendLocationRequest() async {
    if (!_myStreamController.isClosed) {
      _myStreamController.add({
        'STATUS': 'SENDING_REQUEST',
      });
    }

    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(userEmail)
          .collection(senderEmail)
          .doc('messages')
          .set({'command': 'SEND_ONE_TIME_LOCATION'});
      print('[FetchLocation.sendLocationRequest] Request sent');
      DebugFile.saveTextData(
          '[FetchLocation.sendLocationRequest] Request sent');

      subscription = FirebaseFirestore.instance
          .collection('sessions')
          .doc(userEmail)
          .collection(senderEmail)
          .doc('liveLocation')
          .snapshots()
          .listen((snapshot) {
        print(
            '[fetchLocation.sendLocationRequest] Got response ${snapshot.data()}');
        DebugFile.saveTextData(
            '[fetchLocation.sendLocationRequest] Got response ${snapshot.data()}');
        if (snapshot.exists) {
          if (!_myStreamController.isClosed) {
            _myStreamController.add({
              'STATUS': 'SENDER_ONE_TIME_LOCATION',
              'LOCATION': snapshot.data()!['location']
            });
          }
        } else {
          print('[FetchLocation.sendLocationRequest] snapshot does not exist');
          DebugFile.saveTextData(
              '[FetchLocation.sendLocationRequest] snapshot does not exist');
          if (!_myStreamController.isClosed) {
            _myStreamController
                .add({'ERROR': "getting location(waiting for sender to send)"});
          }
        }
      });
    } catch (e) {
      print(
          '[FetchLocation.sendLocationRequest] Error sending request: ${e.toString()}');
      DebugFile.saveTextData(
          '[FetchLocation.sendLocationRequest] Error sending request: ${e.toString()}');
      if (!_myStreamController.isClosed) {
        _myStreamController
            .add({'ERROR': "Error sending request: ${e.toString()}"});
      }
    }
  }
}
