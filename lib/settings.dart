
import 'package:flutter/material.dart';
import 'models.dart';

class SettingsScreen extends StatelessWidget {
  final ScoreboardSettings settings;
  SettingsScreen({this.settings});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () {
            // Navigate back to first route when tapped.
          },
          child: Text('Go back!'),
        ),
      ),
    );
  }
}