import 'package:flutter/material.dart';
import 'package:sender_app/presentation/screens/request_screen.dart';
import 'package:sender_app/user/user_info.dart';

class LogInPage extends StatelessWidget {
  TextEditingController uIdTxtCntrl = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Your Email ID'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'app will crash if no id'),
              controller: uIdTxtCntrl,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                UserInfo.userId = uIdTxtCntrl.text;
                //remove userId from requestscreen params
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequestPage()),
                );
              },
              child: Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }
}
