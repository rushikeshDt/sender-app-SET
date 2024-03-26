// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sender_app/domain/debug_printer.dart';

// class VideoRecorder {
//   static late List<CameraDescription> _cameras;
//   static late CameraDescription _camera;
//   static late CameraController _controller;

//   static String? videoPath;
//   static XFile? file;

//   static Future<void> init() async {
//     try {
//       print('[VideoRecorder] strting init');
//       _cameras = await availableCameras();
//       _camera = _cameras.first;
//       print('[VideoRecorder] ${_camera.name}');
//       // _camera = CameraDescription(
//       //     name: 'FRONT_CAM',
//       //     lensDirection: CameraLensDirection.front,
//       //     sensorOrientation: 0);
//       _controller = CameraController(_camera, ResolutionPreset.low);
//       _controller.initialize();
//       _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
//       print('[VideoRecorder] init finished');
//     } catch (e) {
//       DebugFile.saveTextData('[VideoRecorder.init] Error ${e.toString()}');
//     }

//     // appDirectory = await getApplicationDocumentsDirectory();
//     // videoPath =
//     //     '${appDirectory.path}/samples/video.mp4'; //must overwrite this file if already exist
//   }

//   static Future<XFile?> getSample() async {
//     await _startVideoRecording();
//     await Future.delayed(Duration(seconds: 10));
//     await _stopVideoRecording();
//     if (file == null) {
//       print('[VideoRecorder.getSample] No file obtained!');
//       DebugFile.saveTextData('[VideoRecorder.getSample] No file obtained!');
//       return null;
//     }
//     return file;
//   }

//   static Future<void> _startVideoRecording() async {
//     if (!_controller.value.isInitialized) {
//       return;
//     }

//     try {
//       if (!_controller.value.isRecordingVideo) {
//         print('[VideoRecorder.startVideoRecording] Starting recording');
//         DebugFile.saveTextData(
//             '[VideoRecorder.startVideoRecording] Starting recording');
//         await _controller.startVideoRecording();
//       } else {
//         throw '[VideoRecorder.startVideoRecording] already recording cannot start another recording';
//       }
//     } catch (e) {
//       print(e);
//     }
//   }

//   static Future<void> _stopVideoRecording() async {
//     if (!_controller.value.isRecordingVideo) {
//       throw '[VideoRecorder.startVideoRecording] No ongoing recording to stop';
//     }

//     try {
//       print('[VideoRecorder.startVideoRecording] Stoppping recording');
//       DebugFile.saveTextData(
//           '[VideoRecorder.startVideoRecording] Stoppping recording');
//       file = await _controller.stopVideoRecording();
//       videoPath = file!.path;
//       print(
//           '[VideoRecorder.startVideoRecording] Recording stopped file at $videoPath');
//       DebugFile.saveTextData(
//           '[VideoRecorder.startVideoRecording] Recording stopped file at $videoPath');
//     } catch (e) {
//       print(e);
//     }
//   }
// }
