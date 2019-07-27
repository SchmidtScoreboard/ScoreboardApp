
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'models.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'teams.dart';
import 'channel.dart';
import 'homepage.dart';
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
  ScoreboardSettings originalSettings; 
  FocusNode wifiNode = FocusNode();
  FocusNode passNode = FocusNode();
  String wifi = "";
  String password = "";
  bool requesting = false;
  @override
  void initState() {
    print("Initializing settings state");
    originalSettings = widget.settings.clone();
    mutableSettings = widget.settings.clone();

    super.initState();
  }

  bool hasEditedSettings() => settingsDirty() || wifiDirty();

  bool settingsDirty() => mutableSettings != originalSettings;
  bool wifiDirty() => wifi.isNotEmpty && password.isNotEmpty;
  bool nameDirty() => mutableSettings.name != originalSettings.name;

  Future submitCallback() async {
    if(!requesting) {
      setState(() {
        requesting = true;
      });
      ScoreboardSettings settings = await handleSettings();
      await handleName();
      await handleWifi();

      setState(() {
        print(settings.name);
        originalSettings = settings.clone();
        mutableSettings = settings.clone();
        requesting = false;
      });
    }
  }

  Future<ScoreboardSettings> handleSettings() async {
    try {
      if(settingsDirty()) {
        print("Settings dirty");
        return await Channel.localChannel.configureSettings(mutableSettings);
      }
    } catch (e) {
      //TDOO  display an error
    }
    return mutableSettings;

  }

  Future handleName() async {
    if(nameDirty()) {
      print("Name dirty");
      AppState.setName(mutableSettings.name);
    }
  }

  Future handleWifi() async {
    if(wifiDirty()) {
      print("Wifi dirty");
      ScoreboardSettings scoreboard = await Channel.localChannel.wifiRequest(wifi, password); //TODO replcae all these localChannels with the actual addresses
      await AppState.setState(SetupState.SYNC);
      Navigator.of(context).pop(); //get out of this page and back to the home screen, which should hopefully rebuild into QR state
    }

  }

  @override
  Widget build(BuildContext context) {
    print("Mutable settings name: " + mutableSettings.name);
    return WillPopScope(child: 
      Scaffold(
        appBar: AppBar(
          title: Text("Edit Scoreboard Settings"),
        ),
        body: ( ListView(children: <Widget>[
          ListTile(
            leading: Icon(Icons.tv),
            title: Text("Rename this scoreboard"),
            subtitle: Text(mutableSettings.name),
            onTap: () {
              String name = mutableSettings.name;
              AlertDialog dialog = AlertDialog(
                title: Text("Enter a new scoreboard name:"),
                content: TextField(
                  maxLines: 1, 
                  maxLength: 32,
                  decoration: InputDecoration(labelText: "Scoreboard Name"),
                  //initialValue: mutableSettings.name,
                  
                  onChanged: (String newName) {
                      name = newName;
                    },
                  ),
                actions: <Widget>[
                  new FlatButton(child: Text("Cancel"), 
                    onPressed: () { 
                      print("Pressed cancel"); 
                      Navigator.of(context).pop();
                    },),
                  new FlatButton(child: Text("Confirm"), 
                    onPressed: () { 
                      print("Pressed confirm"); 
                      setState(() {
                        mutableSettings.name = name;
                      });
                      Navigator.of(context).pop();
                    },)
                ],
              );
              showDialog(context: context, builder: (BuildContext context) {return dialog;});
            },),
          ExpansionTile(
            leading: Icon(Icons.wifi),
            title: Text("WiFi Settings"),
            children: <Widget>[
              ListTile(title: Text("Updating wifi settings will require your scoreboard to restart")),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: 
                Theme(data: Theme.of(context).copyWith(brightness: Brightness.dark), child:
                  TextField(decoration: 
                    InputDecoration(
                      labelText: "Wifi Name",
                    ),
                    maxLines: 1, 
                    maxLength: 32,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    focusNode: wifiNode,
                    onChanged: (String s) {setState(() {
                      wifi = s; 
                    });},
                    onEditingComplete: () {FocusScope.of(context).requestFocus(passNode);},
                  ),
                )
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: 
                Theme(data: Theme.of(context).copyWith(brightness: Brightness.dark), child:
                  TextField(decoration: 
                    InputDecoration(
                      labelText: "Password",
                    ),
                    maxLines: 1, 
                    maxLength: 32,
                    obscureText: true,
                    autocorrect: false,
                    textInputAction: TextInputAction.send,
                    focusNode: passNode,
                    onChanged: (String s) {
                      setState(() {
                        password = s;
                      });
                    },
                    onEditingComplete: () {
                      
                    },
                  ),
                )
              ),


            ],
          ),
          for (var screen in mutableSettings.screens)
            getScreenWidget(screen),
          ListTile(
            leading: IconTheme(data: IconThemeData(color: Colors.red), child: Icon(Icons.delete_forever)),
            title: Text("Delete this scoreboard", style: TextStyle(color: Colors.red)),
            onTap: () { 
              //TODO show delete popup, wipe settings and reset to main screen
              AlertDialog alert = AlertDialog(
                title: Text("Are you sure?"),
                content: Text("This action will only delete the saved settings from the app. To fully reset it, hold the side button on the scoreboard for ten seconds."),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text("Delete", style: TextStyle(color: Colors.red),),
                    onPressed: () async {
                      await AppState.removeScoreboard();
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => buildHome()));
                    },
                  )
                ],
              );
              showDialog(context: context, builder: (BuildContext context) { return alert; });


            }
          )
        ],)
        ),
        floatingActionButton:
            Visibility(
              visible: hasEditedSettings(),
              maintainInteractivity: false,
              child: SafeArea(
                bottom: true,
                child: FloatingActionButton.extended(
                  onPressed: () {submitCallback(); },
                  icon: requesting ? Padding(padding: EdgeInsets.all(20), child:
                    CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),)) : Icon(Icons.save),
                  label: requesting ? Text("Loading...") : Text("Save Settings"),
                  backgroundColor: Theme.of(context).accentColor,
                  foregroundColor: Colors.white,
                ),
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
    return //Theme(data: ThemeData(accentColor: Colors.blue), child:
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
        );
      //);
      


  } 
}