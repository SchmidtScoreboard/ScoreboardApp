import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreboard',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran:"flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'My Scoreboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _settingsClicked() {
    setState(() {
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget> [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _settingsClicked,
          ),
        ],
      ),
      body: ScoreboardScreens(),
    );
  }
}

class ScoreboardScreens extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ScoreboardScreensState();
  }
}

Future<ScoreboardSettings> configRequest() async {
  var url = 'http://192.168.0.197:5005/';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    print(json.decode(response.body));
   return ScoreboardSettings.fromJson(json.decode(response.body));
  } else {
    throw Exception("Failed to load post");
  }
}
Future<http.Response> sportRequest (ScreenId id) async {
  var url ='http://192.168.0.197:5005/setSport';

  Map data = {
    'sport': id.index
  };
  //encode Map to JSON
  var body = json.encode(data);

  var response = await http.post(url,
      headers: {"Content-Type": "application/json"},
      body: body
  );
  print("${response.statusCode}");
  print("${response.body}");
  return response;
}
class ScoreboardScreensState extends State<ScoreboardScreens> {

  ScreenId activeScreen; 

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScoreboardSettings>(
      future: configRequest(),
      builder: (context, snapshot) {
      if (snapshot.hasData) {
        return _fillScreens(snapshot.data);
      } else if (snapshot.hasError) {
        return Text(snapshot.error.toString());
      }

      return CircularProgressIndicator();
    }
    );
  }

  Widget _fillScreens(ScoreboardSettings settings) {
    activeScreen = settings.activeScreen;
    return new ListView.builder(
      padding: const EdgeInsets.all(10.0),
      itemCount: settings.screens.length,
      itemBuilder: (context, i) {

        return _buildRow(settings.screens[i]);
      },
    );
  }

  Widget _buildRow(Screen screen) {
    return new Card( 
      color: screen.id == activeScreen? Colors.white : Colors.grey,
      
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () { 
          // if(screen.id != activeScreen) {
            setState(() {
              sportRequest(screen.id);
              activeScreen = screen.id;
            });
          // }
        },
        child: Column(children: <Widget>[
          ListTile(
            leading: Icon(Icons.album),
            title: Text(screen.name,
            style: TextStyle(fontSize: 24),),
            subtitle: Text(screen.subtitle),
          ),
        ],)
      ),
    );
  }
}
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
  List<Screen> screens;

  ScoreboardSettings({this.activeScreen, this.screens});

  factory ScoreboardSettings.fromJson(Map<String, dynamic> json) {
    List<Screen> screens = [];
    for (var screen in json["screens"]) {
      screens.add(Screen.fromJson(screen));
    }
    return ScoreboardSettings(activeScreen: ScreenId.values[json["active_screen"]],
      screens: screens); 
  }
}
