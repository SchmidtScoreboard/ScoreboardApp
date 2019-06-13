import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';
import 'onboarding.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.orangeAccent,
        brightness: Brightness.dark
      ),
      home: FutureBuilder(
        future: AppState.load(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if(snapshot.hasData) {
            print("Got snapshot data");
            AppState appState = snapshot.data;
            int numScoreboards = appState.scoreboardAddresses.length;

            if(numScoreboards == 0) {
              // Go to onboarding
              print("No scoreboards, going to onboarding");
              return SplashScreen();
            } else {
              int lastIndex = max(appState.lastScoreboardIndex, 0);
              SetupState setupState = appState.scoreboardSetupStates[lastIndex];
              switch (setupState) {
                case SetupState.FACTORY:
                  print("Got setup state FACTORY");
                  return SplashScreen(); 
                case SetupState.HOTSPOT:
                  print("Got setup state HOTSPOT");
                  return ConnectToHotspotScreen();
                case SetupState.WIFI_CONNECT:
                  print("Got setup state WIFI_CONNECT");
                  return WifiCredentialsScreen();
                case SetupState.SYNC:
                  print("Got setup state SYNC");
                  return ScanQRCodeScreen();
                case SetupState.READY:
                  print("Got setup state READY");
                  return MyHomePage(title: "My Scoreboard");
                default:
                  print("Error reading scoreboard setup state: $setupState");
                  return MyHomePage(title: "My Scoreboard");
              }
            }
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Text("Error :(");
          } else {
            return Scaffold(appBar: AppBar(
              title: Text("Waiting on storage"),
              ),
            );
          }
        },
      ),
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
  ScoreboardSettings settings;
  Timer refreshTimer;
  Channel channel;
  @override
  void initState() {
    super.initState();
    channel = new Channel();
    refreshTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        settings = null;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScoreboardSettings>(
      future: channel.configRequest(settings),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          settings = snapshot.data;
          return _buildHome();
        } else if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(
            title: Text(widget.title),
            ),
            body: ListView(
              children: <Widget>[
                Card(
                  child: Column(children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.error),
                      title: Text("Could not connect to scoreboard"),
                      subtitle: Text("Make sure it is powered and connected to wifi"),
                    ),
                  ],))
              ]
            )
              
          );

        } else {
          return Scaffold(appBar: AppBar(
            title: Text(widget.title),
            ),
            body: Center(
              child: CircularProgressIndicator()),
          );
        }
      }
    );
  }

  Widget _buildHome() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget> [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () { 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen(settings: settings))
              );
            }
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: settings.screens.length,
        itemBuilder: (context, i) {
          return _buildRow(settings.screens[i]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Future<ScoreboardSettings> responseFuture = channel.powerRequest(!settings.screenOn);
          responseFuture.then((ScoreboardSettings newSettings) {
            setState(() { settings = newSettings;});
          }).catchError((e) {
            print("Something went wrong :(");
          });
        },
        child: Icon(Icons.power_settings_new),
        backgroundColor: settings.screenOn ? Theme.of(context).primaryColor : Colors.grey,
      ),
    );
  }

  Widget _buildRow(Screen screen) {
    return new Card( 
      color: screen.id == settings.activeScreen && settings.screenOn ? Colors.white : Colors.grey,
      
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () { 
          if(screen.id != settings.activeScreen) {
            Future<ScoreboardSettings> responseFuture = channel.sportRequest(screen.id);
            responseFuture.then((ScoreboardSettings newSettings) {
              setState(() {settings = newSettings; }); 
            }).catchError((e) { 
                print("Something went wrong :(");
            });
          }
          
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