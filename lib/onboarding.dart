import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'homepage.dart';
import 'channel.dart';

// import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';

enum OnboardingStatus { ready, loading, error }

abstract class OnboardingScreen extends StatefulWidget {}

abstract class OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingStatus status = OnboardingStatus.ready;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.blue,
              Colors.blue[900],
            ],
          ),
        ),
        child: Scaffold(
            body: getOnboardWidget(context),
            backgroundColor: Colors.transparent,
            drawer: ScoreboardDrawer()));
  }

  Widget getOnboardWidget(BuildContext context);

  Widget getOnboardTitle(String text) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget getOnboardInstruction(String text) {
    return Text(text, style: TextStyle(fontSize: 18, color: Colors.white));
  }

  Widget getOnboardButton(BuildContext context, String text, Widget target,
      AsyncValueGetter<bool> callback,
      {bool enabled = true}) {
    return RaisedButton(
      child: status == OnboardingStatus.ready
          ? Text(text)
          : Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
              )),
      color: Theme.of(context).accentColor,
      elevation: 4,
      highlightElevation: 8,
      shape: StadiumBorder(),
      onPressed: enabled
          ? () async {
              setState(() {
                status = OnboardingStatus.loading;
              });
              bool result = await callback();
              if (!result) {
                print("There was an error in callback");
                status = OnboardingStatus.error;
              } else {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => target));
              }
            }
          : null,
    );
  }

  Widget layoutWidgets(Iterable widgets, [Widget footer]) {
    List<Widget> paddedWidgets = [];
    for (var widget in widgets) {
      paddedWidgets.add(widget);
      paddedWidgets.add(new SizedBox(
        height: 20,
      ));
    }
    Widget alignedFooter = SafeArea(
        child: Align(alignment: FractionalOffset.bottomCenter, child: footer));
    return Stack(children: [
      SingleChildScrollView(
          child: SafeArea(
              minimum: const EdgeInsets.only(top: 70),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: paddedWidgets)))),
      if (footer != null) alignedFooter
    ]);
  }
}

class SplashScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends OnboardingScreenState {
  Future<bool> callback() async {
    await AppState.setState(SetupState.HOTSPOT);
    return true;
  }

  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(
        <Widget>[
          getOnboardTitle("Scoreboard Controller"),
          getOnboardInstruction(
              "Welcome to the scoreboard controller app! Make sure your scoreboard is plugged in and powered on, then we'll get connected!\n\nIf your scoreboard is showing an error, hold down the side button for ten seconds to reset it."),
          getOnboardButton(
              context, "Get Started", ConnectToHotspotScreen(), callback),
        ],
        Padding(
            padding: EdgeInsets.all(20),
            child: FlatButton(
              child: Text(
                  "If you've already set up this scoreboard with another device, you can skip to the syncing phase by pressing here",
                  style: TextStyle(color: Colors.grey, fontSize: 18)),
              onPressed: () {
                AppState.setState(SetupState.SYNC);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => SyncScreen()));
              },
            )));
  }
}

class ConnectToHotspotScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return ConnectToHotspotScreenState();
  }
}

class ConnectToHotspotScreenState extends OnboardingScreenState {
  Timer refreshTimer;
  bool connected = false;

  Future<bool> callback() async {
    await AppState.setState(SetupState.WIFI_CONNECT);
    return true;
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      if (!connected) {
        setState(() {});
      }
    });
  }

  @override
  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Connect to your Scoreboard"),
      getOnboardInstruction(
          "In your device's Settings app, connect to the wifi network as shown on your scoreboard:"),
      //TODO add dope hero image here
      FutureBuilder(
        future: Channel.hotspotChannel.connectRequest(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            print("Connected to server");
            connected = true;
            return getOnboardButton(
                context, "All Connected!", WifiCredentialsScreen(), callback);
          } else if (snapshot.hasError) {
            //print(snapshot.error.toString());
          }
          return Text("Waiting on connection...",
              style: TextStyle(color: Colors.grey[400]));
        },
      ),
    ]);
  }
}

class WifiCredentialsScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return WifiCredentialsScreenState();
  }
}

class WifiCredentialsScreenState extends OnboardingScreenState {
  FocusNode wifiNode = FocusNode();
  FocusNode passNode = FocusNode();
  String wifi;
  String password;

  Future<bool> callback() async {
    try {
      await Channel.hotspotChannel.wifiRequest(wifi, password);
      await AppState.setState(SetupState.SYNC);
    } catch (e) {
      print(e.toString());
      return false;
    }
    return true;
  }

  @override
  Widget getOnboardWidget(BuildContext context) {
    return Theme(
        data: ThemeData(
            primarySwatch: Colors.blue,
            accentColor: Colors.orangeAccent,
            brightness: Brightness.dark),
        child: layoutWidgets(<Widget>[
          getOnboardTitle("Enter your WiFi Information"),
          getOnboardInstruction(
              "Scoreboard needs your wifi information so that it can fetch data from the Internet. Please provide it in the fields below:"),
          TextField(
            decoration: InputDecoration(
              icon: Icon(Icons.wifi),
              labelText: "Wifi Name",
            ),
            maxLines: 1,
            maxLength: 32,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            focusNode: wifiNode,
            onChanged: (String s) {
              wifi = s;
            },
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(passNode);
            },
          ),
          TextField(
            decoration:
                InputDecoration(icon: Icon(Icons.lock), labelText: "Password"),
            maxLines: 1,
            obscureText: true,
            autocorrect: false,
            maxLength: 63,
            textInputAction: TextInputAction.send,
            focusNode: passNode,
            onChanged: (String s) {
              password = s;
            },
            onEditingComplete: () {
              callback();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => SyncScreen()));
            },
          ),
          Padding(
              padding: EdgeInsets.only(top: 20),
              child:
                  getOnboardButton(context, "Submit", SyncScreen(), callback))
        ]));
  }
}

class SyncScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return SyncScreenState();
  }
}

class SyncScreenState extends OnboardingScreenState {
  bool isValid = false;
  String code = "";

  @override
  Widget getOnboardWidget(BuildContext context) {
    print("Building sync screen");
    return layoutWidgets(
        [
          getOnboardTitle("Sync with Scoreboard"),
          getOnboardInstruction(
              "Enter the code that appears on the scoreboard in the box below. If no code appears, double tap the Scoreboard's side button."),
          TextField(
            decoration: InputDecoration(labelText: "Code"),
            textCapitalization: TextCapitalization.characters,
            maxLines: 1,
            autocorrect: false,
            maxLength: 8,
            textInputAction: TextInputAction.done,
            onChanged: (String s) {
              code = s;
              isValid = isValidIpCode(code);
              setState(() {});
            },
            onEditingComplete: () {
              if (isValid) {
                callback();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => MyHomePage()));
              }
            },
          ),
          getOnboardButton(context, "Confirm", MyHomePage(), callback,
              enabled: isValid)
        ],
        RaisedButton(
            child: Padding(
                child: Text(
                    "If your scoreboard is showing an error,\ntap here to restart setup"),
                padding: EdgeInsets.all(5)),
            onPressed: () {
              AppState.setState(SetupState.HOTSPOT);
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ConnectToHotspotScreen()));
            },
            shape: StadiumBorder()));
  }

  Future<bool> callback() async {
    String ip = ipFromCode(code);
    String address = "http://$ip:5005/";
    print("Found address: $address");

    try {
      await Channel(ipAddress: address).syncRequest();
    } catch (e) {
      // Do nothing
      return false;
    } finally {
      await AppState.setState(SetupState.READY);
      await AppState.setAddress(address);
    }
    return true;
  }
}
