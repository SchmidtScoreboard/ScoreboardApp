
import 'package:flutter/material.dart';
import 'models.dart';

class SettingsScreen extends StatefulWidget {
  final ScoreboardSettings settings;
  SettingsScreen({this.settings});

  @override
  State<StatefulWidget> createState() {
    return SettingsScreenState();
  }
}

class SettingsScreenState extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Scoreboard Settings"),
      ),
      body: ( ListView(children: <Widget>[
        ListTile(
          leading: Icon(Icons.wifi),
          title: Text("WiFi Settings"),
          onTap: () {
            //TODO open wifi settings screen
          },
          
        )
      ],)
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {

        },
        icon: Icon(Icons.save),
        label: Text("Save Settings"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
}