
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

class SettingsScreenState extends State<SettingsScreen> {
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
          
        ),
        Divider(),
        for (var screen in widget.settings.screens)
          getScreenWidget(screen),
      ],)
      ),
      floatingActionButton: Padding(
        child: FloatingActionButton.extended(
          onPressed: () {

          },
          icon: Icon(Icons.save),
          label: Text("Save Settings"),
        ),
        padding: const EdgeInsets.only(bottom: 20.0)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget getScreenWidget(Screen screen) {
    return Column(children: <Widget>[
      ListTile(
        title: Text("${screen.name} settings"),
        onTap: () {}
      ),
      

    ]);

  } 
}