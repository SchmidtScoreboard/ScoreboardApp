
import 'dart:async';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class Channel {
  static final Channel _singleton = new Channel._internal();
  factory Channel() {
    if(_singleton == null) {
      Channel c = _singleton;
    }
    return _singleton;
  }
  Channel._internal();

  // String root = 'http://192.168.0.197:5005/';
  // String root = "http://127.0.0.1:5005/";

  Future<ScoreboardSettings> configRequest(ScoreboardSettings set, [String root]) async {
    if(set != null ) {
      return set;
    }
    String url = root != null ? root : await getRoot();
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load post");
    }
  }
  Future<ScoreboardSettings> sportRequest (ScreenId id) async {
    var url = await getRoot() + "setSport";

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
      return ScoreboardSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load post");
    }
  }

  Future<ScoreboardSettings> powerRequest (bool power) async {
    var url = await getRoot() + "setPower";

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
      throw Exception("Failed to load post");
    }
  }
}