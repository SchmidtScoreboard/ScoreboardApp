
import 'dart:async';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class Channel {
  String ipAddress;
  Channel({this.ipAddress});

  static final Channel hotspotChannel = Channel(ipAddress: "http://192.168.4.1:5005/");
  // static final Channel localChannel = Channel(ipAddress: "http://127.0.0.1:5005/");
  static final Channel localChannel = Channel(ipAddress: "http://192.168.0.197:5005/");

  // String root = 'http://192.168.0.197:5005/';
  // String root = "http://127.0.0.1:5005/";

  Future<ScoreboardSettings> configRequest() async {
    final response = await http.get(ipAddress);
    if (response.statusCode == 200) {
      ScoreboardSettings newScoreboard = ScoreboardSettings.fromJson(json.decode(response.body));
      await AppState.setName(newScoreboard.name);
      return newScoreboard;
    } else {
      throw Exception("Failed to load scoreboard settings");
    }
  }
  Future<ScoreboardSettings> sportRequest (int id) async {
    var url = ipAddress + "setSport";

    Map data = {
      'sport': id
    };
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: body
    );
    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send sport request");
    }
  }

  Future<ScoreboardSettings> configureSettings (ScoreboardSettings newSettings) async {
    var url = ipAddress + "configure";
    //TODO implement toJson in scoreboard settings
    
    var body = json.encode(newSettings.toJson());

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: body
    );
    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send configuration");
    }
 }

  Future<ScoreboardSettings> powerRequest (bool power) async {
    var url = ipAddress + "setPower";

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
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send power request");
    }
  }
  Future<ScoreboardSettings> wifiRequest(String ssid, String password) async {
    String url = ipAddress + "wifi";
    Map data = {
      'ssid' : ssid,
      'psk' : password
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
      throw Exception("Failed to connect to scoreboard");
    }
  }
  Future<ScoreboardSettings> syncRequest() async {
    var url = ipAddress + "sync";

    //encode Map to JSON

    var response = await http.post(url);

    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send sync request");
    }
  }
  Future<ScoreboardSettings> connectRequest() async {
    String url = ipAddress + "connect";
    final response = await http.post(url);
    if (response.statusCode == 200) {
      print(response.body);
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to connect to scoreboard");
    }
  }
}
