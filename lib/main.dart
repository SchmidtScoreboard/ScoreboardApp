import 'package:flutter/material.dart';
import 'homepage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme(
              primary: Colors.blue,
              secondary: Colors.blue,
              error: Colors.red,
              brightness: Brightness.dark,
              onPrimary: Colors.blue,
              onSecondary: Colors.blue,
              onError: Colors.red,
              onBackground: Colors.blue,
              background: Colors.blue,
              surface: Colors.white,
              onSurface: Colors.white),
          brightness: Brightness.dark,
          platform: TargetPlatform.iOS),
      home: buildHome(),
    );
  }
}
