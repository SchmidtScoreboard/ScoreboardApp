import 'package:flutter/material.dart';
import 'homepage.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.orangeAccent,
        brightness: Brightness.light,
      ),
      home: buildHome(),
    );
  }
}
