import 'package:flutter/material.dart';
import 'package:braestcancer/login_page.dart'; // Import LoginPage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(), // Set LoginPage as the initial route
    );
  }
}

