import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'homepage.dart';
import 'channel.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';

abstract class OnboardingScreen extends StatefulWidget {

}

abstract class OnboardingScreenState extends State<OnboardingScreen> {
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
        drawer: ScoreboardDrawer(cleanup: (){}) 
      )
    );
  }
  
  Widget getOnboardWidget(BuildContext context);

  void cleanup() {
    //Children that need to clean up timers/etc can use this
  }

}

Widget getOnboardTitle(String text) {
  return Text(text, 
    style: TextStyle(fontSize: 36, 
      color: Colors.white, 
      fontWeight: FontWeight.bold), 
    textAlign: TextAlign.center,
  );
}

Widget getOnboardInstruction(String text) {
    return Text(text, style: TextStyle(fontSize: 18, color: Colors.white));
}

Widget getOnboardButton(BuildContext context, String text, Widget target, AsyncCallback callback) {
  return RaisedButton(
    child: Text(text),  
    color: Theme.of(context).accentColor, 
    elevation: 4,
    highlightElevation: 8,
    shape: StadiumBorder(),
    onPressed: () {
      if(callback != null)
        callback();
      if(target != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => target)
        );
      } 
    },
  );

}

Widget layoutWidgets(Iterable widgets) {
  List<Widget> paddedWidgets = [];
  for (var widget in widgets) {
    paddedWidgets.add(widget);
    paddedWidgets.add(new SizedBox(height: 20,));
  }
  return SingleChildScrollView(
    child: SafeArea( 
      minimum: const EdgeInsets.only(top: 70),
      child: 
        Padding(
          padding:const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: paddedWidgets
          )
        )
    )
  );

}

class SplashScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends OnboardingScreenState {

  Future callback() async {
    await AppState.setState(SetupState.HOTSPOT);
  }

  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Scoreboard Controller"),
      getOnboardInstruction("Welcome to the scoreboard controller app! Make sure your scoreboard is plugged in and powered on, then we'll get connected!\n\nIf your scoreboard is showing an error, hold down the side button for ten seconds to reset it."),
      getOnboardButton(context, "Get Started", ConnectToHotspotScreen(), callback)
      //TODO include dope hero image
    ]);
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
  Channel channel;
  bool connected = false;

  @override
  void cleanup() {
    refreshTimer.cancel();
  }

  Future callback() async {
    cleanup();
    await AppState.setState(SetupState.WIFI_CONNECT);
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    channel = new Channel();
    refreshTimer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      if(!connected) {
        setState(() {
        });
      }
    });
  }

  @override
  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Connect to your Scoreboard"),
      getOnboardInstruction("In your device's Settings app, connect to the wifi network as shown on your scoreboard:"),
      //TODO add dope hero image here
      FutureBuilder(
        future: Channel.localChannel.connectRequest(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if(snapshot.hasData) {
            print("Connected to server");
            connected = true;
            return getOnboardButton(context, "All Connected!", WifiCredentialsScreen(), callback);
          } else if (snapshot.hasError) {
            //print(snapshot.error.toString());
          }
          return Text("Waiting on connection...", style: TextStyle(color: Colors.grey[400]));
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

  Future callback() async {
    ScoreboardSettings scoreboard = await Channel.localChannel.wifiRequest(wifi, password);
    await AppState.setState(SetupState.SYNC);
  }
  @override
  Widget getOnboardWidget(BuildContext context) { //TODO fix layout alignment issues

    return Theme(data: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.orangeAccent,
        brightness: Brightness.dark),
        child: layoutWidgets(<Widget>[
          getOnboardTitle("Enter your WiFi Information"),
          getOnboardInstruction("Scoreboard needs your wifi information so that it can fetch data from the Internet. Please provide it in the fields below:"),
          TextField(decoration: 
            InputDecoration(
              icon: Icon(Icons.wifi), 
              labelText: "Wifi Name",
            ),
            maxLines: 1, 
            maxLength: 32,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            focusNode: wifiNode,
            onChanged: (String s) {wifi = s;},
            onEditingComplete: () {FocusScope.of(context).requestFocus(passNode);},
            ),
          TextField(decoration: InputDecoration(icon: Icon(Icons.lock), labelText: "Password"),
            maxLines: 1, 
            obscureText: true, 
            autocorrect: false, 
            maxLength: 63, 
            textInputAction: TextInputAction.send,
            focusNode: passNode,
            onChanged: (String s) {password = s;},
            onEditingComplete: () {
              callback();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ScanQRCodeScreen())
              );
            },
            ),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: getOnboardButton(context, "Submit", ScanQRCodeScreen(), callback)
          )
        ])
    );
  }
}

class ScanQRCodeScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return ScanQrCodeScreenState();
  }

}

class ScanQrCodeScreenState extends OnboardingScreenState {

  Future<List<CameraDescription>> getCameras() async {
    return await availableCameras();
  }

  Future callback() async {
    try {
      ScoreboardSettings scoreboard = await Channel.localChannel.syncRequest();
    } catch (e) {
      // Do nothing
    } finally {
      await AppState.setState(SetupState.READY);
      // TODO set address based off the camera picture
      await AppState.setAddress("http://127.0.0.1:5005/");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    getCameras().then((var value) {
      cameras = value;
      try {
        controller = new QRReaderController(cameras[0], 
          ResolutionPreset.medium,
          [CodeFormat.qr],
          (dynamic value) {
            print(value);
          }
        );
      } catch (e) {
        print("Error setting up QRReader");
      }

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        initialized = true;
        setState(() {});
        controller.startScanning();
        print("Starting Scanning");
      });

    }).catchError((var error) {
      print(error);
    });
    
  }

  Widget getWidget() {
    if(!initialized) {
      return new Text("Not initalized");
    } else if (cameras.length == 0) {
      return new Text("No cameras :(");
    } else if (!controller.value.isInitialized) {
      return new Text("Controller not initialized");
    } else {
      return new AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: new QRReaderPreview(controller)
      );
    }
  }
  bool initialized = false;
  QRReaderController controller;
  List<CameraDescription> cameras;
  @override
  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Scan Address"),
      getOnboardInstruction("Once your scoreboard restarts, it will display a scannable code that will sync it to this app"),
      getWidget(),
      getOnboardButton(context, "Confirm", MyHomePage(), callback),
      RaisedButton(
        child: Padding(
          child: Text("If your scoreboard is showing an error,\ntap here to restart setup"),
          padding: EdgeInsets.all(5)
        ),
        onPressed: () {
          AppState.setState(SetupState.HOTSPOT);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ConnectToHotspotScreen())
          );
        },
        shape: StadiumBorder())
    ]);
  }

}