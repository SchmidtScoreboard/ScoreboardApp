import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'homepage.dart';
import 'channel.dart';

const borderRadius = 18.0;

// import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';

enum OnboardingStatus { ready, loading, error }

abstract class OnboardingScreen extends StatefulWidget {}

abstract class OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingStatus status = OnboardingStatus.ready;
  bool keyboardShowing = false;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  String ipAddress = "";
  KeyboardVisibilityController keyboardVisibilityController =
      KeyboardVisibilityController();
  late StreamSubscription<bool> keyboardEvents;
  Widget getResetButton(bool isDoubleButton) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        padding: EdgeInsets.all(5),
        shape: RoundedRectangleBorder(
            borderRadius: isDoubleButton
                ? BorderRadius.only(
                    bottomRight: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius))
                : BorderRadius.all(Radius.circular(borderRadius))),
      ),
      child: Text("Restart Setup",
          style: TextStyle(color: Colors.white, fontSize: 12)),
      onPressed: () {
        AppState.setState(SetupState.FACTORY);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => SplashScreen()));
      },
    );
  }

  @override
  void initState() {
    super.initState();
    keyboardEvents = keyboardVisibilityController.onChange.listen(
      (bool visible) {
        setState(() {
          keyboardShowing = visible;
        });
      },
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await keyboardEvents.cancel();
  }

  Future<String> getIp() async {
    AppState state = await AppState.load();
    String ip;
    try {
      ip = state.scoreboardAddresses[state.activeIndex];
    } catch (e) {
      ip = "";
    }
    return ip;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getIp(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            ipAddress = snapshot.data!;
            return Scaffold(
                key: scaffoldKey,
                body: Builder(builder: (BuildContext context) {
                  return getOnboardWidget(context);
                }),
                backgroundColor: Theme.of(context).primaryColorDark,
                drawer: ScoreboardDrawer());
          } else {
            return Container(color: Theme.of(context).primaryColorDark);
          }
        });
  }

  Widget getOnboardWidget(BuildContext context);

  Widget getOnboardTitle(String text) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 36,
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget getOnboardInstruction(String text) {
    return Text(text, style: TextStyle(fontSize: 18, color: Colors.white));
  }

  Widget getOnboardButton(BuildContext context, String text, Widget target,
      Future<bool> Function(BuildContext) callback,
      {bool enabled = true, Function(BuildContext)? errorCallback}) {
    return ElevatedButton(
      child: status == OnboardingStatus.ready
          ? Text(text, style: TextStyle(color: Colors.white, fontSize: 12))
          : Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
              )),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 4,
        // highlightElevation: 8,
        shape: StadiumBorder(),
      ),
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

  Widget layoutWidgets(Iterable widgets, Widget? footer) {
    List<Widget> paddedWidgets = [];
    for (var widget in widgets) {
      paddedWidgets.add(widget);
      paddedWidgets.add(new SizedBox(
        height: 20,
      ));
    }
    Widget alignedFooter = SafeArea(
        minimum: const EdgeInsets.only(bottom: 10, right: 10),
        child: Align(alignment: FractionalOffset.bottomRight, child: footer));
    return Stack(children: [
      SingleChildScrollView(
          child: SafeArea(
              minimum: const EdgeInsets.only(top: 70),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                      child: Container(
                          width: 500,
                          child: Column(children: paddedWidgets)))))),
      SafeArea(
        child: IconButton(
            icon: ipAddress == "" ? Icon(Icons.menu) : Icon(Icons.arrow_back),
            onPressed: () async {
              if (ipAddress == "") {
                scaffoldKey.currentState!.openDrawer();
              } else {
                await AppState.setState(SetupState.READY);
                setState(() {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => buildHome()));
                });
              }
            }),
      ),
      if (!keyboardShowing) alignedFooter
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
            TextButton(
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
                      color: Theme.of(context).colorScheme.secondary,
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius))),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            padding: EdgeInsets.all(5),
          ),
          child: Text("Skip to Sync",
              style: TextStyle(color: Colors.white, fontSize: 12)),
          onPressed: () {
            AppState.setState(SetupState.SYNC);
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => SyncScreen()));
          },
        ));
  }
}

class ConnectToHotspotScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return ConnectToHotspotScreenState();
  }
}

class ConnectToHotspotScreenState extends OnboardingScreenState {
  late Timer refreshTimer;
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
    return layoutWidgets(
        <Widget>[
          getOnboardTitle("Connect to your Scoreboard"),
          FutureBuilder(
            future: Channel.hotspotChannel.connectRequest(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                print("Connected to server");
                return Column(children: <Widget>[
                  getOnboardInstruction(
                      "Your device is now connected to the Schmidt Scoreboard."),
                  SizedBox(height: 20),
                  getOnboardButton(
                      context, "Continue", WifiCredentialsScreen(), callback),
                ]);
              } else if (snapshot.hasError) {
                //print(snapshot.error.toString());
              }
              return Column(children: [
                getOnboardInstruction(
                    "In your device's Settings app, connect to the wifi network as shown on your scoreboard"),
                SizedBox(height: 20),
                Text("Waiting on connection...",
                    style: TextStyle(color: Colors.grey[400])),
              ]);
            },
          ),
        ],
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(borderRadius),
                      topLeft: Radius.circular(borderRadius))),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              padding: EdgeInsets.all(5),
            ),
            child: Text("Skip to Sync",
                style: TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: () {
              AppState.setState(SetupState.SYNC);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => SyncScreen()));
            },
          ),
          getResetButton(true)
        ]));
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
  late String wifi;
  late String password;
  bool showWifiPassword = false;
  bool sentCredentials = false;
  String errorString = "";

  @override
  void initState() {
    super.initState();
    passNode.addListener(() {
      setState(() {});
    });
  }

  void errorCallback(BuildContext context) {
    if (sentCredentials) {
      print("Got error callback wifi setup");
      if (errorString == "") {
        errorString =
            "Failed to send Wifi Configuration, is your scoreboard turned on? Are you connected to wifi network Scoreboard42?";
      }
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: Text(
          errorString,
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(minutes: 10),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: "Dismiss",
          textColor: Colors.white,
          onPressed: () {},
        ),
      ));
    }
    status = OnboardingStatus.ready;
  }

  Future<bool> callback(BuildContext context) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    sentCredentials = false;

    AlertDialog wifiConfirm = AlertDialog(
      title: Text("Confirm WiFi Credentials"),
      content: RichText(
          text: TextSpan(
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.white,
        ),
        children: <TextSpan>[
          TextSpan(text: 'Your Scoreboard will attempt to connect to "'),
          TextSpan(
            text: '$wifi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: '" with password "'),
          TextSpan(
              text: '$password', style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
              text:
                  '". Please double check that this is correct. Both WiFi name and password are case sensitive.')
        ],
      )),
      actions: <Widget>[
        TextButton(
          child: Text("Cancel"),
          onPressed: () async {
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          child: Text("Confirm"),
          onPressed: () async {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
    bool result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return wifiConfirm;
        });
    if (result) {
      sentCredentials = true;
      try {
        ScoreboardSettings settings =
            await Channel.hotspotChannel.wifiRequest(wifi, password);
        if (settings == null) {
          print("Failed to setup wifi");
          errorString =
              "Failed to setup wifi, make sure the Wifi Name and Password are correct.";
          return false;
        } else {
          await AppState.setState(SetupState.SYNC);
        }
      } catch (e) {
        errorString = "";
        print(e.toString());
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Enter your WiFi Information"),
      getOnboardInstruction(
          "Scoreboard needs your wifi information so that it can fetch data from the Internet."),
      Theme(
          data: Theme.of(context),
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
          data: Theme.of(context),
          child: Stack(children: <Widget>[
            TextField(
              decoration: InputDecoration(
                  icon: Icon(Icons.lock), labelText: "Password"),
              maxLines: 1,
              obscureText: !showWifiPassword,
              autocorrect: false,
              maxLength: 63,
              textInputAction: TextInputAction.send,
              focusNode: passNode,
              onChanged: (String s) {
                password = s;
              },
            ),
            Positioned(
                bottom: 14,
                right: 0,
                child: IconButton(
                    color: Theme.of(context).colorScheme.secondary,
                    disabledColor: Theme.of(context).disabledColor,
                    icon: showWifiPassword
                        ? Icon(FontAwesomeIcons.eyeSlash)
                        : Icon(FontAwesomeIcons.eye),
                    iconSize: 16,
                    onPressed: passNode.hasFocus
                        ? () {
                            setState(() {
                              showWifiPassword = !showWifiPassword;
                            });
                          }
                        : null)),
          ])),
      Padding(
          padding: EdgeInsets.only(top: 20),
          child: getOnboardButton(context, "Submit", SyncScreen(), callback,
              errorCallback: errorCallback))
    ], getResetButton(false));
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
              "Your scoreboard is connecting to wifi! It may take a few minutes to connect.\n\nOnce connected, enter the code that appears on the Scoreboard to sync."),
          Theme(
              data: Theme.of(context),
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
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              padding: EdgeInsets.all(5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      bottomLeft: Radius.circular(borderRadius))),
            ),
            child: Text("Retry Wifi",
                style: TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: () {
              AppState.setState(SetupState.WIFI_CONNECT);
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WifiCredentialsScreen()));
            },
          ),
          getResetButton(true)
        ]));
  }

  void errorCallback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: Text(
        "Sync failed. Is your phone connected to the same WiFi network as the Scoreboard?",
        style: TextStyle(color: Colors.white),
      ),
      duration: Duration(minutes: 10),
      backgroundColor: Colors.redAccent,
      action: SnackBarAction(
        label: "Dismiss",
        textColor: Colors.white,
        onPressed: () {},
      ),
    ));
    status = OnboardingStatus.ready;
  }

  Future<bool> callback(BuildContext context) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    String ip = ipFromCode(code);
    String address = "http://$ip:5005/";
    print("Found address: $address");

    try {
      await Channel(ipAddress: address).syncRequest();
    } catch (e) {
      // Do nothing
      print(e.toString());
      return false;
    }
    await AppState.setState(SetupState.READY);
    await AppState.setAddress(address);
    return true;
  }
}
