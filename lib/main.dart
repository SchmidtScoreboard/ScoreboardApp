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
          appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme(
              primary: Colors.blue,
              secondary: Colors.blue,
              error: Colors.red,
              brightness: Brightness.dark,
              onPrimary: Colors.transparent,
              onSecondary: Colors.transparent,
              onError: Colors.red,
              onBackground: Colors.transparent,
              background: Colors.blue,
              surface: Colors.white,
              onSurface: Colors.white),
          brightness: Brightness.dark,
          platform: TargetPlatform.iOS),
      home: buildHome(),
    );
  }
}
