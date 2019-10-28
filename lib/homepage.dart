import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';
import 'onboarding.dart';
import 'dart:math';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ScoreboardDrawer extends StatefulWidget {
  final Function cleanup;
  ScoreboardDrawer({Key key, this.cleanup}) : super(key: key);

  @override
  _ScoreboardDrawerState createState() => _ScoreboardDrawerState();
}

class _ScoreboardDrawerState extends State<ScoreboardDrawer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: AppState.load(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            AppState state = snapshot.data;
            return Drawer(
                child: Column(
              children: <Widget>[
                DrawerHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'My Scoreboards',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: ListView(
                        shrinkWrap: true,
                        children:
                            _buildDrawerList(state, widget.cleanup, context))),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: SafeArea(
                      child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text(
                      "Add a new scoreboard",
                    ),
                    onTap: () async {
                      await AppState.addScoreboard();
                      widget.cleanup();
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => buildHome()));
                    },
                  )),
                )
              ],
            ));
          } else {
            return Text("Loading");
          }
        });
  }

  List<Widget> _buildDrawerList(
      AppState state, Function cleanup, BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < state.scoreboardAddresses.length; i++) {
      widgets.add(Slidable(
        key: ValueKey(i),
        child: ListTile(
            title: Text(
              state.scoreboardNames[i],
              style: i == state.activeIndex
                  ? TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
            onTap: () async {
              await AppState.setActive(i);
              cleanup();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => buildHome()));
            }),
        actionPane: SlidableDrawerActionPane(),
        secondaryActions: <Widget>[
          IconSlideAction(
            icon: Icons.delete,
            color: Colors.red,
            onTap: () async {
              //show alert dialog

              AlertDialog alert = AlertDialog(
                title: Text("Are you sure?"),
                content: Text(
                    "This action will only delete the saved settings from the app. To fully reset it, hold the side button on the scoreboard for ten seconds."),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () async {
                      await AppState.removeScoreboard(index: i);
                      Navigator.of(context).pop();
                      setState(() {});
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => buildHome()));
                    },
                  )
                ],
              );
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return alert;
                  });
            },
          )
        ],
      ));
    }
    return widgets;
  }
}

Widget buildHome() {
  return FutureBuilder(
    future: AppState.load(),
    builder: (BuildContext context, AsyncSnapshot snapshot) {
      if (snapshot.hasData) {
        print("Got snapshot data");
        AppState appState = snapshot.data;
        int numScoreboards = appState.scoreboardAddresses.length;

        if (numScoreboards == 0) {
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
              return SyncScreen();
            case SetupState.READY:
              print("Got setup state READY");
              return MyHomePage();
            default:
              print("Error reading scoreboard setup state: $setupState");
              return MyHomePage();
          }
        }
      } else if (snapshot.hasError) {
        print(snapshot.error);
        return Text("Error :(");
      } else {
        return Scaffold(
          appBar: AppBar(
            title: Text("Waiting on storage"),
          ),
        );
      }
    },
  );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key key,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScoreboardSettings settings;
  Timer refreshTimer;
  Channel channel;
  bool refreshingScreenSelect;
  bool refreshingPower;
  bool shouldRefreshConfig = true;
  @override
  void initState() {
    super.initState();
    //channel = await AppState.getChannel();
    refreshingPower = false;
    refreshingScreenSelect = false;
    refreshTimer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      setState(() {
        shouldRefreshConfig = true;
      });
    });
  }

  Future<ScoreboardSettings> getConfig() async {
    if (shouldRefreshConfig && !refreshingPower && !refreshingScreenSelect) {
      AppState state = await AppState.load();
      String ip = state.scoreboardAddresses[state.activeIndex];
      print("Querying scoreboard at address: $ip");
      return Channel(ipAddress: ip).configRequest();
    } else {
      return Future.value(settings);
    }
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    shouldRefreshConfig = true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScoreboardSettings>(
        future: getConfig(),
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
            drawer = ScoreboardDrawer(cleanup: () {
              refreshTimer.cancel();
            });
            shouldRefreshConfig = false;
          } else if (snapshot.hasError) {
            print(snapshot.error);
            body = ListView(children: <Widget>[
              Card(
                  child: ListTile(
                leading: Icon(Icons.error),
                title: Text("Could not connect to scoreboard"),
                subtitle: Text("Make sure it is powered and connected to wifi"),
              )),
              Card(
                child: ListTile(
                  leading: Icon(Icons.sync),
                  title: Text("If scoreboard is working normally.."),
                  subtitle: Text(
                      "Double click the side button on the scoreboard to enter sync mode, then tap here to synchronize"),
                  onTap: () async {
                    await AppState.setState(SetupState.SYNC);
                    setState(() {
                      //disable the timer
                      refreshTimer.cancel();
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => buildHome()));
                    });
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text("If scoreboard is showing an error..."),
                  subtitle: Text(
                      "Hold down the side button on the scoreboard for ten seconds to fully reset. Then, tap here to reset"),
                  onTap: () async {
                    await AppState.setState(SetupState.FACTORY);
                    setState(() {
                      //disable the timer
                      refreshTimer.cancel();
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => buildHome()));
                    });
                  },
                ),
              )
            ]);
            drawer = ScoreboardDrawer(cleanup: () {
              refreshTimer.cancel();
            });
            shouldRefreshConfig = false;
          } else {
            body = Center(child: CircularProgressIndicator());
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(settings != null ? settings.name : "Loading"),
              actions: actions,
            ),
            body: body,
            floatingActionButton: fab,
            drawer: drawer,
          );
        });
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
          icon: Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            shouldRefreshConfig = true;
            refreshTimer.cancel();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsScreen(settings: settings)));
          }),
    ];
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () async {
        setState(() {
          refreshingPower = true;
        });
        AppState state = await AppState.load();
        String ip = state.scoreboardAddresses[state.activeIndex];
        print("Querying scoreboard at address: $ip");
        ScoreboardSettings newSettings = await
            Channel(ipAddress: ip).powerRequest(!settings.screenOn);
        setState(() {
          settings = newSettings;
          refreshingPower = false;
        });
      
      },
      child: refreshingPower
          ? CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Icon(
              Icons.power_settings_new,
              color: Colors.white,
            ),
      backgroundColor:
          settings.screenOn ? Theme.of(context).accentColor : Colors.grey,
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
      color: screen.id == settings.activeScreen && settings.screenOn
          ? Theme.of(context).accentColor
          : Colors.grey,
      child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () async {
            if (screen.id != settings.activeScreen) {
              setState(() {
                print("Selecting");
                settings.activeScreen = screen.id;
                settings.screenOn = true;
                refreshingScreenSelect = true;
              });
            }
            AppState state = await AppState.load();
            String ip = state.scoreboardAddresses[state.activeIndex];
            print("Querying scoreboard at address: $ip");
            ScoreboardSettings newSettings = await
                Channel(ipAddress: ip).sportRequest(screen.id);
            setState(() {
              print("Done select");
              settings = newSettings;
              refreshingScreenSelect = false;
            });
          },
          child: Column(
            children: <Widget>[
              ListTile(
                leading:
                    screen.id == settings.activeScreen && refreshingScreenSelect
                        ? CircularProgressIndicator(
                            valueColor:
                                new AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Icon(
                            screen.getIcon(),
                            color: Colors.white,
                            size: 40,
                          ),
                title: Text(
                  screen.name,
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                subtitle: Text(screen.subtitle,
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          )),
    );
  }
}
