import 'package:firebase_auth/firebase_auth.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/domain/local_firestore.dart';

class CurrentUser {
  static late Map user;

  static fetchUser(String userId) async {
    try {
      user = await FirestoreOps.getUserDetails(userId);
    } catch (e) {
      print("[CurrentUser.fetchUser] error fetching user ${e.toString()}");
      DebugFile.saveTextData(
          "[CurrentUser.fetchUser] error fetching user ${e.toString()}");
    }

    print('[CurrentUser.fetchUser] current user fetched $user');
    DebugFile.saveTextData(
        '[CurrentUser.fetchUser] current user fetched $user');
  }
}
