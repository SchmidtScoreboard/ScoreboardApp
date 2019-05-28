
import 'package:http/http.dart' as http;
import 'dart:convert';
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

Future<ScoreboardSettings> configRequest(ScoreboardSettings set) async {
  if(set != null ) {
    return set;
  }
  // var url = 'http://192.168.0.197:5005/';
  var url = "http://127.0.0.1:5005/";
  final response = await http.get(url);
  if (response.statusCode == 200) {
    print(response.body);
   return ScoreboardSettings.fromJson(json.decode(response.body));
  } else {
    throw Exception("Failed to load post");
  }
}
Future<ScoreboardSettings> sportRequest (ScreenId id) async {
  // var url ='http://192.168.0.197:5005/setSport';
  var url = "http://127.0.0.1:5005/setSport";

  Map data = {
    'sport': id.index
  };
  //encode Map to JSON
  var body = json.encode(data);

  var response = await http.post(url,
      headers: {"Content-Type": "application/json"},
      body: body
  );
  if (response.statusCode == 200) {
    print(response.body);
   return ScoreboardSettings.fromJson(json.decode(response.body));
  } else {
    throw Exception("Failed to load post");
  }
}

Future<ScoreboardSettings> powerRequest (bool power) async {
  // var url ='http://192.168.elf.197:5005/setPower';
  var url = "http://127.0.0.1:5005/setPower";

  Map data = {
    'screen_on': power
  };
  //encode Map to JSON
  var body = json.encode(data);

  var response = await http.post(url,
      headers: {"Content-Type": "application/json"},
      body: body
  );

  if (response.statusCode == 200) {
    print(response.body);
   return ScoreboardSettings.fromJson(json.decode(response.body));
  } else {
    throw Exception("Failed to load post");
  }
}