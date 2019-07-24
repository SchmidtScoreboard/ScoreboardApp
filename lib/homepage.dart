
import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';
import 'onboarding.dart';
import 'dart:math';

Widget buildHome() {
  return FutureBuilder(
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
          int lastIndex = max(appState.activeIndex, 0);
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
  );
}
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, }) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScoreboardSettings settings;
  Timer refreshTimer;
  Channel channel;
  bool refreshingScreenSelect;
  bool refreshingPower;
  @override
  void initState() async {
    super.initState();
    channel = await AppState.getChannel();
    refreshingPower = false;
    refreshingScreenSelect = false;
    refreshTimer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      setState(() {
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScoreboardSettings>(
      future: Channel.localChannel.configRequest(),
      builder: (context, snapshot) {
        Widget body;
        List<Widget> actions;
        Widget fab;
        Widget drawer;
        if (snapshot.hasData) {
          settings = snapshot.data;
          body = _buildHome();
          actions = _buildActions();      
          fab = _buildFab();
          drawer = _buildDrawer();
          
        } else if (snapshot.hasError) {
          body = ListView(
            children: <Widget>[
              Card(
                child:
                  ListTile(
                    leading: Icon(Icons.error),
                    title: Text("Could not connect to scoreboard"),
                    subtitle: Text("Make sure it is powered and connected to wifi"),
                  )
                ),
              Card(
                child: 
                  ListTile(
                    leading: Icon(Icons.sync),
                    title: Text("If scoreboard is working normally.."),
                    subtitle: Text("Click the side button on the scoreboard to enter sync mode, then tap here to synchronize"),
                    onTap: () async {
                      await AppState.setState(SetupState.SYNC);
                      setState(() {
                        //disable the timer
                        refreshTimer.cancel();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => buildHome())
                        );
                      });

                    },
                  )
                ,
              ),
              Card(
                child: 
                  ListTile(
                    leading: Icon(Icons.refresh),
                    title: Text("If scoreboard is showing an error..."),
                    subtitle: Text("Hold down the side button on the scoreboard for ten seconds to fully reset. Then, tap here to reset"),
                    onTap: () async {
                      await AppState.setState(SetupState.FACTORY);
                      setState(() {
                        //disable the timer
                        refreshTimer.cancel();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => buildHome())
                        );
                      });
                    },
                  )
                ,
              )
            ]
          );
          drawer = _buildDrawer();
        } else {
          body = Center(
            child: CircularProgressIndicator());
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: actions,
          ), body: body,
          floatingActionButton: fab,
          drawer: drawer,

        );
      }
    );
  }

  Widget _buildDrawer() {
    return FutureBuilder(
      future: AppState.load(),
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          AppState state = snapshot.data;
          return Drawer(
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text("Scoreboard 1"),
                  
                ), ListTile(
                  title: Text("Scoreboard 2")
                )
                

              ],
            ),
          );
        } else {
          return Text("Loading");
        }

      });
  }

  List<Widget> _buildActions() {
    return <Widget> [
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
    ];
  }

  Widget _buildFab() {
    return FloatingActionButton(
        onPressed: () {
          setState(() {
            settings.screenOn = !(settings.screenOn);
            refreshingPower = true;
          });
          Future<ScoreboardSettings> responseFuture = Channel.localChannel.powerRequest(!settings.screenOn);
          responseFuture.then((ScoreboardSettings newSettings) {
            setState(() { 
              settings = newSettings;
              refreshingPower = false;
            });
          }).catchError((e) {
            print("Something went wrong :(");
          });
        },
        child: refreshingPower ? 
          CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),) :
          Icon(Icons.power_settings_new, color: Colors.white,),
        backgroundColor: settings.screenOn ? Theme.of(context).accentColor : Colors.grey,
        foregroundColor: Colors.white,
      );
  }

  Widget _buildHome() {
      return Container(
        child: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: settings.screens.length,
          itemBuilder: (context, i) {
            return _buildRow(settings.screens[i]);
          },
        ),
      );
  }

  Widget _buildRow(Screen screen) {
    return new Card( 
      color: screen.id == settings.activeScreen && settings.screenOn ? Theme.of(context).accentColor : Colors.grey,
      
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () { 
          if(screen.id != settings.activeScreen) {
            setState(() {
              print("Selecting");
              settings.activeScreen = screen.id;
              settings.screenOn = true;
              refreshingScreenSelect = true;
            });
            Future<ScoreboardSettings> responseFuture = Channel.localChannel.sportRequest(screen.id);
            responseFuture.then((ScoreboardSettings newSettings) {
              setState(() {
                print("Done select");
                settings = newSettings; 
                refreshingScreenSelect = false;
              }); 
            }).catchError((e) { 
                print("Something went wrong :(");
            });
          }
          
        },
        child: Column(children: <Widget>[
          ListTile(
            leading: screen.id == settings.activeScreen && refreshingScreenSelect ? 
              CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),) :
              Icon(Icons.album, color: Colors.white,),
            title: Text(screen.name,
            style: TextStyle(fontSize: 24, color: Colors.white),),
            subtitle: Text(screen.subtitle, style: TextStyle(color: Colors.white)),
          ),
        ],)
      ),
    );
  }
}