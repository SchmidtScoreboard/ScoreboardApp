
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
enum ScreenId { nhl, mlb }

class Screen {

  Screen({this.id, this.name, this.subtitle, this.alwaysRotate, this.rotationTime});
  ScreenId id;
  String name;
  String subtitle;

  bool alwaysRotate;
  int rotationTime;
  //list of favorite team IDs

  factory Screen.fromJson(Map<String, dynamic> json) {
    return Screen(id: ScreenId.values[json["id"]],
      name: json['name'],
      subtitle: json['subtitle'],
      alwaysRotate: json['always_rotate'],
      rotationTime: json['rotation_time']);
  }
}

class ScoreboardSettings {
  ScreenId activeScreen;
  bool screenOn;
  List<Screen> screens;

  ScoreboardSettings({this.activeScreen, this.screenOn, this.screens});

  factory ScoreboardSettings.fromJson(Map<String, dynamic> json) {
    List<Screen> screens = [];
    for (var screen in json["screens"]) {
      screens.add(Screen.fromJson(screen));
    }
    return ScoreboardSettings(activeScreen: ScreenId.values[json["active_screen"]],
      screenOn: json["screen_on"],
      screens: screens); 
  }
}

  // var root = 'http://192.168.0.197:5005/';
  var root = "http://127.0.0.1:5005/";
Future<String> getRoot() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  String address = prefs.getString("scoreboardAddress");
  if(address == null) {
    return "";
  } else {
    return address;
  }

}