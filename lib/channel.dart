import 'dart:async';
import 'dart:ffi';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Channel {
  String ipAddress;
  Channel({required this.ipAddress});

  static final Channel localChannel =
      Channel(ipAddress: "http://127.0.0.1:5005/");
  static final Channel personalLaptopChannel =
      Channel(ipAddress: "http://192.168.4.30:5005/");
  static final Channel testingChannel =
      Channel(ipAddress: "http://192.168.0.197:5005/");
  static final Channel hotspotChannel =
      Channel(ipAddress: "http://42.42.42.1:5005/");
  // localChannel;
  // personalLaptopChannel;

  // String root = 'http://192.168.0.197:5005/';
  // String root = "http://127.0.0.1:5005/";

  Future<ScoreboardSettings> configRequest() async {
    Uri url = Uri.parse(ipAddress);
    final response = await http.get(url).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      ScoreboardSettings newScoreboard =
          ScoreboardSettings.fromJson(json.decode(response.body));
      await AppState.setName(newScoreboard.name);
      return newScoreboard;
    } else {
      throw Exception("Failed to load scoreboard settings");
    }
  }

  Future<ScoreboardSettings> sportRequest(int id) async {
    Uri url = Uri.parse(ipAddress + "setSport");

    Map data = {'sport': id};
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: body);
    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send sport request");
    }
  }

  Future<ScoreboardSettings> gameAction() async {
    Uri url = Uri.parse(ipAddress + "gameAction");

    Map data = {};
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: body);
    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send sport request");
    }
  }

  Future<ScoreboardSettings> configureSettings(
      ScoreboardSettings newSettings) async {
    Uri url = Uri.parse(ipAddress + "configure");
    print("Sending scoreboard: ${newSettings.toJson()}");
    var body = json.encode(newSettings.toJson());

    var response = await http
        .post(url, headers: {"Content-Type": "application/json"}, body: body)
        .timeout(Duration(seconds: 10));
    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send configuration");
    }
  }

  Future<ScoreboardSettings> powerRequest(bool power) async {
    Uri url = Uri.parse(ipAddress + "setPower");

    Map data = {'screen_on': power};
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http
        .post(url, headers: {"Content-Type": "application/json"}, body: body)
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send power request");
    }
  }

  Future<ScoreboardSettings> autoPowerRequest(bool autoPower) async {
    Uri url = Uri.parse(ipAddress + "autoPower");

    Map data = {'auto_power': autoPower};
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http
        .post(url, headers: {"Content-Type": "application/json"}, body: body)
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send auto power request");
    }
  }

  Future<ScoreboardSettings> wifiRequest(String ssid, String password) async {
    Uri url = Uri.parse(ipAddress + "wifi");
    Map data = {'ssid': ssid, 'psk': password};
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: body);
    if (response.statusCode == 200) {
      print(response.body);
      return ScoreboardSettings.fromJson(json.decode(response.body));
    }
    if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception("Failed to connect to scoreboard");
    }
  }

  Future<ScoreboardSettings> syncRequest() async {
    Uri url = Uri.parse(ipAddress + "sync");

    print("Attempting to sync at $url");

    var response = await http.post(url).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to send sync request");
    }
  }

  Future<ScoreboardSettings> connectRequest() async {
    Uri url = Uri.parse(ipAddress + "connect");
    print("Attempting to connect at $url");
    final response = await http.post(url).timeout(Duration(seconds: 10));
    if (response.statusCode == 200) {
      print(response.body);
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to connect to scoreboard");
    }
  }

  Future<ScoreboardSettings> rebootRequest() async {
    Uri url = Uri.parse(ipAddress + "reboot");
    final response = await http.post(url).timeout(Duration(seconds: 10));
    if (response.statusCode == 200) {
      print(response.body);
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to connect to scoreboard");
    }
  }

  Future<String> getVersion() async {
    Uri url = Uri.parse(ipAddress + "version");
    final response = await http.get(url).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("Failed to load version");
    }
  }

  Future<CustomMessage> getCustomMessage() async {
    Uri url = Uri.parse(ipAddress + "getCustomMessage");
    final response = await http.get(url).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      var message = CustomMessage.fromJson(json.decode(response.body));
      return message;
    } else {
      print("Failed to parse");
      throw Exception("Failed to get custom message");
    }
  }

  Future<void> setCustomMessage(CustomMessage message) async {
    Uri url = Uri.parse(ipAddress + "setCustomMessage");
    var body = json.encode(message.toJson());

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: body);

    if (response.statusCode != 202) {
      print(response.statusCode);
      throw Exception("Failed to set custom message");
    }
  }
}
