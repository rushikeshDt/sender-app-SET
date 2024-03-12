import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sender_app/utils/validate_email.dart';

class ResetPasswordPage extends StatelessWidget {
  TextEditingController _controller = TextEditingController();
  ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(50),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    var value = validateEmail(_controller.text);
                    print('value is $value');
                    if (value == null) {
                      FirebaseAuth.instance
                          .sendPasswordResetEmail(email: _controller.text);

                      Navigator.of(context).pop(true);
                    } else {
                      _controller.text = value;
                    }
                  },
                  child: Text("Send"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User clicked "Yes"
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
