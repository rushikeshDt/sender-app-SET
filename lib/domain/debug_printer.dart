import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';

class DebugFile {
  // Define a folder name and file name for your text data
  static const String folderName = 'sender_app';
  static const String fileName = 'debug_file.txt';
  static late String path;
  static File? file;

  // Method to create the folder if it doesn't exist
  static Future<void> createFile() async {
    print('[DebugFile.createFile] Creating debug file');
    final directory = await getApplicationDocumentsDirectory();
    final internalStoragePath = directory.path;
    final folderPath = '$internalStoragePath/$folderName';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);

      print('[DebugFile] Folder for debug file created');
    } else {
      print('[DebugFile] Folder exist. not creating.');
    }

    path = '$folderPath/$fileName';
    file = File(path);
    print('[DebugFile] File path is $path.');
  }

  // Method to save text data to the file
  static Future<void> saveTextData(String data) async {
    if (file != null) {
      await file!.writeAsString(data + "\n", mode: FileMode.append);
    } else {
      print('[DebugFile] File does not exist, creating and saving to file.');
      await createFile();
      await file!.writeAsString(data + "\n", mode: FileMode.append);
    }
  }

  // Method to retrieve text data from the file
  static Future<String> loadTextData() async {
    try {
      final file = File(path);
      // Read the file
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      // Return an empty string if an error occurs (e.g., file not found)
      print("[DebugFile] ${e.toString()}");
      throw e;
    }
  }
}
