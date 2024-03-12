import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:sender_app/configs/device_info.dart';

class VerifyEmail extends StatefulWidget {
  VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  String _error = 'EMPTY';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(
            10, DeviceInfo.getDeviceHeight(context) / 4, 10, 0),
        child: Column(
          children: [
            Text(
                'Your email is unverified.\n Do you want to send another email to your email address for verification ?'),
            SizedBox(
              height: 16,
            ),
            Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      try {
                        FirebaseAuth.instance.currentUser!
                            .sendEmailVerification();
                      } catch (e) {
                        setState(() {
                          _error =
                              "Please try logging in again \n${e.toString()}";
                        });
                      }

                      Navigator.pop(context);
                    },
                    child: Text('Yes')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('No')),
              ],
            ),
            Visibility(
                visible: _error == "EMPTY" ? false : true,
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  color: Colors.grey,
                  child: Text(
                    _error,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
