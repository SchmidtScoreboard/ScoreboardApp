import 'package:Scoreboard/teams.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';
import 'onboarding.dart';
import 'dart:math';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:badges/badges.dart';

const REFRESH_FAILURES_BEFORE_SHOW_ERROR = 24;

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
  bool refreshingAutoPower = false;
  bool shouldRefreshConfig = true;
  bool scoreboardUpdateAvailable = false;
  int refreshFailures = 0;
  Future doneSetup;

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
    Screen(
        id: ScreenId.FOOTBALL,
        name: "Football",
        subtitle: "Show scores from professional football"),
    Screen(
        id: ScreenId.GOLF,
        name: "Golf",
        subtitle: "Show scores from professional golf"),
  ];

  List<Screen> collegeScreens = [
    Screen(
        id: ScreenId.COLLEGE_BASKETBALL,
        name: "College Basketball",
        subtitle: "Show scores from college basketball"),
    Screen(
        id: ScreenId.COLLEGE_FOOTBALL,
        name: "College Football",
        subtitle: "Show scores from college football"),
  ];

  List<Screen> otherScreens = [
    Screen(
        id: ScreenId.CLOCK, name: "Clock", subtitle: "Show the current time"),
    Screen(id: ScreenId.FLAPPY, name: "Game", subtitle: "Let's play a game"),
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
      shouldRefreshConfig = false;
      return Channel(ipAddress: ip).configRequest();
    } else {
      print("Returning existing settings");
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

  Widget getErrorTile(String title, String subtitle, IconData icon) {
    return Container(
        width: 500,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
        ));
  }

  Widget getErrorButton(String text, Function() callback) {
    return Padding(
        child: ElevatedButton(
            child: Text(text),
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18.0))),
                primary: Theme.of(context).accentColor),
            onPressed: callback),
        padding: EdgeInsets.only(bottom: 10.0));
  }

  void showBottomSheet(BuildContext context, bool loading) {
    showMaterialModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: SafeArea(
            child: Column(
          children: [
            Container(
                width: 500,
                child: ListTile(
                    leading: Icon(Icons.cancel),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    title: Text("Troubleshooting",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)))),
            Container(height: 30),
            // Stack(children: [
            //   Center(
            //       child: Padding(
            //           padding: EdgeInsets.all(20),
            //           child: Text("Troubleshooting",
            //               style: TextStyle(fontSize: 24)))),
            //   Padding(
            //       padding: EdgeInsets.all(10),
            //       child: IconButton(
            //           icon: Icon(Icons.cancel),
            //           onPressed: () {
            //             Navigator.pop(context);
            //           })),
            // ])),
            getErrorTile(
                "Power",
                "If your scoreboard is showing no content, it may not have power. Ensure it is fully plugged in--there should be a red light from the left side of the Scoreboard. Then, tap refresh and wait for your Scoreboard to power on.",
                FontAwesomeIcons.plug),
            getErrorButton("Refresh", () {
              setState(() {
                refreshFailures = 0;
                shouldRefreshConfig = true;
              });
              Navigator.pop(context);
            }),
            getErrorTile(
                "Sync",
                "If your scoreboard is showing content and appears connected, you are likely not connected to the correct WiFi network. Go to your device's Settings to ensure it is connected to the same WiFi network you used to set up this Scoreboard. Then, tap Refresh above.\n\n"
                    "If that is unsuccessful, you need to resync the app. Quickly double press the Scoreboard's side button--you should see a sync code appear. Then, tap the Sync button below to re-syncronize.",
                FontAwesomeIcons.sync),
            getErrorButton("Sync", () async {
              Navigator.pop(context);
              await AppState.setState(SetupState.SYNC);
              setState(() {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => buildHome()));
              });
            }),
            getErrorTile(
                "Reset",
                "If your Scoreboard is displaying an error, it may be experiencing an issue that requires a simple reboot. Unplug your Scoreboard and plug it back in, then wait 2 minutes for it to start back up.\n\nIf the error persists after a reboot, hold down the side button on the Scoreboard for 10 seconds, then release. It should display a \"Resetting\" message. Then, tap Reset below to restart the Scoreboard setup process.",
                FontAwesomeIcons.sync),
            getErrorButton("Reset", () async {
              Navigator.pop(context);
              await AppState.setState(SetupState.FACTORY);
              setState(() {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => buildHome()));
              });
            }),
          ],
        )),
      ),
    );
  }

  ButtonStyle getButtonStyle(BuildContext context, bool left) {
    const borderRadius = Radius.circular(18.0);
    const zero = Radius.circular(0);
    return ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
                left: left ? borderRadius : zero,
                right: left ? zero : borderRadius)),
        primary: Theme.of(context).accentColor);
  }

  Widget getLoadingPage(BuildContext context, bool loading) {
    var getBottomText = (String text) {
      return Padding(padding: EdgeInsets.only(bottom: 10.0), child: Text(text));
    };
    return Stack(children: [
      Center(
          child: loading
              ? CircularProgressIndicator()
              : Icon(
                  Icons.error,
                  color: Colors.yellow[300],
                  size: 150,
                )),
      SafeArea(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  width: 500,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          getBottomText(loading
                              ? "Make sure your device is connected to the same WiFi network as your Scoreboard\n\nScoreboard takes approximately 2 minutes to reboot"
                              : "Failed to connect to scoreboard!\n\nMake sure your device is connected to the same WiFi network as your Scoreboard"),
                          Container(
                            height: 20,
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                    child: Text("Refresh"),
                                    style: getButtonStyle(context, true),
                                    onPressed: () {
                                      setState(() {
                                        refreshFailures = 0;
                                        shouldRefreshConfig = true;
                                      });
                                    }),
                                ElevatedButton(
                                    child: Text("Troubleshooting"),
                                    style: getButtonStyle(context, false),
                                    onPressed: () {
                                      showBottomSheet(context, loading);
                                    })
                              ])
                        ],
                        mainAxisAlignment: MainAxisAlignment.end,
                      )))))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    print("Calling build at root");
    refreshTimer = new Timer(Duration(seconds: 10), () {
      print("Executing timer from success");
      setState(() {
        shouldRefreshConfig = true;
      });
    });
    return FutureBuilder<ScoreboardSettings>(
        future: getConfig(),
        builder: (context, snapshot) {
          Widget body;

          List<Widget> actions;
          Widget fab;
          Widget drawer;
          String name;
          if (snapshot.hasData) {
            settings = snapshot.data;
            name = settings.name;
            body = _buildHome(context);
            actions = _buildActions();
            fab = _buildFab(context);
            drawer = ScoreboardDrawer();
            shouldRefreshConfig = false;
            refreshFailures = 0;
          } else {
            if (snapshot.hasError) {
              print("Got config error " +
                  snapshot.error.toString() +
                  "\nRefresh failures: " +
                  refreshFailures.toString());
              refreshFailures += 1;
              if (refreshFailures < REFRESH_FAILURES_BEFORE_SHOW_ERROR) {
                name = "Loading";
              } else {
                if (refreshTimer != null) {
                  refreshTimer.cancel();
                }
                name = "Connection Error";
              }
            } else {
              print("No snapshot error");
              name = "Loading...";
            }
            body = getLoadingPage(
                context, refreshFailures < REFRESH_FAILURES_BEFORE_SHOW_ERROR);
            drawer = ScoreboardDrawer();
            shouldRefreshConfig = false;
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

  Widget _buildFab(BuildContext context) {
    double height = 75;
    double width = 150;
    return Container(
        height: height,
        width: width,
        child: new Material(
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(height / 2))),
            elevation: 10.0,
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    color: settings.screenOn
                        ? Theme.of(context).accentColor
                        : Colors.grey,
                    width: width / 2,
                    height: height,
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          settings.screenOn = !settings.screenOn;
                          refreshingPower = true;
                        });
                        AppState state = await AppState.load();
                        String ip =
                            state.scoreboardAddresses[state.activeIndex];
                        print("Setting power for scoreboard at address: $ip");
                        ScoreboardSettings newSettings =
                            await Channel(ipAddress: ip)
                                .powerRequest(settings.screenOn);
                        setState(() {
                          settings = newSettings;
                          refreshingPower = false;
                        });
                      },
                      child: refreshingPower
                          ? Padding(
                              padding: EdgeInsets.all(height / 4),
                              child: CircularProgressIndicator(
                                valueColor: new AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ))
                          : Icon(
                              Icons.power_settings_new,
                              color: Colors.white,
                              size: height / 2,
                            ),
                    )),
                InkWell(
                    onTap: () async {
                      setState(() {
                        settings.autoPowerOn = !settings.autoPowerOn;
                        refreshingAutoPower = true;
                      });
                      AppState state = await AppState.load();
                      String ip = state.scoreboardAddresses[state.activeIndex];
                      print(
                          "Setting auto power for scoreboard at address: $ip");
                      ScoreboardSettings newSettings =
                          await Channel(ipAddress: ip)
                              .autoPowerRequest(settings.autoPowerOn);
                      setState(() {
                        settings = newSettings;
                        refreshingAutoPower = false;
                      });
                    },
                    child: Container(
                        color:
                            settings.autoPowerOn ? Colors.green : Colors.grey,
                        width: width / 2,
                        height: height,
                        child: refreshingAutoPower
                            ? Padding(
                                padding: EdgeInsets.all(height / 4),
                                child: CircularProgressIndicator(
                                  valueColor: new AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ))
                            : Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: height / 2,
                              ))),
              ]),
              Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 0),
                      child: VerticalDivider(
                        thickness: 2,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ))),
            ])));
  }

  List<Row> getTable(List<Screen> screens, BuildContext context,
      int crossAxisCount, double iconSize) {
    List<Widget> items = screens
        .map((screen) => getScreen(screen, context, iconSize: iconSize))
        .toList();
    while (items.length % crossAxisCount != 0) {
      items.add(new Visibility(
          child: getScreen(screens[0], context, iconSize: iconSize),
          maintainInteractivity: false,
          visible: false,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true));
    }
    List<Row> rows = [];
    List<Widget> row = [];
    List<List<Widget>> rowList = [];
    for (var item in items) {
      row.add(item);
      if (row.length == crossAxisCount) {
        rows.add(new Row(
            mainAxisAlignment: MainAxisAlignment.center, children: row));
        rowList.add(row);
        row = [];
      }
    }
    return rows;
  }

  Widget getScreen(Screen screen, BuildContext context,
      {double margin = 5.0, double iconSize = 70.0}) {
    return new Card(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 5.0),
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

              AppState state = await AppState.load();
              String ip = state.scoreboardAddresses[state.activeIndex];
              print("Setting sport for scoreboard at address: $ip");
              try {
                ScoreboardSettings newSettings =
                    await Channel(ipAddress: ip).sportRequest(screen.id);
                settings = newSettings;
              } finally {
                setState(() {
                  print("Done select");
                  refreshingScreenSelect = false;
                });
              }
            } else if (screen.id == settings.activeScreen &&
                screen.id == ScreenId.FLAPPY) {
              AppState state = await AppState.load();
              String ip = state.scoreboardAddresses[state.activeIndex];
              try {
                ScoreboardSettings newSettings =
                    await Channel(ipAddress: ip).gameAction();
                settings = newSettings;
              } finally {
                print("Done send game action");
              }
            }
          },
          child: Stack(children: [
            screen.id == ScreenId.SMART
                ? Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          screen.id == settings.activeScreen &&
                                  refreshingScreenSelect
                              ? Container(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        new AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ))
                              : Icon(screen.getIcon(), color: Colors.white),
                          Text(
                            "  Automatic",
                            style: TextStyle(fontSize: 24),
                          )
                        ]))
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: screen.id == settings.activeScreen &&
                            refreshingScreenSelect
                        ? Container(
                            width: iconSize,
                            height: iconSize,
                            child: CircularProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ))
                        : Icon(
                            screen.getIcon(),
                            color: Colors.white,
                            size: iconSize,
                          ),
                  ),
            if (settings.autoPowerOn &&
                screen.id == ScreenId.SMART &&
                !settings.screenOn)
              Positioned(
                  right: 4.0,
                  top: 4.0,
                  child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(offset: Offset(0, 1))])))
          ])),
    );
  }

  Widget getCategoryText(String text, double padding) {
    return Padding(
        padding: EdgeInsets.only(left: padding, top: 10.0),
        child: Text(text, style: TextStyle(fontSize: 14)));
  }

  Widget getGroup(List<Screen> screens, String label, double padding,
      int crossAxisCount, double iconSize) {
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Stack(overflow: Overflow.visible, children: [
          Column(
            children: [...getTable(screens, context, crossAxisCount, iconSize)],
          ),
          Positioned(child: getCategoryText(label, padding), top: -22.0),
        ]));
  }

  double getRowWidth(int screenWidth, int crossAxisCount, double iconWidth,
      double cardHorizontalPadding, double cardHorizontalMargin) {
    return crossAxisCount * (iconWidth + cardHorizontalPadding * 2) +
        (crossAxisCount - 1) * (cardHorizontalMargin * 2);
  }

  double getInset(int screenWidth, double rowWidth) {
    return (screenWidth - rowWidth) / 2;
  }

  int getCrossAxisCount(int screenWidth, double iconWidth,
      double cardHorizontalPadding, double cardHorizontalMargin) {
    var crossAxisCount = (screenWidth ~/
            (iconWidth + cardHorizontalMargin + cardHorizontalPadding)) -
        1;
    return min(crossAxisCount, 4);
  }

  Widget _buildHome(BuildContext context) {
    int width = MediaQuery.of(context).size.width.floor();
    double additionalPadding = (MediaQuery.of(context).padding.left +
        MediaQuery.of(context).padding.right);

    width -= additionalPadding.toInt() * 2;
    double iconSize = 100.0;
    int crossAxisCount = 1;
    const double cardHorizontalPadding = 40.0;
    const double cardHorizontalMargin = 5.0;
    while (crossAxisCount == 1) {
      crossAxisCount = getCrossAxisCount(
          width, iconSize, cardHorizontalPadding, cardHorizontalMargin);
      if (crossAxisCount == 1) {
        iconSize -= 10;
      }
    }
    var rowWidth = getRowWidth(width, crossAxisCount, iconSize,
        cardHorizontalPadding, cardHorizontalMargin);
    var inset = getInset(width, rowWidth) + additionalPadding;
    // print(
    //     "Width is $width, count: $crossAxisCount, rowWidth: $rowWidth, inset: $inset, iconSize: $iconSize");

    var smartScreen = Screen(id: ScreenId.SMART, name: "Smart", subtitle: "");
    if (crossAxisCount == 0) {
      return ListView(children: []);
    }
    return ListView(
      children: [
        Padding(
            child: getScreen(smartScreen, context, margin: inset),
            padding: EdgeInsets.only(top: min(inset - 10, 30))),
        getGroup(proScreens, "Professional", inset, crossAxisCount, iconSize),
        getGroup(collegeScreens, "College", inset, crossAxisCount, iconSize),
        getGroup(otherScreens, "Other", inset, crossAxisCount, iconSize),
        Padding(
            padding: EdgeInsets.only(top: 80),
            child: SafeArea(child: Center(child: Text("Made for Jamie"))))
      ],
    );
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
