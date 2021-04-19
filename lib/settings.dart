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
    print("Brightness:  ${originalSettings.brightness}");
    passNode.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  bool hasEditedSettings() => settingsDirty() || wifiDirty() || nameDirty();

  bool settingsDirty() => mutableSettings != originalSettings;
  bool wifiDirty() => wifi.isNotEmpty && password.isNotEmpty;
  bool nameDirty() => mutableSettings.name != originalSettings.name;
  bool brightnessDirty() =>
      mutableSettings.brightness != originalSettings.brightness;

  Future handleChanges() async {
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

  Future submitCallback() async {
    if (!requesting) {
      setState(() {
        requesting = true;
      });
      if (brightnessDirty()) {
        // Show a popup
        AlertDialog policyAlert = AlertDialog(
          title: Text("Restart Required"),
          content: Text(
              "Changing brightness requires a restart of your scoreboard. Continue?"),
          actions: <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("OK"),
              onPressed: () async {
                Navigator.of(context).pop();
                await handleChanges();
              },
            ),
          ],
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return policyAlert;
            });
      } else {
        await handleChanges();
      }
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

  int brightnessToBrightnessSelection(int brightness) {
    if (brightness == LOW_BRIGHTNESS) {
      return 0;
    } else if (brightness == MID_BRIGHTNESS) {
      return 1;
    } else if (brightness == HIGH_BRIGHTNESS) {
      return 2;
    } else {
      return 3;
    }
  }

  int brightnesSelectionToBrightness(int selection) {
    if (selection == 0) {
      return LOW_BRIGHTNESS;
    } else if (selection == 1) {
      return MID_BRIGHTNESS;
    } else if (selection == 2) {
      return HIGH_BRIGHTNESS;
    } else {
      return MAX_BRIGHTNESS;
    }
  }

  Map<int, Widget> getBrightnessWidgets() {
    var map = {
      0: Text("  Low  "),
      1: Text("  Mid  "),
      2: Text("  High  "),
      3: Text("  Max  ")
    };
    // map.map(
    //     (key, value) => MapEntry(key, Container(width: 1000, child: value)));
    return map;
  }

  @override
  Widget build(BuildContext context) {
    var teamMaps = {
      ScreenId.MLB: Team.mlbTeams,
      ScreenId.NHL: Team.nhlTeams,
      ScreenId.COLLEGE_BASKETBALL: Team.ncaaTeams,
      ScreenId.BASKETBALL: Team.nbaTeams,
      ScreenId.FOOTBALL: Team.nflTeams,
      ScreenId.COLLEGE_FOOTBALL: Team.ncaaTeams,
    };
    print("Mutable settings name: " + mutableSettings.name);
    bool scoreboardOutOfDate =
        mutableSettings.version < ScoreboardSettings.clientVersion;
    int brightnessSelect =
        brightnessToBrightnessSelection(mutableSettings.brightness ?? 100);
    return WillPopScope(
      child: Scaffold(
          appBar: AppBar(
            title: Text("Edit Scoreboard Settings"),
          ),
          body: Center(
              child: SizedBox(
                  width: 600,
                  child: ListView(
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
                              decoration:
                                  InputDecoration(labelText: "Scoreboard Name"),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
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
                                    FocusScope.of(context)
                                        .requestFocus(passNode);
                                  },
                                ),
                              )),
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
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
                                            color:
                                                Theme.of(context).accentColor,
                                            disabledColor:
                                                Theme.of(context).disabledColor,
                                            icon: showWifiPassword
                                                ? Icon(
                                                    FontAwesomeIcons.eyeSlash)
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
                      ListTile(
                        leading: Icon(Icons.timer),
                        title: Text("Rotation time"),
                        trailing:
                            Text("${mutableSettings.rotationTime} seconds"),
                        onTap: () {
                          Picker picker = new Picker(
                              adapter: NumberPickerAdapter(data: [
                                NumberPickerColumn(begin: 5, end: 120, jump: 5)
                              ]),
                              hideHeader: true,
                              title: Text("Select a rotation time in seconds"),
                              backgroundColor: Colors.transparent,
                              textStyle:
                                  TextStyle(color: Colors.white, fontSize: 18),
                              onConfirm: (Picker picker, List value) {
                                mutableSettings.rotationTime =
                                    picker.getSelectedValues()[0];
                                setState(() {});
                              });
                          picker.showDialog(context);
                        },
                      ),
                      ListTile(
                          leading: Icon(Icons.favorite),
                          title: Text("Favorite teams:"),
                          onTap: () {
                            showAddTeamDialog(teamMaps);
                          },
                          trailing: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                showAddTeamDialog(teamMaps);
                              })),
                      Column(
                          children: mutableSettings.focusTeams
                              .where((FocusTeam team) =>
                                  teamMaps.containsKey(team.screenId))
                              .map((FocusTeam team) => Slidable(
                                    // key: ValueKey(team.teamId),
                                    child: ListTile(
                                        // key: ValueKey(team.teamId),
                                        title: Text("        " +
                                            ScreenId.getEmoji(team.screenId) +
                                            "  " +
                                            teamMaps[team.screenId][team.teamId]
                                                .toString())),
                                    actionPane: SlidableDrawerActionPane(),
                                    secondaryActions: <Widget>[
                                      IconSlideAction(
                                        icon: Icons.delete,
                                        color: Colors.red,
                                        onTap: () {
                                          mutableSettings.focusTeams
                                              .remove(team);
                                          setState(() {});
                                        },
                                      )
                                    ],
                                  ))
                              .toList()),
                      Builder(builder: (context) {
                        FocusTeam golfKey =
                            FocusTeam(screenId: ScreenId.GOLF, teamId: 0);
                        return CheckboxListTile(
                            value: mutableSettings.focusTeams.contains(golfKey),
                            onChanged: (bool newValue) {
                              if (newValue) {
                                mutableSettings.focusTeams.add(golfKey);
                              } else {
                                mutableSettings.focusTeams.remove(golfKey);
                              }
                              setState(() {});
                            },
                            activeColor: Theme.of(context).accentColor,
                            secondary: Icon(Icons.sports_golf),
                            title: Text("Prioritize Golf"),
                            subtitle: Text("Focus on Golf events when active"));
                      }),
                      CheckboxListTile(
                          value: mutableSettings.clock_off_auto_power,
                          onChanged: (bool newValue) {
                            mutableSettings.clock_off_auto_power = newValue;
                            setState(() {
                              
                            });
                          },
                            activeColor: Theme.of(context).accentColor,
                            secondary: Icon(FontAwesomeIcons.clock),
                            title: Text("Automatic Clock"),
                            subtitle: Text("Show clock when there are no sports and magic power is enabled")
                          ),
                      ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text("Timezone: ${mutableSettings.timezone}"),
                        onTap: () {
                          Picker picker = new Picker(
                              adapter: PickerDataAdapter<String>(
                                  pickerdata: timezones),
                              onConfirm: (Picker picker, List value) {
                                mutableSettings.timezone = timezones[value[0]];
                                setState(() {});
                              },
                              backgroundColor: Colors.transparent,
                              textStyle:
                                  TextStyle(color: Colors.white, fontSize: 18),
                              title: Text("Change the timezone"),
                              hideHeader: true,
                              looping: false);
                          picker.showDialog(context);
                        },
                      ),
                      if (originalSettings.brightness != null)
                        ExpansionTile(
                            leading: Icon(Icons.brightness_6),
                            title: Text("Set Brightness"),
                            children: <Widget>[
                              CupertinoSegmentedControl(
                                children: getBrightnessWidgets(),
                                padding: EdgeInsets.all(10),
                                unselectedColor:
                                    Theme.of(context).backgroundColor,
                                selectedColor: Colors.white,
                                borderColor: Colors.white,
                                onValueChanged: (int val) {
                                  setState(() {
                                    brightnessSelect = val;
                                    mutableSettings.brightness =
                                        brightnesSelectionToBrightness(
                                            brightnessSelect);
                                  });
                                },
                                groupValue: brightnessSelect,
                              )
                            ]),
                      ExpansionTile(
                        leading: Icon(Icons.info),
                        title: Text("About"),
                        children: <Widget>[
                          ListTile(
                              leading: Icon(Icons.tv),
                              title: FutureBuilder(future: () async {
                                AppState state = await AppState.load();
                                String ip = state
                                    .scoreboardAddresses[state.activeIndex];
                                return Channel(ipAddress: ip).getVersion();
                              }(), builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  if (snapshot.hasData) {
                                    return Text(
                                        "Scoreboard Version: ${snapshot.data}");
                                  } else {
                                    return Text(
                                        "Failed to fetch scoreboard version");
                                  }
                                } else {
                                  return Text("Fetching scoreboard version...");
                                }
                              })),
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
                                badgeContent: Text("1",
                                    style: TextStyle(color: Colors.white)),
                              )
                            : Icon(Icons.power_settings_new),
                        title: Text("Reboot this scoreboard"),
                        subtitle:
                            Text("Scoreboard will check for updates on reboot"),
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
                                  child: Text("Update"),
                                  onPressed: () async {
                                    AppState state = await AppState.load();
                                    String ip = state
                                        .scoreboardAddresses[state.activeIndex];
                                    print("Rebooting at ip : $ip");
                                    try {
                                      await Channel(ipAddress: ip)
                                          .rebootRequest();
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
                  ))),
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

  void showAddTeamDialog(Map<int, Map<int, Team>> teamMaps) {
    var leagues = [
      "Hockey",
      "Baseball",
      "College Basketball",
      "Basketball",
      "Football",
      "College Football"
    ];
    Picker picker = new Picker(
        adapter: PickerDataAdapter<String>(pickerdata: leagues),
        onConfirm: (Picker picker, List value) {
          int screenId = value[0];
          List<Team> displayData = [];
          for (int teamId in teamMaps[screenId].keys) {
            if (!mutableSettings.focusTeams
                .contains(FocusTeam(screenId: screenId, teamId: teamId))) {
              displayData.add(teamMaps[screenId][teamId]);
            }
          }
          displayData.sort();
          Picker picker = new Picker(
              adapter: PickerDataAdapter<Team>(pickerdata: displayData),
              onConfirm: (Picker picker, List value) {
                mutableSettings.focusTeams.add(FocusTeam(
                    screenId: screenId, teamId: displayData[value[0]].id));
                setState(() {});
              },
              backgroundColor: Colors.transparent,
              textStyle: TextStyle(color: Colors.white, fontSize: 18),
              title: Text("Add a favorite team"),
              hideHeader: true);
          picker.showDialog(context);
        },
        backgroundColor: Colors.transparent,
        textStyle: TextStyle(color: Colors.white, fontSize: 18),
        title: Text("Select a Sport"),
        hideHeader: true);
    picker.showDialog(context);
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
