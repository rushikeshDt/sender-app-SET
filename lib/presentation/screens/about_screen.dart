import 'package:flutter/material.dart';
import 'package:sender_app/configs/device_info.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/utils/upload_file_to_cloud.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _isLoading = false;
  String? _message;
  String? fileData;
  @override
  void initState() {
    // TODO: implement initState
    getFileContent();
    super.initState();
  }

  getFileContent() async {
    DebugFile.loadTextData().then((value) {
      setState(() {
        fileData = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About My App'),
      ),
      body: Center(
          child: Column(
        children: [
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      if (DebugFile.file != null)
                        await uploadTextFile(DebugFile.file!);
                      setState(() {
                        _message = 'Successfull ';
                      });
                    } catch (e) {
                      setState(() {
                        _message = 'Error ${e.toString()} ';
                      });
                    }

                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: Text('Upload Debug File'),
                ),
          Text('Mesasge: ${_message ?? "Upload file to developer"}'),
          Container(
            height: DeviceInfo.getDeviceHeight(context) * 0.75,
            child: SingleChildScrollView(
              child: Text(fileData ?? "getting file contents..."),
            ),
          )
        ],
      )),
    );
  }
}
