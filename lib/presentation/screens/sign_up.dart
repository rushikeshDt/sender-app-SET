import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:sender_app/domain/debug_printer.dart';
import 'package:sender_app/presentation/screens/login.dart';
import 'package:sender_app/presentation/screens/request_screen.dart';
import 'package:sender_app/user/user_info.dart' as CurrentUser;
import 'package:sender_app/utils/validate%20email.dart';
import 'package:sender_app/utils/validate_email.dart';
import 'package:sender_app/utils/validate_phone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController _emailTextController = new TextEditingController();
  TextEditingController _passwordTextController = new TextEditingController();
  TextEditingController _phoneTextController = new TextEditingController();
  TextEditingController _usernameTextController = new TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _error = "EMPTY";

  // late String? _verificationId;
  // late int? _token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('SignUp'),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                      "A verification email will be sent. Verify your email before loggin in."),
                  SizedBox(height: 20),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && RegExp(r'\s').hasMatch(value)) {
                        return "username value should not include spaces";
                      }
                    },
                    decoration: InputDecoration(labelText: 'username'),
                    controller: _usernameTextController,
                  ),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                    decoration: InputDecoration(labelText: 'email'),
                    controller: _emailTextController,
                  ),
                  TextFormField(
                    validator: validatePassword,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'password'),
                    controller: _passwordTextController,
                  ),
                  TextFormField(
                    validator: validatePhoneNumber,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'phone'),
                    controller: _phoneTextController,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      print(_emailTextController.text);
                      DebugFile.saveTextData('''[SignUpPage]
                      email: ${_emailTextController.text.trim()},
                      password: ${_passwordTextController.text.trim()},
                      phone: ${_phoneTextController.text.trim()}
                      ''');

                      print(_passwordTextController.text);

                      if (_formKey.currentState!.validate()) {
                        _SignUpUser(
                                _emailTextController.text.trim(),
                                _passwordTextController.text.trim(),
                                _usernameTextController.text.trim(),
                                _phoneTextController.text.trim(),
                                context)
                            .then((value) {
                          if (value) {
                            Navigator.pushAndRemoveUntil(context,
                                MaterialPageRoute(builder: (context) {
                              return LoginPage();
                            }), (route) => false);
                          } else {
                            // const Toast(
                            //   child: Text("problem logging in"),
                            // ).show(context);
                            setState(() {
                              _error = "problem logging in";
                            });
                          }
                        });
                      } else {
                        // const Toast(
                        //         child: Text("plz resolve all validation message"))
                        //     .show(context);
                        setState(() {
                          _error = "plz resolve all validation message";
                        });
                      }
                    },
                    child: Text('SignUp'),
                  ),
                  SizedBox(height: 20),
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
            )),
      ),
    );
  }

  Future<bool> _SignUpUser(String email, String password, String username,
      String phone, BuildContext context) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      user.sendEmailVerification();

      final uniqueUserId = user.uid;
      print(uniqueUserId);

      final CollectionReference UsersCollection =
          FirebaseFirestore.instance.collection('users');

      await UsersCollection.doc(uniqueUserId).set({
        'username': username,
        'phone': phone,
        'userID': uniqueUserId,
        'createdAt': DateTime.now().toLocal().toString(),
        'userEmail': email,
      });
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        // const Toast(
        //   child: Text('The password provided is too weak.'),
        // ).show(context);
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        // const Toast(
        //   child: Text('The account already exists for that email.'),
        // ).show(context);
      }
      rethrow;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      print(e);
      return false;
    }
  }
}






  // _getOTP() async {
  //   print("sending OTP");
  //   await FirebaseAuth.instance.verifyPhoneNumber(
  //     phoneNumber: "+91${_emailTextController.text}",
  //     verificationCompleted: (PhoneAuthCredential credential) {},
  //     verificationFailed: (FirebaseAuthException e) {},
  //     codeSent: (String verificationId, int? resendToken) async {
  //       print("otp sent");
  //       setState(() {
  //         _verificationId = verificationId;
  //         _token = resendToken;
  //       });
  //     },
  //     codeAutoRetrievalTimeout: (String verificationId) {},
  //   );
  // }



   // if (_verificationId == null) {
    //   print("no verificationId have you performed _getOTP() ?");
    // }
    // FirebaseAuth auth = FirebaseAuth.instance;
    // print("OTP entered " + _passwordTextController.text);
    // String smsCode = _passwordTextController.text;

    // // Create a PhoneAuthCredential with the code
    // PhoneAuthCredential credential = PhoneAuthProvider.credential(
    //     verificationId: _verificationId!, smsCode: smsCode);
    // try {
    //   // Sign the user in (or link) with the credential
    //   UserCredential creds = await auth.signInWithCredential(credential);

    //   print("logIn success");
    //   print(
    //       "user info obtain after login ${creds.additionalCurrentUser ?? "no info obtained"}");
    //   return true;
    // } catch (e) {
    //   print("_error loggging in " + e.toString());
    //   return false;
    // }