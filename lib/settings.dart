
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'models.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'teams.dart';
import 'package:flutter_picker/flutter_picker.dart';




class SettingsScreen extends StatefulWidget {
  final ScoreboardSettings settings;
  SettingsScreen({this.settings});

  @override
  State<StatefulWidget> createState() {
    return SettingsScreenState();
  }
}

class SettingsScreenState extends State<SettingsScreen> {
  ScoreboardSettings mutableSettings;
  @override
  void initState() {
    mutableSettings = widget.settings.clone();

    super.initState();
  }
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
        for (var screen in mutableSettings.screens)
          getScreenWidget(screen),
        ListTile(
          leading: IconTheme(data: IconThemeData(color: Colors.red), child: Icon(Icons.delete_forever)),
          title: Text("Delete this scoreboard", style: TextStyle(color: Colors.red)),
          onTap: () { 
            //TODO show delete popup, wipe settings and reset to main screen

          }
        )
      ],)
      ),
      floatingActionButton: Padding(
        child: FloatingActionButton.extended(
          onPressed: () {
            // TODO send save/wifi request

          },
          icon: Icon(Icons.save),
          label: Text("Save Settings"),
          backgroundColor: Theme.of(context).primaryColor
        ),
        padding: const EdgeInsets.only(bottom: 20.0)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget getScreenWidget(Screen screen) {
    Map<int, Team> teamMap;
    switch (screen.id) {
      case ScreenId.MLB:
        teamMap = Team.mlbTeams; 
        break;
      case ScreenId.NHL:
        teamMap = Team.nhlTeams;
        break;
      default:
        print("Could not find team in list");
        return ListTile(title: Text("Scoreboard settings are corrupted"), subtitle: Text("Hold the poower button for 10 seconds to fully reset"),);
    }
    return Theme(data: ThemeData(accentColor: Colors.blue), child:
        ExpansionTile(
          title: Text("${screen.name} Settings"),
          leading: Icon(Icons.desktop_mac),
          children: <Widget>[
            ListTile(
              title: Text("Favorite teams:"),
              trailing: IconButton(
                icon: Icon(Icons.add), 
                onPressed: () {
                   List<String> data = [];
                   for (int teamId in teamMap.keys) {
                    data.add(teamMap[teamId].city + " " + teamMap[teamId].name);
                   }
                   Picker picker = new Picker(
                     adapter: PickerDataAdapter<String>(pickerdata: data),
                     onConfirm: (Picker picker, List value) {
                       print(value.toString());
                     },
                     title: Text("Select a favorite team"),
                     hideHeader: true,
                     looping: true

                   );
                   picker.showDialog(context);

                }

              )),
            Column(
              children: screen.focusTeams.map(
                (int teamId) => 
                  Slidable(
                    key: 
                      ValueKey(teamId),
                    child: 
                      ListTile(
                        key: ValueKey(teamId), 
                        title: Text(teamMap[teamId].city + " " + teamMap[teamId].name)
                      ), 
                    actionPane: 
                      SlidableDrawerActionPane(),
                    secondaryActions: <Widget>[
                      IconSlideAction(
                        icon: Icons.delete, 
                        color: Colors.red,
                        onTap: () {
                          screen.focusTeams.remove(teamId);
                          setState(() {
                            
                          });
                        },)
                    ],
                    
                  )
                ).toList()
            ),

          ],
        )
      );
      


  } 
}