
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

  bool hasEditedSettings() {
    bool eq = mutableSettings == widget.settings;
    return !eq;
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(child: 
      Scaffold(
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
        floatingActionButton: Visibility(
          visible: hasEditedSettings(),
          maintainInteractivity: false,
          child: Padding(
            child: FloatingActionButton.extended(
              onPressed: () {
                //TODO trigger send command, show loading wheel, handle error
              },
              icon: Icon(Icons.save),
              label: Text("Save Settings"),
              backgroundColor: Theme.of(context).primaryColor
            ),
            padding: const EdgeInsets.only(bottom: 20.0)
          )
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat
      ), 
      onWillPop: () {
        print("Popping");
        if(hasEditedSettings()) {
          bool shouldPop;
          
          AlertDialog dialog = new AlertDialog(
            title: Text("Exit settings without saving changes?"),
            actions: <Widget>[
              new FlatButton(child: Text("Cancel"), 
                onPressed: () { 
                  print("Pressed cancel"); 
                  Navigator.of(context).pop(false);
                },),
              new FlatButton(child: Text("Confirm"), 
                onPressed: () { 
                  print("Pressed confirm"); 
                  shouldPop = true;
                  Navigator.of(context).pop(true);
                },)
            ],
          );
          return showDialog(context: context, builder: (BuildContext context) {return dialog;});
        } else {
          return Future.value(true);
        }
      },
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
              title: Text("Rotation time"),
              trailing: Text("${screen.rotationTime} seconds"),
              onTap: () {
                Picker picker = new Picker(
                  adapter: NumberPickerAdapter(data: [NumberPickerColumn(begin: 5, end: 120, jump: 5)]),
                  hideHeader: true,
                  title: Text("Select a rotation time in seconds"),
                  onConfirm: (Picker picker, List value) {
                    screen.rotationTime = picker.getSelectedValues()[0];
                    setState(() {
                      
                    });
                  });
                  picker.showDialog(context);
                
              },),
            ListTile(
              title: Text("Favorite teams:"),
              trailing: IconButton( //TODO add info button
                icon: Icon(Icons.add), 
                onPressed: () {
                  List<String> displayData = [];
                  List<int> teamIds = [];
                  for (int teamId in teamMap.keys) {
                    if (!screen.focusTeams.contains(teamId)) {
                      displayData.add(teamMap[teamId].city + " " + teamMap[teamId].name);
                      teamIds.add(teamId);
                    }
                  }
                  Picker picker = new Picker(
                    adapter: PickerDataAdapter<String>(pickerdata: displayData),
                    onConfirm: (Picker picker, List value) {
                      screen.focusTeams.add(teamIds[value[0]]);
                      setState(() {
                        
                      });
                    },
                    title: Text("Add a favorite team"),
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
                        title: Text("    " + teamMap[teamId].city + " " + teamMap[teamId].name)
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