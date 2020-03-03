import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';

import 'homepage.dart';
import 'channel.dart';

// import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';

enum OnboardingStatus { ready, loading, error }

abstract class OnboardingScreen extends StatefulWidget {}

abstract class OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingStatus status = OnboardingStatus.ready;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
            body: Builder(builder: (BuildContext context) {
              return getOnboardWidget(context);
            }),
            backgroundColor: Colors.transparent,
            drawer: ScoreboardDrawer()));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
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
      Future<bool> Function(BuildContext) callback,
      {bool enabled = true, Function(BuildContext) errorCallback}) {
    return RaisedButton(
      child: status == OnboardingStatus.ready
          ? Text(
              text,
              // style: TextStyle(color: Colors.white),
            )
          : Padding(
              padding: EdgeInsets.all(10),
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
              bool result = await callback(context);
              if (!result) {
                print("There was an error in callback");
                status = OnboardingStatus.error;
                if (errorCallback != null) {
                  errorCallback(context);
                }
                setState(() {});
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
        minimum: const EdgeInsets.only(bottom: 30),
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
  Future<bool> callback(BuildContext context) async {
    await AppState.setState(SetupState.HOTSPOT);
    return true;
  }

  Widget getOnboardWidget(BuildContext context) {
    AppState.load().then((AppState state) {
      if (state.policyVersion < AppState.CURRENT_POLICY_VERSION) {
        AlertDialog policyAlert = AlertDialog(
          title: Text("Usage and Privacy Policy"),
          content: SingleChildScrollView(child: Text(AppState.POLICY_TEXT)),
          actions: <Widget>[
            FlatButton(
              child: Text("Accept"),
              onPressed: () async {
                await AppState.setPolicyVersion(
                    AppState.CURRENT_POLICY_VERSION);
                Navigator.of(context).pop();
              },
            )
          ],
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return policyAlert;
            });
      }
    });
    return layoutWidgets(
        <Widget>[
          getOnboardTitle("Scoreboard Controller"),
          getOnboardInstruction(
              "Welcome to the scoreboard controller app! Make sure your scoreboard is plugged in and powered on, then we'll get connected!\n\nIf your scoreboard is showing an error, hold down the side button for ten seconds to reset it."),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "If you'd like to purchase a Scoreboard, check out ",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                TextSpan(
                  text: "schmidtscoreboard.com",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launch("http://schmidtscoreboard.com");
                    },
                ),
              ],
            ),
          ),
          getOnboardButton(
              context, "Get Started", ConnectToHotspotScreen(), callback),
        ],
        Padding(
            padding: EdgeInsets.all(20),
            child: FlatButton(
              child: Text(
                  "If you've already set up this scoreboard with another device, you can skip to the syncing phase by pressing here",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  Future<bool> callback(BuildContext context) async {
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
          "In your device's Settings app, connect to the wifi network as shown on your scoreboard"),
      FutureBuilder(
        future: Channel.hotspotChannel.connectRequest(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            print("Connected to server");
            connected = true;
            return getOnboardButton(
                context, "Continue", WifiCredentialsScreen(), callback);
          } else if (snapshot.hasError) {
            //print(snapshot.error.toString());
          }
          return Text("Waiting on connection...",
              style: TextStyle(color: Colors.grey[400]));
        },
      ),
      if (!connected)
        RaisedButton(
            child: Text(
              "Go to Settings",
            ),
            color: Theme.of(context).accentColor,
            elevation: 4,
            highlightElevation: 8,
            shape: StadiumBorder(),
            onPressed: () {
              AppSettings.openWIFISettings();
            })
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

  void errorCallback(BuildContext context) {
    print("Got error callback wifi setup");
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: Text(
          "Failed to send Wifi Configuration, is your scoreboard turned on? Are you connected to wifi network Scoreboard42?"),
      duration: Duration(minutes: 10),
      action: SnackBarAction(
        label: "Dismiss",
        onPressed: () {},
      ),
    ));
    status = OnboardingStatus.ready;
  }

  Future<bool> callback(BuildContext context) async {
    Scaffold.of(context).hideCurrentSnackBar();
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
    return layoutWidgets(<Widget>[
      getOnboardTitle("Enter your WiFi Information"),
      getOnboardInstruction(
          "Scoreboard needs your wifi information so that it can fetch data from the Internet. Please provide it in the fields below."),
      getOnboardInstruction(
          "Note that fields are case-sensitive. Scoreboard will restart and connect to WiFi"),
      Theme(
          data: ThemeData(
              primarySwatch: Colors.blue,
              accentColor: Colors.orangeAccent,
              brightness: Brightness.dark),
          child: TextField(
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
          )),
      Theme(
          data: ThemeData(
              primarySwatch: Colors.blue,
              accentColor: Colors.orangeAccent,
              brightness: Brightness.dark),
          child: TextField(
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
          )),
      Padding(
          padding: EdgeInsets.only(top: 20),
          child: getOnboardButton(context, "Submit", SyncScreen(), callback,
              errorCallback: errorCallback))
    ]);
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
              "It will take a few minutes for your Scoreboard to startup and connect."),
          getOnboardInstruction(
              "Enter the code that appears on the Scoreboard."),
          Theme(
              data: ThemeData(
                  primarySwatch: Colors.blue,
                  accentColor: Colors.orangeAccent,
                  brightness: Brightness.dark),
              child: TextField(
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
              )),
          getOnboardButton(context, "Confirm", MyHomePage(), callback,
              enabled: isValid, errorCallback: errorCallback)
        ],
        Padding(
            padding: EdgeInsets.all(20),
            child: FlatButton(
              child: Text(
                  "If your scoreboard is showing an error, reset your Scoreboard by pressing and holding the side button for 10 seconds, then tap here to restart setup",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              onPressed: () {
                AppState.setState(SetupState.SYNC);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ConnectToHotspotScreen()));
              },
            )));
  }

  void errorCallback(BuildContext context) {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: Text(
          "Sync failed. Is your Scoreboard connected to the same WiFi network as this device?"),
      duration: Duration(minutes: 10),
      action: SnackBarAction(
        label: "Dismiss",
        onPressed: () {},
      ),
    ));
    status = OnboardingStatus.ready;
  }

  Future<bool> callback(BuildContext context) async {
    Scaffold.of(context).hideCurrentSnackBar();
    String ip = ipFromCode(code);
    String address = "http://$ip:5005/";
    print("Found address: $address");

    try {
      await Channel(ipAddress: address).syncRequest();
    } catch (e) {
      // Do nothing
      return false;
    }
    await AppState.setState(SetupState.READY);
    await AppState.setAddress(address);
    return true;
  }
}
