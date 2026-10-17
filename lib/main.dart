import 'package:flutter/material.dart';
import 'pages/dashboard.dart';

void main() => runApp(const BillShieldApp());

class BillShieldApp extends StatelessWidget {
  const BillShieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BillShield',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const Dashboard(),
    );
  }
}