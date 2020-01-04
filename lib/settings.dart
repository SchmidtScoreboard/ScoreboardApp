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
  @override
  void initState() {
    print("Initializing settings state");
    originalSettings = widget.settings.clone();
    mutableSettings = widget.settings.clone();

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
                        child: TextField(
                          decoration: InputDecoration(
                              icon: Icon(Icons.lock), labelText: "Password"),
                          maxLines: 1,
                          obscureText: true,
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
                      )),
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
                      title: Text("Made for Jamie"),
                      leading: Icon(Icons.favorite))
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
        return ListTile(
          title: Text("Scoreboard settings are corrupted"),
          subtitle:
              Text("Hold the poower button for 10 seconds to fully reset"),
        );
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
            trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  List<String> displayData = [];
                  List<int> teamIds = [];
                  for (int teamId in teamMap.keys) {
                    if (!screen.focusTeams.contains(teamId)) {
                      displayData.add(
                          teamMap[teamId].city + " " + teamMap[teamId].name);
                      teamIds.add(teamId);
                    }
                  }
                  Picker picker = new Picker(
                      adapter:
                          PickerDataAdapter<String>(pickerdata: displayData),
                      onConfirm: (Picker picker, List value) {
                        screen.focusTeams.add(teamIds[value[0]]);
                        setState(() {});
                      },
                      title: Text("Add a favorite team"),
                      hideHeader: true,
                      looping: true);
                  picker.showDialog(context);
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
  "Africa/Abidjan",
  "Africa/Accra",
  "Africa/Addis_Ababa",
  "Africa/Algiers",
  "Africa/Asmara",
  "Africa/Bamako",
  "Africa/Bangui",
  "Africa/Banjul",
  "Africa/Bissau",
  "Africa/Blantyre",
  "Africa/Brazzaville",
  "Africa/Bujumbura",
  "Africa/Cairo",
  "Africa/Casablanca",
  "Africa/Ceuta",
  "Africa/Conakry",
  "Africa/Dakar",
  "Africa/Dar_es_Salaam",
  "Africa/Djibouti",
  "Africa/Douala",
  "Africa/El_Aaiun",
  "Africa/Freetown",
  "Africa/Gaborone",
  "Africa/Harare",
  "Africa/Johannesburg",
  "Africa/Juba",
  "Africa/Kampala",
  "Africa/Khartoum",
  "Africa/Kigali",
  "Africa/Kinshasa",
  "Africa/Lagos",
  "Africa/Libreville",
  "Africa/Lome",
  "Africa/Luanda",
  "Africa/Lubumbashi",
  "Africa/Lusaka",
  "Africa/Malabo",
  "Africa/Maputo",
  "Africa/Maseru",
  "Africa/Mbabane",
  "Africa/Mogadishu",
  "Africa/Monrovia",
  "Africa/Nairobi",
  "Africa/Ndjamena",
  "Africa/Niamey",
  "Africa/Nouakchott",
  "Africa/Ouagadougou",
  "Africa/Porto-Novo",
  "Africa/Sao_Tome",
  "Africa/Tripoli",
  "Africa/Tunis",
  "Africa/Windhoek",
  "America/Adak",
  "America/Anchorage",
  "America/Anguilla",
  "America/Antigua",
  "America/Araguaina",
  "America/Argentina/Buenos_Aires",
  "America/Argentina/Catamarca",
  "America/Argentina/Cordoba",
  "America/Argentina/Jujuy",
  "America/Argentina/La_Rioja",
  "America/Argentina/Mendoza",
  "America/Argentina/Rio_Gallegos",
  "America/Argentina/Salta",
  "America/Argentina/San_Juan",
  "America/Argentina/San_Luis",
  "America/Argentina/Tucuman",
  "America/Argentina/Ushuaia",
  "America/Aruba",
  "America/Asuncion",
  "America/Atikokan",
  "America/Bahia",
  "America/Bahia_Banderas",
  "America/Barbados",
  "America/Belem",
  "America/Belize",
  "America/Blanc-Sablon",
  "America/Boa_Vista",
  "America/Bogota",
  "America/Boise",
  "America/Cambridge_Bay",
  "America/Campo_Grande",
  "America/Cancun",
  "America/Caracas",
  "America/Cayenne",
  "America/Cayman",
  "America/Chicago",
  "America/Chihuahua",
  "America/Costa_Rica",
  "America/Creston",
  "America/Cuiaba",
  "America/Curacao",
  "America/Danmarkshavn",
  "America/Dawson",
  "America/Dawson_Creek",
  "America/Denver",
  "America/Detroit",
  "America/Dominica",
  "America/Edmonton",
  "America/Eirunepe",
  "America/El_Salvador",
  "America/Fort_Nelson",
  "America/Fortaleza",
  "America/Glace_Bay",
  "America/Godthab",
  "America/Goose_Bay",
  "America/Grand_Turk",
  "America/Grenada",
  "America/Guadeloupe",
  "America/Guatemala",
  "America/Guayaquil",
  "America/Guyana",
  "America/Halifax",
  "America/Havana",
  "America/Hermosillo",
  "America/Indiana/Indianapolis",
  "America/Indiana/Knox",
  "America/Indiana/Marengo",
  "America/Indiana/Petersburg",
  "America/Indiana/Tell_City",
  "America/Indiana/Vevay",
  "America/Indiana/Vincennes",
  "America/Indiana/Winamac",
  "America/Inuvik",
  "America/Iqaluit",
  "America/Jamaica",
  "America/Juneau",
  "America/Kentucky/Louisville",
  "America/Kentucky/Monticello",
  "America/Kralendijk",
  "America/La_Paz",
  "America/Lima",
  "America/Los_Angeles",
  "America/Lower_Princes",
  "America/Maceio",
  "America/Managua",
  "America/Manaus",
  "America/Marigot",
  "America/Martinique",
  "America/Matamoros",
  "America/Mazatlan",
  "America/Menominee",
  "America/Merida",
  "America/Metlakatla",
  "America/Mexico_City",
  "America/Miquelon",
  "America/Moncton",
  "America/Monterrey",
  "America/Montevideo",
  "America/Montserrat",
  "America/Nassau",
  "America/New_York",
  "America/Nipigon",
  "America/Nome",
  "America/Noronha",
  "America/North_Dakota/Beulah",
  "America/North_Dakota/Center",
  "America/North_Dakota/New_Salem",
  "America/Ojinaga",
  "America/Panama",
  "America/Pangnirtung",
  "America/Paramaribo",
  "America/Phoenix",
  "America/Port-au-Prince",
  "America/Port_of_Spain",
  "America/Porto_Velho",
  "America/Puerto_Rico",
  "America/Punta_Arenas",
  "America/Rainy_River",
  "America/Rankin_Inlet",
  "America/Recife",
  "America/Regina",
  "America/Resolute",
  "America/Rio_Branco",
  "America/Santarem",
  "America/Santiago",
  "America/Santo_Domingo",
  "America/Sao_Paulo",
  "America/Scoresbysund",
  "America/Sitka",
  "America/St_Barthelemy",
  "America/St_Johns",
  "America/St_Kitts",
  "America/St_Lucia",
  "America/St_Thomas",
  "America/St_Vincent",
  "America/Swift_Current",
  "America/Tegucigalpa",
  "America/Thule",
  "America/Thunder_Bay",
  "America/Tijuana",
  "America/Toronto",
  "America/Tortola",
  "America/Vancouver",
  "America/Whitehorse",
  "America/Winnipeg",
  "America/Yakutat",
  "America/Yellowknife",
  "Antarctica/Casey",
  "Antarctica/Davis",
  "Antarctica/DumontDUrville",
  "Antarctica/Macquarie",
  "Antarctica/Mawson",
  "Antarctica/McMurdo",
  "Antarctica/Palmer",
  "Antarctica/Rothera",
  "Antarctica/Syowa",
  "Antarctica/Troll",
  "Antarctica/Vostok",
  "Arctic/Longyearbyen",
  "Asia/Aden",
  "Asia/Almaty",
  "Asia/Amman",
  "Asia/Anadyr",
  "Asia/Aqtau",
  "Asia/Aqtobe",
  "Asia/Ashgabat",
  "Asia/Atyrau",
  "Asia/Baghdad",
  "Asia/Bahrain",
  "Asia/Baku",
  "Asia/Bangkok",
  "Asia/Barnaul",
  "Asia/Beirut",
  "Asia/Bishkek",
  "Asia/Brunei",
  "Asia/Chita",
  "Asia/Choibalsan",
  "Asia/Colombo",
  "Asia/Damascus",
  "Asia/Dhaka",
  "Asia/Dili",
  "Asia/Dubai",
  "Asia/Dushanbe",
  "Asia/Famagusta",
  "Asia/Gaza",
  "Asia/Hebron",
  "Asia/Ho_Chi_Minh",
  "Asia/Hong_Kong",
  "Asia/Hovd",
  "Asia/Irkutsk",
  "Asia/Jakarta",
  "Asia/Jayapura",
  "Asia/Jerusalem",
  "Asia/Kabul",
  "Asia/Kamchatka",
  "Asia/Karachi",
  "Asia/Kathmandu",
  "Asia/Khandyga",
  "Asia/Kolkata",
  "Asia/Krasnoyarsk",
  "Asia/Kuala_Lumpur",
  "Asia/Kuching",
  "Asia/Kuwait",
  "Asia/Macau",
  "Asia/Magadan",
  "Asia/Makassar",
  "Asia/Manila",
  "Asia/Muscat",
  "Asia/Nicosia",
  "Asia/Novokuznetsk",
  "Asia/Novosibirsk",
  "Asia/Omsk",
  "Asia/Oral",
  "Asia/Phnom_Penh",
  "Asia/Pontianak",
  "Asia/Pyongyang",
  "Asia/Qatar",
  "Asia/Qostanay",
  "Asia/Qyzylorda",
  "Asia/Riyadh",
  "Asia/Sakhalin",
  "Asia/Samarkand",
  "Asia/Seoul",
  "Asia/Shanghai",
  "Asia/Singapore",
  "Asia/Srednekolymsk",
  "Asia/Taipei",
  "Asia/Tashkent",
  "Asia/Tbilisi",
  "Asia/Tehran",
  "Asia/Thimphu",
  "Asia/Tokyo",
  "Asia/Tomsk",
  "Asia/Ulaanbaatar",
  "Asia/Urumqi",
  "Asia/Ust-Nera",
  "Asia/Vientiane",
  "Asia/Vladivostok",
  "Asia/Yakutsk",
  "Asia/Yangon",
  "Asia/Yekaterinburg",
  "Asia/Yerevan",
  "Atlantic/Azores",
  "Atlantic/Bermuda",
  "Atlantic/Canary",
  "Atlantic/Cape_Verde",
  "Atlantic/Faroe",
  "Atlantic/Madeira",
  "Atlantic/Reykjavik",
  "Atlantic/South_Georgia",
  "Atlantic/St_Helena",
  "Atlantic/Stanley",
  "Australia/Adelaide",
  "Australia/Brisbane",
  "Australia/Broken_Hill",
  "Australia/Currie",
  "Australia/Darwin",
  "Australia/Eucla",
  "Australia/Hobart",
  "Australia/Lindeman",
  "Australia/Lord_Howe",
  "Australia/Melbourne",
  "Australia/Perth",
  "Australia/Sydney",
  "Canada/Atlantic",
  "Canada/Central",
  "Canada/Eastern",
  "Canada/Mountain",
  "Canada/Newfoundland",
  "Canada/Pacific",
  "Europe/Amsterdam",
  "Europe/Andorra",
  "Europe/Astrakhan",
  "Europe/Athens",
  "Europe/Belgrade",
  "Europe/Berlin",
  "Europe/Bratislava",
  "Europe/Brussels",
  "Europe/Bucharest",
  "Europe/Budapest",
  "Europe/Busingen",
  "Europe/Chisinau",
  "Europe/Copenhagen",
  "Europe/Dublin",
  "Europe/Gibraltar",
  "Europe/Guernsey",
  "Europe/Helsinki",
  "Europe/Isle_of_Man",
  "Europe/Istanbul",
  "Europe/Jersey",
  "Europe/Kaliningrad",
  "Europe/Kiev",
  "Europe/Kirov",
  "Europe/Lisbon",
  "Europe/Ljubljana",
  "Europe/London",
  "Europe/Luxembourg",
  "Europe/Madrid",
  "Europe/Malta",
  "Europe/Mariehamn",
  "Europe/Minsk",
  "Europe/Monaco",
  "Europe/Moscow",
  "Europe/Oslo",
  "Europe/Paris",
  "Europe/Podgorica",
  "Europe/Prague",
  "Europe/Riga",
  "Europe/Rome",
  "Europe/Samara",
  "Europe/San_Marino",
  "Europe/Sarajevo",
  "Europe/Saratov",
  "Europe/Simferopol",
  "Europe/Skopje",
  "Europe/Sofia",
  "Europe/Stockholm",
  "Europe/Tallinn",
  "Europe/Tirane",
  "Europe/Ulyanovsk",
  "Europe/Uzhgorod",
  "Europe/Vaduz",
  "Europe/Vatican",
  "Europe/Vienna",
  "Europe/Vilnius",
  "Europe/Volgograd",
  "Europe/Warsaw",
  "Europe/Zagreb",
  "Europe/Zaporozhye",
  "Europe/Zurich",
  "GMT",
  "Indian/Antananarivo",
  "Indian/Chagos",
  "Indian/Christmas",
  "Indian/Cocos",
  "Indian/Comoro",
  "Indian/Kerguelen",
  "Indian/Mahe",
  "Indian/Maldives",
  "Indian/Mauritius",
  "Indian/Mayotte",
  "Indian/Reunion",
  "Pacific/Apia",
  "Pacific/Auckland",
  "Pacific/Bougainville",
  "Pacific/Chatham",
  "Pacific/Chuuk",
  "Pacific/Easter",
  "Pacific/Efate",
  "Pacific/Enderbury",
  "Pacific/Fakaofo",
  "Pacific/Fiji",
  "Pacific/Funafuti",
  "Pacific/Galapagos",
  "Pacific/Gambier",
  "Pacific/Guadalcanal",
  "Pacific/Guam",
  "Pacific/Honolulu",
  "Pacific/Kiritimati",
  "Pacific/Kosrae",
  "Pacific/Kwajalein",
  "Pacific/Majuro",
  "Pacific/Marquesas",
  "Pacific/Midway",
  "Pacific/Nauru",
  "Pacific/Niue",
  "Pacific/Norfolk",
  "Pacific/Noumea",
  "Pacific/Pago_Pago",
  "Pacific/Palau",
  "Pacific/Pitcairn",
  "Pacific/Pohnpei",
  "Pacific/Port_Moresby",
  "Pacific/Rarotonga",
  "Pacific/Saipan",
  "Pacific/Tahiti",
  "Pacific/Tarawa",
  "Pacific/Tongatapu",
  "Pacific/Wake",
  "Pacific/Wallis",
  "US/Alaska",
  "US/Arizona",
  "US/Central",
  "US/Eastern",
  "US/Hawaii",
  "US/Mountain",
  "US/Pacific",
  "UTC"
];
