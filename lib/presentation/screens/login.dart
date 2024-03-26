import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:sender_app/domain/debug_printer.dart';

import 'package:sender_app/presentation/screens/request_screen.dart';
import 'package:sender_app/presentation/screens/reset_password.dart';
import 'package:sender_app/presentation/screens/sign_up.dart';
import 'package:sender_app/presentation/screens/verify_email.dart';
import 'package:sender_app/user/user_info.dart';
import 'package:sender_app/utils/validate%20password.dart';

import 'package:sender_app/utils/validate_email.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String _error = "EMPTY";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Your code here (e.g., setState)
      _autoLogIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      validator: (email) {
                        return email != null
                            ? validateEmail(email.trim())
                            : null;
                      },
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      validator: (pwd) {
                        return pwd != null
                            ? validatePassword(pwd.trim())
                            : null;
                      },
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                        });
                        if (_formKey.currentState!.validate()) {
                          _logInUser(_emailController.text.trim(),
                                  _passwordController.text.trim())
                              .then((value) {
                            if (value == 'SUCCESS') {
                              Navigator.pushAndRemoveUntil(context,
                                  MaterialPageRoute(builder: (context) {
                                return RequestPage();
                              }), (route) => false);
                            } else {
                              setState(() {
                                _isLoading = false;
                                _error = value;
                              });
                            }
                          });
                        } else {
                          setState(() {
                            _isLoading = false;
                            _error =
                                'Please make sure there are no validation errors';
                          });
                        }
                      },
                      child: Text('Login'),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()));
                      },
                      child: Text('SignUp'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => ResetPasswordPage()));
                      },
                      child: Text('Forgot password?'),
                    ),
                    SizedBox(height: 10),
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
    );
  }

  Future<String> _logInUser(String emailAddress, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailAddress, password: password);
      final user = credential.user;
      if (user == null) {
        return 'user null';
      }
      print('emailverified: ${credential.user!.emailVerified}');
      DebugFile.saveTextData(
          '[LogInPge] emailverified: ${credential.user!.emailVerified}');
      if (!(credential.user!.emailVerified)) {
        Navigator.push(
            context, MaterialPageRoute(builder: (ctx) => VerifyEmail()));
        print('[logInPage] email unverified. ${user.email}');
        DebugFile.saveTextData('[logInPage] email unverified. ${user.email}');
        return "email unverified. verify email before login. Check your emails for verification email.";
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', emailAddress);
      await prefs.setString('password', password);
      await CurrentUser.fetchUser(user.uid);
      return 'SUCCESS';
    } catch (e) {
      print("[LogInPage] error ${e.toString()}");
      DebugFile.saveTextData("[LogInPage] error ${e.toString()}");
      return e.toString();
    }
  }

  void _autoLogIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');

    if (email != null && password != null) {
      print('[print] email and password found in prefs ${email} ${password}');
      DebugFile.saveTextData(
          '[LogInPage] email and password found in prefs ${email} ${password}');
      final value = await _logInUser(email.trim(), password.trim());

      if (value == 'SUCCESS') {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) {
          return RequestPage();
        }), (route) => false);
        return;
      } else {
        setState(() {
          _isLoading = false;
          _error = value;
        });
      }
    }
    setState(() {
      _isLoading = false;
      _error = 'Please log in';
    });
  }
}
