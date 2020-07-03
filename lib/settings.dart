import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'teams.dart';
import 'channel.dart';
import 'homepage.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:badges/badges.dart';

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
  bool showWifiPassword = false;
  @override
  void initState() {
    print("Initializing settings state");
    originalSettings = widget.settings.clone();
    mutableSettings = widget.settings.clone();
    passNode.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  bool hasEditedSettings() => settingsDirty() || wifiDirty() || nameDirty();

  bool settingsDirty() => mutableSettings != originalSettings;
  bool wifiDirty() => wifi.isNotEmpty && password.isNotEmpty;
  bool nameDirty() => mutableSettings.name != originalSettings.name;

  Future submitCallback() async {
    if (!requesting) {
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
      if (settingsDirty() || nameDirty()) {
        print("Settings dirty");
        AppState state = await AppState.load();
        String ip = state.scoreboardAddresses[state.activeIndex];
        print("Configuring settings for scoreboard at address: $ip");
        return await Channel(ipAddress: ip).configureSettings(mutableSettings);
      }
    } catch (e) {
      //TDOO  display an error
      print(e);
    }
    return mutableSettings;
  }

  Future handleName() async {
    if (nameDirty()) {
      print("Name dirty");
      AppState.setName(mutableSettings.name);
    }
  }

  Future handleWifi() async {
    if (wifiDirty()) {
      print("Wifi dirty");
      AppState state = await AppState.load();
      String ip = state.scoreboardAddresses[state.activeIndex];
      print("Setting wifi for scoreboard at address: $ip");
      ScoreboardSettings scoreboard =
          await Channel(ipAddress: ip).wifiRequest(wifi, password);
      await AppState.setState(SetupState.SYNC);
      Navigator.of(context)
          .pop(); //get out of this page and back to the home screen, which should hopefully rebuild into QR state
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Mutable settings name: " + mutableSettings.name);
    bool scoreboardOutOfDate =
        mutableSettings.version < ScoreboardSettings.clientVersion;
    return WillPopScope(
      child: Scaffold(
          appBar: AppBar(
            title: Text("Edit Scoreboard Settings"),
          ),
          body: (ListView(
            children: <Widget>[
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
                      textCapitalization: TextCapitalization.words,
                      //initialValue: mutableSettings.name,

                      onChanged: (String newName) {
                        name = newName;
                      },
                    ),
                    actions: <Widget>[
                      new FlatButton(
                        child: Text("Cancel"),
                        onPressed: () {
                          print("Pressed cancel");
                          Navigator.of(context).pop();
                        },
                      ),
                      new FlatButton(
                        child: Text("Confirm"),
                        onPressed: () {
                          print("Pressed confirm");
                          setState(() {
                            mutableSettings.name = name;
                          });
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  );
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return dialog;
                      });
                },
              ),
              ExpansionTile(
                leading: Icon(Icons.wifi),
                title: Text("WiFi Settings"),
                children: <Widget>[
                  ListTile(
                      title: Text(
                          "Updating wifi settings will require your scoreboard to restart")),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(brightness: Brightness.dark),
                        child: TextField(
                          decoration: InputDecoration(
                            icon: Icon(Icons.wifi),
                            labelText: "Wifi Name",
                          ),
                          maxLines: 1,
                          maxLength: 32,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          focusNode: wifiNode,
                          onChanged: (String s) {
                            setState(() {
                              wifi = s;
                            });
                          },
                          onEditingComplete: () {
                            FocusScope.of(context).requestFocus(passNode);
                          },
                        ),
                      )),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Theme(
                          data: Theme.of(context)
                              .copyWith(brightness: Brightness.dark),
                          child: Stack(children: <Widget>[
                            TextField(
                              decoration: InputDecoration(
                                  icon: Icon(Icons.lock),
                                  labelText: "Password"),
                              maxLines: 1,
                              obscureText: !showWifiPassword,
                              autocorrect: false,
                              maxLength: 63,
                              textInputAction: TextInputAction.send,
                              focusNode: passNode,
                              onChanged: (String s) {
                                setState(() {
                                  password = s;
                                });
                              },
                              onEditingComplete: () {},
                            ),
                            Positioned(
                                bottom: 14,
                                right: 0,
                                child: IconButton(
                                    color: Theme.of(context).accentColor,
                                    disabledColor:
                                        Theme.of(context).disabledColor,
                                    icon: showWifiPassword
                                        ? Icon(FontAwesomeIcons.eyeSlash)
                                        : Icon(FontAwesomeIcons.eye),
                                    iconSize: 16,
                                    onPressed: passNode.hasFocus
                                        ? () {
                                            setState(() {
                                              showWifiPassword =
                                                  !showWifiPassword;
                                            });
                                          }
                                        : null)),
                          ]))),
                ],
              ),
              for (var screen in mutableSettings.screens)
                getScreenWidget(screen),
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text("Timezone: ${mutableSettings.timezone}"),
                onTap: () {
                  Picker picker = new Picker(
                      adapter: PickerDataAdapter<String>(pickerdata: timezones),
                      onConfirm: (Picker picker, List value) {
                        mutableSettings.timezone = timezones[value[0]];
                        setState(() {});
                      },
                      backgroundColor: Colors.transparent,
                      textStyle: TextStyle(color: Colors.white, fontSize: 18),
                      title: Text("Change the timezone"),
                      hideHeader: true,
                      looping: false);
                  picker.showDialog(context);
                },
              ),
              ExpansionTile(
                leading: Icon(Icons.info),
                title: Text("About"),
                children: <Widget>[
                  ListTile(
                      leading: Icon(Icons.tv),
                      title: Text(
                          "Scoreboard Version: ${mutableSettings.version}")),
                  ListTile(
                      leading: Icon(Icons.phone_iphone),
                      title: Text(
                          "App Version: ${ScoreboardSettings.clientVersion}")),
                  ListTile(
                      leading: Icon(Icons.wifi_tethering),
                      title: Text(
                          "Scoreboard MAC Address:\n${mutableSettings.macAddress}")),
                  ListTile(
                      title: Text("Made for Jamie"),
                      leading: Icon(Icons.favorite)),
                  ListTile(
                    title: Text("Privacy and Usage Policy"),
                    leading: Icon(FontAwesomeIcons.key),
                    onTap: () {
                      AlertDialog policyAlert = AlertDialog(
                        title: Text("Prviacy and Usage Policy"),
                        content: Text(AppState.POLICY_TEXT),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return policyAlert;
                          });
                    },
                  )
                ],
              ),
              ListTile(
                leading: scoreboardOutOfDate
                    ? Badge(
                        child: Icon(Icons.power_settings_new),
                        badgeContent:
                            Text("1", style: TextStyle(color: Colors.white)),
                      )
                    : Icon(Icons.power_settings_new),
                title: Text("Reboot this scoreboard"),
                subtitle: Text("Scoreboard will check for updates on reboot"),
                onTap: () {
                  AlertDialog alert = AlertDialog(
                      title: Text("Reboot this scoreboard"),
                      content: Text(
                          "Rebooting will also update the scoreboard to the latest version.\nThis may take a minute."),
                      actions: <Widget>[
                        FlatButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                          child: Text("Reboot"),
                          onPressed: () async {
                            AppState state = await AppState.load();
                            String ip =
                                state.scoreboardAddresses[state.activeIndex];
                            print("Rebooting at ip : $ip");
                            try {
                              await Channel(ipAddress: ip).rebootRequest();
                            } catch (e) {
                              print(e.toString());
                            } finally {
                              Navigator.of(context).pop();
                            }
                          },
                        )
                      ]);
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return alert;
                      });
                },
              ),
              ListTile(
                  leading: IconTheme(
                      data: IconThemeData(color: Colors.red),
                      child: Icon(Icons.delete_forever)),
                  title: Text("Delete this scoreboard",
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    AlertDialog alert = AlertDialog(
                      title: Text("Are you sure?"),
                      content: Text(
                          "This action will only delete the saved settings from the app. To fully reset it, hold the side button on the scoreboard for ten seconds."),
                      actions: <Widget>[
                        FlatButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                          child: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () async {
                            await AppState.removeScoreboard();
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => buildHome()));
                          },
                        )
                      ],
                    );
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return alert;
                        });
                  })
            ],
          )),
          floatingActionButton: Visibility(
              visible: hasEditedSettings(),
              maintainInteractivity: false,
              child: SafeArea(
                bottom: true,
                minimum: EdgeInsets.all(20),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    submitCallback();
                  },
                  icon: requesting
                      ? Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            valueColor:
                                new AlwaysStoppedAnimation<Color>(Colors.white),
                          ))
                      : Icon(Icons.save),
                  label:
                      requesting ? Text("Loading...") : Text("Save Settings"),
                  backgroundColor: Theme.of(context).accentColor,
                  foregroundColor: Colors.white,
                ),
              )),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat),
      onWillPop: () {
        print("Popping");
        if (hasEditedSettings()) {
          AlertDialog dialog = new AlertDialog(
            title: Text("Exit settings without saving changes?"),
            actions: <Widget>[
              new FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  print("Pressed cancel");
                  Navigator.of(context).pop(false);
                },
              ),
              new FlatButton(
                child: Text("Confirm"),
                onPressed: () {
                  print("Pressed confirm");
                  Navigator.of(context).pop(true);
                },
              )
            ],
          );
          return showDialog(
              context: context,
              builder: (BuildContext context) {
                return dialog;
              });
        } else {
          return Future.value(true);
        }
      },
    );
  }

  void showAddTeamDialog(Map<int, Team> teamMap, Screen screen) {
    List<Team> displayData = [];
    for (int teamId in teamMap.keys) {
      if (!screen.focusTeams.contains(teamId)) {
        displayData.add(teamMap[teamId]);
      }
    }
    displayData.sort();
    Picker picker = new Picker(
        adapter: PickerDataAdapter<Team>(pickerdata: displayData),
        onConfirm: (Picker picker, List value) {
          screen.focusTeams.add(displayData[value[0]].id);
          setState(() {});
        },
        backgroundColor: Colors.transparent,
        textStyle: TextStyle(color: Colors.white, fontSize: 18),
        title: Text("Add a favorite team"),
        hideHeader: true);
    picker.showDialog(context);
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
        return Container();
    }
    return //Theme(data: ThemeData(accentColor: Colors.blue), child:
        ExpansionTile(
      title: Text("${screen.name} Settings"),
      leading: Icon(screen.getIcon()),
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.timer),
          title: Text("Rotation time"),
          trailing: Text("${screen.rotationTime} seconds"),
          onTap: () {
            Picker picker = new Picker(
                adapter: NumberPickerAdapter(
                    data: [NumberPickerColumn(begin: 5, end: 120, jump: 5)]),
                hideHeader: true,
                title: Text("Select a rotation time in seconds"),
                backgroundColor: Colors.transparent,
                textStyle: TextStyle(color: Colors.white, fontSize: 18),
                onConfirm: (Picker picker, List value) {
                  screen.rotationTime = picker.getSelectedValues()[0];
                  setState(() {});
                });
            picker.showDialog(context);
          },
        ),
        ListTile(
            leading: Icon(Icons.favorite),
            title: Text("Favorite teams:"),
            onTap: () {
              showAddTeamDialog(teamMap, screen);
            },
            trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  showAddTeamDialog(teamMap, screen);
                })),
        Column(
            children: screen.focusTeams
                .map((int teamId) => Slidable(
                      key: ValueKey(teamId),
                      child: ListTile(
                          key: ValueKey(teamId),
                          title: Text("    " +
                              teamMap[teamId].city +
                              " " +
                              teamMap[teamId].name)),
                      actionPane: SlidableDrawerActionPane(),
                      secondaryActions: <Widget>[
                        IconSlideAction(
                          icon: Icons.delete,
                          color: Colors.red,
                          onTap: () {
                            screen.focusTeams.remove(teamId);
                            setState(() {});
                          },
                        )
                      ],
                    ))
                .toList()),
      ],
    );
    //);
  }
}

List<String> timezones = [
  "US/Alaska",
  "US/Arizona",
  "US/Central",
  "US/Eastern",
  "US/Hawaii",
  "US/Mountain",
  "US/Pacific",
  "UTC"
];
