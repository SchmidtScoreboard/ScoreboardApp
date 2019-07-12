import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'onboarding.dart';
import 'homepage.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.orangeAccent,
        brightness: Brightness.light,
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
