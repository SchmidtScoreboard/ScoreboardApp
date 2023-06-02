import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'channel.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:convert/convert.dart';

class ScreenId {
  static const NHL = 0;
  static const MLB = 1;
  static const COLLEGE_BASKETBALL = 2;
  static const BASKETBALL = 3;
  static const FOOTBALL = 4;
  static const COLLEGE_FOOTBALL = 5;
  static const GOLF = 6;
  static const CLOCK = 50;
  static const REFRESH = 100;
  static const HOTSPOT = 101;
  static const WIFIDETAILS = 102;
  static const FLAPPY = 420;
  static const CUSTOM_MESSAGE = 421;
  static const SYNC = 103;
  static const SMART = 10000;

  static String getEmoji(int value) {
    switch (value) {
      case ScreenId.NHL:
        return "🏒";
      case ScreenId.MLB:
        return "⚾️";
      case ScreenId.BASKETBALL:
      case ScreenId.COLLEGE_BASKETBALL:
        return "🏀";
      case ScreenId.FOOTBALL:
      case ScreenId.COLLEGE_FOOTBALL:
        return "🏈";
      case ScreenId.GOLF:
        return "⛳️";
      default:
        return "❌";
    }
  }
}

class FocusTeam {
  int screenId;
  int teamId;
  FocusTeam({required this.screenId, required this.teamId});
  factory FocusTeam.fromJson(Map<String, dynamic> json) {
    return FocusTeam(screenId: json["screen_id"], teamId: json['team_id']);
  }
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FocusTeam &&
        this.screenId == other.screenId &&
        this.teamId == other.teamId;
  }

  FocusTeam clone() {
    return new FocusTeam(screenId: screenId, teamId: teamId);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {};
    ret["screen_id"] = screenId;
    ret["team_id"] = teamId;
    return ret;
  }
}

class Screen {
  Screen(
      {required this.id,
      required this.name,
      required this.subtitle,
      this.alwaysRotate = false,
      this.rotationTime = 0,
      this.focusTeams = const []});
  int id;
  String name;
  String subtitle;

  bool alwaysRotate;
  int rotationTime;
  List<int> focusTeams;

  factory Screen.fromJson(Map<String, dynamic> json) {
    return Screen(
        id: json["id"],
        name: json['name'],
        subtitle: json['subtitle'],
        alwaysRotate: json['always_rotate'],
        rotationTime: json['rotation_time'],
        focusTeams: new List<int>.from(json['focus_teams']));
  }

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Screen &&
        this.id == other.id &&
        this.name == other.name &&
        this.subtitle == other.subtitle &&
        this.alwaysRotate == other.alwaysRotate &&
        this.rotationTime == other.rotationTime &&
        listEquals(this.focusTeams, other.focusTeams);
  }

  Screen clone() {
    List<int> focus = [];
    for (int i in focusTeams) {
      focus.add(i);
    }
    return new Screen(
        alwaysRotate: alwaysRotate,
        id: id,
        name: name,
        rotationTime: rotationTime,
        subtitle: subtitle,
        focusTeams: focus);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {};
    ret["id"] = id;
    ret["name"] = name;
    ret["subtitle"] = subtitle;
    ret["always_rotate"] = alwaysRotate;
    ret["rotation_time"] = rotationTime;
    ret["focus_teams"] = focusTeams;
    return ret;
  }

  IconData getIcon() {
    switch (id) {
      case ScreenId.NHL:
        return FontAwesomeIcons.hockeyPuck;
      case ScreenId.MLB:
        return FontAwesomeIcons.baseballBall;
      case ScreenId.COLLEGE_BASKETBALL:
        return FontAwesomeIcons.basketballBall;
      case ScreenId.BASKETBALL:
        return FontAwesomeIcons.basketballBall;
      case ScreenId.COLLEGE_FOOTBALL:
        return FontAwesomeIcons.footballBall;
      case ScreenId.FOOTBALL:
        return FontAwesomeIcons.footballBall;
      case ScreenId.GOLF:
        return FontAwesomeIcons.golfBall;
      case ScreenId.CLOCK:
        return FontAwesomeIcons.clock;
      case ScreenId.FLAPPY:
        return Icons.play_arrow;
      case ScreenId.SMART:
        return FontAwesomeIcons.magic;
      case ScreenId.CUSTOM_MESSAGE:
        return Icons.chat_bubble;
      default:
        return FontAwesomeIcons.mandalorian;
    }
  }
}

enum AutoPowerMode { Off, Clock, CustomMessage }

String autoPowerModeToString(AutoPowerMode mode) {
  switch (mode) {
    case AutoPowerMode.Off:
      return "Off";
    case AutoPowerMode.Clock:
      return "Clock";
    case AutoPowerMode.CustomMessage:
      return "CustomMessage";
  }
}

AutoPowerMode autoPowerModeFromString(String str) {
  switch (str) {
    case "Off":
      return AutoPowerMode.Off;
    case "Clock":
      return AutoPowerMode.Clock;
    case "CustomMessage":
      return AutoPowerMode.CustomMessage;
    default:
      return AutoPowerMode.Off;
  }
}

class ScoreboardSettings {
  static final int clientVersion = 7;

  int activeScreen;
  bool screenOn;
  bool autoPowerOn;
  List<Screen> screens;
  int setupState;
  String name;
  int version;
  String timezone;
  String macAddress;
  bool alwaysRotate = false;
  int rotationTime;
  List<FocusTeam> focusTeams;
  int brightness;
  AutoPowerMode autoPowerMode;

  ScoreboardSettings(
      {required this.activeScreen,
      required this.screenOn,
      required this.autoPowerOn,
      required this.name,
      required this.screens,
      required this.setupState,
      required this.version,
      required this.timezone,
      required this.macAddress,
      required this.rotationTime,
      required this.focusTeams,
      required this.brightness,
      required this.autoPowerMode});

  factory ScoreboardSettings.fromJson(Map<String, dynamic> json) {
    List<Screen> screens = [];
    for (var screen in json["screens"]) {
      screens.add(Screen.fromJson(screen));
    }

    List<FocusTeam> focusTeams = [];
    if (json["favorite_teams"] != null) {
      for (var team in json["favorite_teams"]) {
        focusTeams.add(FocusTeam.fromJson(team));
      }
    }

    return ScoreboardSettings(
        activeScreen: json["active_screen"],
        screenOn: json["screen_on"],
        autoPowerOn: json["auto_power"] ?? false,
        name: json["name"] ?? "My New Scoreboard",
        screens: screens,
        setupState: json["setup_state"],
        version: json["version"],
        timezone: json["timezone"],
        macAddress: json["mac_address"] ?? "00:00:00:00:00:00",
        rotationTime: json['rotation_time'] ?? 10,
        focusTeams: focusTeams,
        brightness: json['brightness'] ?? HIGH_BRIGHTNESS,
        autoPowerMode:
            autoPowerModeFromString(json['auto_power_mode'] ?? "Off"));
  }

  ScoreboardSettings clone() {
    List<Screen> screensCopy = [];
    for (Screen s in screens) {
      screensCopy.add(s.clone());
    }
    List<FocusTeam> focus = [];
    for (FocusTeam i in focusTeams) {
      focus.add(i.clone());
    }
    return new ScoreboardSettings(
        activeScreen: activeScreen,
        screenOn: screenOn,
        autoPowerOn: autoPowerOn,
        name: name,
        version: version,
        screens: new List<Screen>.from(screensCopy),
        setupState: setupState,
        timezone: timezone,
        macAddress: macAddress,
        rotationTime: rotationTime,
        focusTeams: focus,
        brightness: brightness,
        autoPowerMode: autoPowerMode);
  }

  bool clientNeedsUpdate() {
    return this.version > ScoreboardSettings.clientVersion;
  }

  bool scoreboardNeedsUpdate() {
    return this.version < ScoreboardSettings.clientVersion;
  }

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ScoreboardSettings &&
        this.activeScreen == other.activeScreen &&
        this.screenOn == other.screenOn &&
        this.autoPowerOn == other.autoPowerOn &&
        this.name == other.name &&
        this.timezone == other.timezone &&
        this.macAddress == other.macAddress &&
        listEquals(this.screens, other.screens) &&
        this.rotationTime == other.rotationTime &&
        listEquals(this.focusTeams, other.focusTeams) &&
        this.brightness == other.brightness &&
        this.autoPowerMode == other.autoPowerMode;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {};
    ret["active_screen"] = activeScreen;
    ret["auto_power"] = autoPowerOn;
    ret["screen_on"] = screenOn;
    ret["screens"] = [];
    ret["setup_state"] = setupState;
    ret["name"] = name;
    ret["version"] = version;
    ret["timezone"] = timezone;
    for (Screen s in screens) {
      ret["screens"].add(s.toJson());
    }
    ret["mac_address"] = macAddress;
    ret["rotation_time"] = rotationTime;
    ret["favorite_teams"] = focusTeams;
    ret["brightness"] = brightness;
    ret["auto_power_mode"] = autoPowerModeToString(autoPowerMode);
    return ret;
  }
}

const LOW_BRIGHTNESS = 25;
const MID_BRIGHTNESS = 50;
const HIGH_BRIGHTNESS = 75;
const MAX_BRIGHTNESS = 100;

// Scoreboard uses Diffie-Hellman Key Exchange of ~500 digit keys
class VerificationKey {
  late BigInt secret;

  static BigInt p = BigInt.parse("23");
  static BigInt g = BigInt.parse("5"); // Primitive root modulo of p
  static const DIGITS = 2;

  VerificationKey(String s) {
    this.secret = BigInt.parse(s);
  }

  VerificationKey.internal(BigInt bigInt) {
    this.secret = bigInt;
  }
  static VerificationKey generate() {
    String value = "";
    Random random = Random.secure();
    for (var i = 0; i < DIGITS; i++) {
      // There are way better ways to do this
      value += random.nextInt(10).toString();
    }
    return VerificationKey(value);
  }

  // Converts an arbitrary string message to base64, then to bigint
  static BigInt stringToBigInt(String message) {
    var bytes = utf8.encode(message);
    var hexString = hex.encode(bytes);
    return BigInt.parse(hexString, radix: 16);
  }

  // Returns hex string signed using this key
  String encrypt(String message) {
    BigInt messageInt = stringToBigInt(message);
    return (secret * messageInt).toRadixString(16);
  }

  String decrypt(String encryptedMessage) {
    BigInt messageInt = BigInt.parse(encryptedMessage, radix: 16);
    BigInt decryptedInt = messageInt ~/ secret;
    List<int> hexValues = hex.decode(decryptedInt.toRadixString(16));
    return utf8.decode(hexValues);
  }

  BigInt getPublicKey() {
    return g.modPow(secret, p);
  }

  VerificationKey getSharedSecret(BigInt exchangedPublicKey) {
    return VerificationKey.internal(exchangedPublicKey.modPow(secret, p));
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
  late List<String> scoreboardAddresses;
  late List<SetupState> scoreboardSetupStates;
  late List<String> scoreboardNames;
  late int activeIndex;
  late int policyVersion;

  static const String ADDRESS_KEY = "addresses";
  static const String SETUP_STATE_KEY = "setup_states";
  static const String LAST_INDEX_KEY = "last_index";
  static const String POLICY_VERSION = "policy_version";
  static const String NAMES_KEY = "names";

  static const int CURRENT_POLICY_VERSION = 1;
  static const String POLICY_TEXT =
      "Schmidt Scoreboard does not collect or sell personal information of any kind.\n\nIt may collect Scoreboard usage information purely for internal use and feature selection, but it will never collect your wifi information or any other private information.\n\nScoreboard offers several modes to display scores from various leagues. Any of these modes may be removed at any time.";

  static AppState? _singleton;

  AppState._internal();
  AppState._default() {
    scoreboardAddresses = [""];
    scoreboardNames = ["My Scoreboard"];
    scoreboardSetupStates = [SetupState.FACTORY];
    activeIndex = 0;
    policyVersion = 0;
  }

  static void resetState(AppState state) {
    state.scoreboardAddresses = [""];
    state.scoreboardNames = ["My Scoreboard"];
    state.scoreboardSetupStates = [SetupState.FACTORY];
    state.activeIndex = 0;
    state.policyVersion = 0;
  }

  static Future<AppState> load() async {
    if (_singleton != null) {
      return _singleton!;
    } else {
      _singleton = AppState._internal();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        _singleton!.scoreboardAddresses = prefs.getStringList(ADDRESS_KEY)!;
        _singleton!.scoreboardSetupStates = prefs
            .getStringList(SETUP_STATE_KEY)!
            .map((s) => SetupState.values[int.parse(s)])
            .toList();
        _singleton!.scoreboardNames = prefs.getStringList(NAMES_KEY)!;
        _singleton!.activeIndex = prefs.getInt(LAST_INDEX_KEY)!;
        _singleton!.policyVersion = prefs.getInt(POLICY_VERSION) ?? 0;
        if (_singleton!.scoreboardAddresses.length !=
                _singleton!.scoreboardSetupStates.length ||
            _singleton!.scoreboardNames.length !=
                _singleton!.scoreboardAddresses.length) {
          throw Exception("Invalid addresses, setup states, or names");
        } else if (_singleton!.activeIndex >=
                _singleton!.scoreboardAddresses.length ||
            _singleton!.activeIndex < 0) {
          throw Exception("Invalid last index");
        }
        return _singleton!;
      } catch (e) {
        //invalid string lists, set everything to basic values and return. This is an OK state if nothing has been done
        _singleton = AppState._internal();
        resetState(_singleton!);

        return _singleton!;
      }
    }
  }

  static Future store() async {
    if (_singleton == null) {
      throw Exception("Cannot store null AppState");
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList(ADDRESS_KEY, _singleton!.scoreboardAddresses);
      prefs.setStringList(
          SETUP_STATE_KEY,
          _singleton!.scoreboardSetupStates
              .map((state) => state.index.toString())
              .toList());
      prefs.setStringList(NAMES_KEY, _singleton!.scoreboardNames);
      prefs.setInt(LAST_INDEX_KEY, _singleton!.activeIndex);
      prefs.setInt(POLICY_VERSION, _singleton!.policyVersion);
    }
  }

  static Future setState(SetupState state) async {
    AppState app = await AppState.load();
    app.scoreboardSetupStates[app.activeIndex] = state;
    await AppState.store();
  }

  static Future setName(String name) async {
    AppState app = await AppState.load();
    app.scoreboardNames[app.activeIndex] = name;
    await AppState.store();
  }

  static Future setAddress(String address) async {
    AppState app = await AppState.load();
    app.scoreboardAddresses[app.activeIndex] = address;
    await AppState.store();
  }

  static Future setActive(int index) async {
    AppState app = await AppState.load();
    app.activeIndex = index;
    await AppState.store();
  }

  static Future setPolicyVersion(int version) async {
    AppState app = await AppState.load();
    app.policyVersion = version;
    await AppState.store();
  }

  static Future addScoreboard() async {
    AppState app = await AppState.load();
    bool foundMyScoreboard = false;
    String name = "My Scoreboard";
    for (String name in app.scoreboardNames) {
      if (name.startsWith("My Scoreboard")) {
        foundMyScoreboard = true;
        break;
      }
    }
    if (foundMyScoreboard) {
      //Find the highest numbered one
      int number = 1;
      for (String name in app.scoreboardNames) {
        RegExp exp = new RegExp(r"^My Scoreboard\s([0-9]+)");
        List<Match> matches = exp.allMatches(name).toList();
        if (matches.length > 0) {
          Match m = matches[0];
          if (m.groupCount == 1 && m.group(1) != null) {
            int candidate = int.tryParse(m.group(1)!) ?? 0;
            if (candidate > number) {
              number = candidate;
            }
          }
        }
      }
      name = "My Scoreboard ${number + 1}";
    }

    app.scoreboardAddresses.add("");
    app.scoreboardNames.add(name);
    app.scoreboardSetupStates.add(SetupState.FACTORY);
    app.activeIndex = app.scoreboardNames.length - 1;
    await AppState.store();
  }

  static Future removeScoreboard({int? index}) async {
    AppState app = await AppState.load();
    if (index == null) {
      index = app.activeIndex;
    }
    app.scoreboardAddresses.removeAt(index);
    app.scoreboardNames.removeAt(index);
    app.scoreboardSetupStates.removeAt(index);
    app.activeIndex = 0;

    if (app.scoreboardAddresses.length == 0) {
      //Add a new default scoreboard so we don't crash
      resetState(app);
    }
    await AppState.store();
  }

  static Future<Channel> getChannel() async {
    AppState app = await AppState.load();
    return Channel(ipAddress: app.scoreboardAddresses[app.activeIndex]);
  }
}

String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

String ipFromCode(String code) {
  String out = "";
  RegExp regex = RegExp("..");
  for (RegExpMatch match in regex.allMatches(code)) {
    String matched = match.group(0)!;
    int mod = alphabet.indexOf(matched[0]);
    int rem = alphabet.indexOf(matched[1]);
    int octet = alphabet.length * mod + rem;
    out += octet.toString() + ".";
  }
  return out.substring(0, out.length - 1);
}

bool isValidIpCode(String candidate) {
  RegExp regex = RegExp("[A-Z][A-Z][A-Z][A-Z][A-Z][A-Z][A-Z][A-Z]");
  return regex.hasMatch(candidate);
}

enum FontSize { Small, Medium, Large }

class CustomMessageLine {
  String text;
  FontSize size;
  Color color;

  CustomMessageLine(
      {required this.text, required this.size, required this.color});
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CustomMessageLine &&
        text == other.text &&
        size == other.size &&
        color == other.color;
  }

  Map<String, dynamic> toJson() {
    String colorStr = "";
    colorStr += color.red.toRadixString(16).padLeft(2, '0');
    colorStr += color.green.toRadixString(16).padLeft(2, '0');
    colorStr += color.blue.toRadixString(16).padLeft(2, '0');

    Map<String, dynamic> ret = {};
    ret["text"] = text;
    ret["size"] = size == FontSize.Large
        ? "Large"
        : size == FontSize.Medium
            ? "Medium"
            : "Small";
    ret["color"] = colorStr;
    return ret;
  }

  factory CustomMessageLine.fromJson(Map<String, dynamic> json) {
    String colorStr = "FF" + json["color"];
    int hex = int.parse(colorStr, radix: 16);

    FontSize size = FontSize.Small;
    String fontStr = json["size"];
    if (fontStr == "Medium") {
      size = FontSize.Medium;
    } else if (fontStr == "Large") {
      size = FontSize.Large;
    }

    return CustomMessageLine(color: Color(hex), size: size, text: json["text"]);
  }

  CustomMessageLine clone() {
    return CustomMessageLine(
        color: this.color, size: this.size, text: this.text);
  }
}

class Pixels {
  List<List<Color>> data;

  Pixels({required this.data});
  bool operator ==(other) {
    // return listEquals(this.data, other.data);
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (other is Pixels) {
      for (int x = 0; x < 64; x++) {
        for (int y = 0; y < 32; y++) {
          if (other.data[y][x] != data[y][x]) {
            return false;
          }
        }
      }
      return true;
    } else {
      return false;
    }
  }

  List<List<Uint8List>> toJson() {
    List<List<Uint8List>> out = [];
    for (List<Color> row in data) {
      List<Uint8List> outRow = [];
      for (Color pixel in row) {
        var pixelOut = new Uint8List(3);
        pixelOut[0] = pixel.red;
        pixelOut[1] = pixel.green;
        pixelOut[2] = pixel.blue;
        outRow.add(pixelOut);
      }
      out.add(outRow);
    }
    return out;
  }

  Pixels clone() {
    List<List<Color>> dataCopy = [];
    for (var row in this.data) {
      List<Color> outRow = [];
      for (var pixel in row) {
        outRow.add(pixel);
      }
      dataCopy.add(outRow);
    }
    return Pixels(data: dataCopy);
  }

  Uint8List getImageBytes() {
    StringBuffer bytes = StringBuffer();
    bytes.writeln("P3");
    bytes.writeln("256 128");
    bytes.writeln("255");
    var numPixels = 0;
    for (var row in this.data) {
      for (int j = 0; j < 4; j++) {
        for (var pixel in row) {
          bytes.writeln("${pixel.red} ${pixel.green} ${pixel.blue}");
          bytes.writeln("${pixel.red} ${pixel.green} ${pixel.blue}");
          bytes.writeln("${pixel.red} ${pixel.green} ${pixel.blue}");
          bytes.writeln("${pixel.red} ${pixel.green} ${pixel.blue}");
          numPixels += 4;
        }
      }
    }
    while (numPixels < (64 * 4 * 32 * 4)) {
      bytes.writeln("0 0 0");
      numPixels++;
    }
    String out = bytes.toString();
    return Uint8List.fromList(out.codeUnits);
  }
}

class CustomMessage {
  List<CustomMessageLine> lines;
  Pixels background;

  CustomMessage({required this.lines, required this.background});

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (other is CustomMessage) {
      return listEquals(this.lines, other.lines) &&
          background == other.background;
    } else {
      return false;
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {};
    ret["background"] = background.toJson();

    ret["texts"] = [];
    for (CustomMessageLine line in lines) {
      ret["texts"].add(line.toJson());
    }
    return ret;
  }

  factory CustomMessage.fromJson(Map<String, dynamic> json) {
    List<CustomMessageLine> lines = [];
    for (var line in json["texts"]) {
      lines.add(CustomMessageLine.fromJson(line));
    }

    List<List<Color>> data = [];
    for (var row in json["background"]) {
      List<Color> outRow = [];
      for (var pixel in row) {
        Color pix = new Color.fromARGB(255, pixel[0], pixel[1], pixel[2]);
        outRow.add(pix);
      }
      data.add(outRow);
    }

    return CustomMessage(background: Pixels(data: data), lines: lines);
  }

  CustomMessage clone() {
    List<CustomMessageLine> linesCopy = [];
    for (var line in lines) {
      linesCopy.add(line.clone());
    }
    return CustomMessage(background: background.clone(), lines: linesCopy);
  }
}
