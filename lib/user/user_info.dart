import 'package:firebase_auth/firebase_auth.dart';
import 'package:sender_app/domain/local_firestore.dart';

class CurrentUser {
  static late Map user;

  static fetchUser(String userId) async {
    try {
      user = await FirestoreOps.getUserDetails(userId);
    } catch (e) {
      print("[print] error fetching user ${e.toString()}");
    }

    print('[print]current user fetched $user');
  }
}
