
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ScreenId { 
  static const NHL = 0;
  static const MLB = 1; 
  static const REFRESH = 100;
  static const HOTSPOT = 101;
  static const WIFIDETAILS = 102;
  static const QR = 103;
}

class Screen {

  Screen({this.id, this.name, this.subtitle, this.alwaysRotate, this.rotationTime});
  int id;
  String name;
  String subtitle;

  bool alwaysRotate;
  int rotationTime;
  //list of favorite team IDs

  factory Screen.fromJson(Map<String, dynamic> json) {
    return Screen(id: json["id"],
      name: json['name'],
      subtitle: json['subtitle'],
      alwaysRotate: json['always_rotate'],
      rotationTime: json['rotation_time']);
  }
}

class ScoreboardSettings {
  int activeScreen;
  bool screenOn;
  List<Screen> screens;

  ScoreboardSettings({this.activeScreen, this.screenOn, this.screens});

  factory ScoreboardSettings.fromJson(Map<String, dynamic> json) {
    List<Screen> screens = [];
    for (var screen in json["screens"]) {
      screens.add(Screen.fromJson(screen));
    }
    return ScoreboardSettings(activeScreen: json["active_screen"],
      screenOn: json["screen_on"],
      screens: screens); 
  }
}

enum SetupState {
  FACTORY,
  HOTSPOT,
  WIFI_CONNECT,
  SYNC,
  READY,
}

class AppState {
  List<String> scoreboardAddresses;
  List<SetupState> scoreboardSetupStates;
  int lastScoreboardIndex;

  static const String ADDRESS_KEY = "addresses";
  static const String SETUP_STATE_KEY = "setup_states";
  static const String LAST_INDEX_KEY = "last_index";


  static AppState _singleton;

  AppState._internal();
  
  static Future<AppState> load() async {
    if(_singleton != null) {
      return _singleton;
    } else {
      _singleton = AppState._internal();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        _singleton.scoreboardAddresses = prefs.getStringList(ADDRESS_KEY);
        _singleton.scoreboardSetupStates = prefs.getStringList(SETUP_STATE_KEY).map((s) => SetupState.values[int.parse(s)]).toList();
        _singleton.lastScoreboardIndex = prefs.getInt(LAST_INDEX_KEY);
      } catch (e) {
        //invalid string lists, set everything to basic values and return. This is an OK state if nothing has been done
        print(e);
        _singleton = AppState._internal();
        _singleton.scoreboardAddresses = [""];
        _singleton.scoreboardSetupStates = [SetupState.FACTORY];
        _singleton.lastScoreboardIndex = 0;

        return _singleton;
      }
      if(_singleton.scoreboardAddresses.length != _singleton.scoreboardSetupStates.length) {
        throw Exception("Invalid addresses and setup states");
      } else if (_singleton.lastScoreboardIndex >= _singleton.scoreboardAddresses.length) {
        throw Exception("Invalid last index");
      }
      return _singleton;
    }
  }

  static Future store() async {
    print("Storing app state");
    if(_singleton == null) {
      throw Exception("Cannot store null AppState");
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList(ADDRESS_KEY, _singleton.scoreboardAddresses);
      prefs.setStringList(SETUP_STATE_KEY, _singleton.scoreboardSetupStates.map((state) => state.index.toString()).toList());
      prefs.setInt(LAST_INDEX_KEY, _singleton.lastScoreboardIndex);
    }
  }

}

  var root = 'http://192.168.0.197:5005/';
 // var root = "http://127.0.0.1:5005/";
// Future<String> getRoot() async {
//   final SharedPreferences prefs = await SharedPreferences.getInstance();

//   String address = prefs.getString("scoreboardAddress");
//   if(address == null) {
//     return "";
//   } else {
//     return address;
//   }

// }