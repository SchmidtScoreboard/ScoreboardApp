import 'package:Scoreboard/teams.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';
import 'onboarding.dart';
import 'dart:math';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:badges/badges.dart';

class ScoreboardDrawer extends StatefulWidget {
  ScoreboardDrawer({Key key}) : super(key: key);

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
                      Text(
                        'If you own multiple Schmidt Scoreboards, use this menu to swap between them',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: ListView(
                        shrinkWrap: true,
                        children: _buildDrawerList(state, context))),
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

  List<Widget> _buildDrawerList(AppState state, BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < state.scoreboardAddresses.length; i++) {
      widgets.add(ClipRect(
          child: Slidable(
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
      )));
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
        return Text("Internal Error");
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
  bool refreshingScreenSelect = false;
  bool refreshingPower = false;
  bool shouldRefreshConfig = true;
  bool scoreboardUpdateAvailable = false;

  List<Screen> proScreens = [
    Screen(
        id: ScreenId.NHL,
        name: "Hockey",
        subtitle: "Show scores from professional hockey"),
    Screen(
        id: ScreenId.MLB,
        name: "Baseball",
        subtitle: "Show scores from professional baseball"),
    Screen(
        id: ScreenId.BASKETBALL,
        name: "Basketball",
        subtitle: "Show scores from professional basketball"),
  ];

  List<Screen> collegeScreens = [
    Screen(
        id: ScreenId.COLLEGE_BASKETBALL,
        name: "College Basketball",
        subtitle: "Show scores from college basketball"),
  ];

  List<Screen> otherScreens = [
    Screen(
        id: ScreenId.CLOCK, name: "Clock", subtitle: "Show the current time"),
    // Screen(
    //     id: ScreenId.SMART,
    //     name: "Smart Switch",
    //     subtitle:
    //         "Automatically switch between leagues when your favorite teams are playing")
  ];
  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<ScoreboardSettings> getConfig() async {
    if (shouldRefreshConfig && !refreshingPower && !refreshingScreenSelect) {
      AppState state = await AppState.load();
      String ip = state.scoreboardAddresses[state.activeIndex];
      print("Getting config from scoreboard at address: $ip");
      return Channel(ipAddress: ip).configRequest();
    } else {
      return Future.value(settings);
    }
  }

  @override
  void dispose() {
    if (refreshTimer != null && refreshTimer.isActive) {
      refreshTimer.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    shouldRefreshConfig = true;
    super.didUpdateWidget(oldWidget);
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
          String name;
          if (snapshot.hasData) {
            print("Got config data");
            if (refreshTimer == null || !refreshTimer.isActive) {
              refreshTimer = Timer.periodic(Duration(seconds: 10), (Timer t) {
                setState(() {
                  shouldRefreshConfig = true;
                });
              });
            }
            settings = snapshot.data;
            name = settings.name;
            body = _buildHome();
            actions = _buildActions();
            fab = _buildFab();
            drawer = ScoreboardDrawer();
            shouldRefreshConfig = false;
          } else if (snapshot.hasError) {
            print("Got config error " + snapshot.error.toString());
            name = "Sync Error";
            body = ListView(padding: EdgeInsets.all(10), children: <Widget>[
              Card(
                  color: Colors.red[300],
                  child: Padding(
                      padding: EdgeInsets.all(10),
                      child: ListTile(
                        // leading: Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: <Widget>[Icon(Icons.error)]),
                        title: Text("Could not connect to your scoreboard"),
                        subtitle: Text(
                            "Make sure your scoreboard is plugged in and your device is connected to the same WiFi network"),
                      ))),
              Card(
                color: Colors.red[300],
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: ListTile(
                      // leading: Column(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: <Widget>[Icon(Icons.sync)]),
                      title: Text("If scoreboard is working normally.."),
                      subtitle: Text(
                          "Double click the side button on the scoreboard to enter sync mode, then tap here to synchronize"),
                      onTap: () async {
                        await AppState.setState(SetupState.SYNC);
                        setState(() {
                          //disable the timer
                          refreshTimer.cancel();
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => buildHome()));
                        });
                      },
                    )),
              ),
              Card(
                color: Colors.red[300],
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: ListTile(
                      // leading: Column(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: <Widget>[Icon(Icons.refresh)]),
                      title: Text("If scoreboard is showing an error..."),
                      subtitle: Text(
                          "Hold down the side button on the scoreboard for ten seconds to fully reset. Then, tap here to redo setup"),
                      onTap: () async {
                        await AppState.setState(SetupState.FACTORY);
                        setState(() {
                          //disable the timer
                          refreshTimer.cancel();
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => buildHome()));
                        });
                      },
                    )),
              )
            ]);
            if (refreshTimer == null || !refreshTimer.isActive) {
              refreshTimer = Timer.periodic(Duration(seconds: 10), (Timer t) {
                setState(() {
                  shouldRefreshConfig = true;
                });
              });
            }
            drawer = ScoreboardDrawer();
            shouldRefreshConfig = false;
          } else {
            name = "Loading";
            body = Center(child: CircularProgressIndicator());
            drawer = ScoreboardDrawer();
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(name),
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
          icon: settings.scoreboardNeedsUpdate()
              ? Badge(
                  child: Icon(Icons.settings),
                  badgeContent:
                      Text("1", style: TextStyle(color: Colors.white)),
                )
              : Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            shouldRefreshConfig = true;
            refreshTimer.cancel();
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SettingsScreen(settings: settings)))
                .then((value) => setState(() => {}));
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
        print("Setting power for scoreboard at address: $ip");
        ScoreboardSettings newSettings =
            await Channel(ipAddress: ip).powerRequest(!settings.screenOn);
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

  Widget getTable(List<Screen> screens) {
    List<Widget> items = screens.map((screen) => getScreen(screen)).toList();
    return GridView.count(
      shrinkWrap: true,
      primary: false,
      children: items,
      crossAxisCount: 2,
      childAspectRatio: 5 / 4,
    );
  }

  Widget getScreen(Screen screen) {
    return new Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
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
          print("Setting sport for scoreboard at address: $ip");
          ScoreboardSettings newSettings =
              await Channel(ipAddress: ip).sportRequest(screen.id);
          setState(() {
            print("Done select");
            settings = newSettings;
            refreshingScreenSelect = false;
          });
        },
        child: screen.id == settings.activeScreen && refreshingScreenSelect
            ? CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Icon(
                screen.getIcon(),
                color: Colors.white,
                size: 100,
              ),
      ),
    );
  }

  Widget getCategoryText(String text) {
    return Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Text(text, style: TextStyle(fontSize: 20)));
  }

  Widget _buildHome() {
    return Container(
        child: ListView(
      shrinkWrap: true,
      children: [
        Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: getCategoryText("Professional")),
        getTable(proScreens),
        getCategoryText("College"),
        getTable(collegeScreens),
        getCategoryText("Other"),
        getTable(otherScreens),
      ],
    ));
  }

  void _checkVersion() async {
    AlertDialog alert;
    try {
      settings = await getConfig();
    } catch (e) {
      return;
      // Do nothing
    }
    if (settings.clientNeedsUpdate()) {
      alert = AlertDialog(
          title: Text("Update this App!"),
          content: Text(
              "You are using an outdated version of the Scoreboard app.\nPlease update it in the App Store to get the latest features and bug fixes"),
          actions: [
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    } else if (settings.scoreboardNeedsUpdate()) {
      alert = AlertDialog(
          title: Text("Update your scoreboard!"),
          content: Text("There is an update available for your scoreboard."),
          actions: [
            FlatButton(
              child: Text("Later"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("Reboot"),
              onPressed: () async {
                AppState state = await AppState.load();
                String ip = state.scoreboardAddresses[state.activeIndex];
                print("Rebooting at ip : $ip");
                try {
                  await Channel(ipAddress: ip).rebootRequest();
                } catch (e) {
                  print(e.toString());
                } finally {
                  Navigator.of(context).pop();
                }
              },
            )
          ]);
    }
    if (alert != null) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          });
    }
  }
}
