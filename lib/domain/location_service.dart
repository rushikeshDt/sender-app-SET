import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sender_app/domain/debug_printer.dart';

class LocationService {
  static late String _userEmail;
  static late String _receiverEmail;

  static feedParameters({required String uEmail, required String rEmail}) {
    _userEmail = uEmail;
    _receiverEmail = rEmail;
  }

  static Future<void> sendReady() async {
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_receiverEmail)
          .collection(_userEmail)
          .doc('messages')
          .set({'reply': 'READY'});
      print('[locationService.sendReady] reply:READY sent');
      DebugFile.saveTextData('[locationService.sendReady] reply:READY sent');
    } catch (e) {
      print('[locationService.sendReady] error ${e.toString()}');
      DebugFile.saveTextData(
          '[locationService.sendReady] error ${e.toString()}');
    }
  }

  static Future<void> listenForRequest() async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(_receiverEmail)
        .collection(_userEmail)
        .doc('messages')
        .snapshots()
        .listen((snapshot) async {
      print('[LocationService.listen] got snapshot: ${snapshot.data()}');
      DebugFile.saveTextData(
          '[LocationService.listen] messages doc got snapshot: ${snapshot.data()}');
      if (snapshot.exists) {
        switch (snapshot.data()!['command']) {
          case 'SEND_ONE_TIME_LOCATION':
            await _sendLocation();
            break;
          //case for location stream soon.
          case '':
            break;
          default:
            break;
        }
      }
    });
  }

  static Future<void> _sendLocation() async {
    try {
      final time = DateTime.now().toLocal().toString();
      Position pos = await Geolocator.getCurrentPosition();
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_receiverEmail)
          .collection(_userEmail)
          .doc('liveLocation')
          .set({
        'location': {
          'lat': pos.latitude.toString(),
          'lang': pos.longitude.toString(),
          'time': time,
        },
      });

      print('[LocationService.sendLocation] location sent at time $time ');
      DebugFile.saveTextData(
          '[LocationService.sendLocation] location sent at time $time ');
      sendReady();
    } catch (e) {
      print('[LocationService.sendLocation] error sending location');
      DebugFile.saveTextData(
          '[LocationService.sendLocation] error sending location');
    }
  }
}
