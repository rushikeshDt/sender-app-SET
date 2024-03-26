import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sender_app/user/user_info.dart';

Future<void> uploadTextFile(File file) async {
  String currentUser = CurrentUser.user['userEmail'];
  try {
    String fileName =
        '${currentUser}_debug_info.txt'; // Change this to your desired file name
    Reference storageReference = FirebaseStorage.instance.ref().child(fileName);

    // Upload the file to Firebase Cloud Storage
    UploadTask uploadTask = storageReference.putFile(file);

    // Get the download URL once the upload is complete
    String downloadURL = await (await uploadTask).ref.getDownloadURL();
    print(
        '[uploadTextFile] File uploaded successfully. Download URL: $downloadURL');
  } catch (error) {
    print('[uploadTextFile] Error uploading file: $error');
  }
}
