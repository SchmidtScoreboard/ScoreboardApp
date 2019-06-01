import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';

abstract class OnboardingScreen extends StatefulWidget {

}

abstract class OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: getOnboardWidget(context)
      )
    );
  }
  
  Widget getOnboardWidget(BuildContext context);

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
  return Padding(
    padding: const EdgeInsets.symmetric(vertical:40),
    child:
      Text(text, style: TextStyle(fontSize: 18, color: Colors.white),)
  );
}

Widget getOnboardButton(BuildContext context, String text, Widget target, [VoidCallback callback]) {
  return RaisedButton(
    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
    child: Text(text),  
    color: Theme.of(context).accentColor, 
    elevation: 4,
    highlightElevation: 8,
    shape: StadiumBorder(),
    onPressed: () {
      if(callback != null)
        callback();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => target)
      );
    },
  );

}

Widget layoutWidgets(Iterable widgets) {
  return SafeArea( 
    minimum: const EdgeInsets.only(top: 100),
    child: Center( child:
      Padding(
        padding:const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: widgets,
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
  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Scoreboard Controller"),
      getOnboardInstruction("Welcome to the scoreboard controller app! Make sure your scoreboard is plugged in and powered on, then we'll get connected!"),
      getOnboardButton(context, "Get Started", ConnectToHotspotScreen())
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
  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Connect to your Scoreboard"),
      getOnboardInstruction("In your device's Settings app, connect to the wifi network as shown on your scoreboard:"),
      //TODO add dope hero image here
      FutureBuilder(
        future: channel.configRequest(settings, "http://127.0.0.1:5005/"),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if(snapshot.hasData) {
            return getOnboardButton(context, "All Connected!", WifiCredentialsScreen());
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

  void callback() {
    //TODO send /wifi request
  }
  @override
  Widget getOnboardWidget(BuildContext context) { //TODO fix layout alignment issues
    return ListView(children: <Widget>[
      layoutWidgets(<Widget>[
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
        onEditingComplete: () {callback();},
        ),
      Padding(
        padding: EdgeInsets.only(top: 20),
        child: getOnboardButton(context, "Submit", SplashScreen(), callback)
      )
    ])
    ]);
  }
}

class ScanQRCodeScreen extends OnboardingScreen {
  @override
  State<StatefulWidget> createState() {
    return ScanQrCodeScreenState();
  }

}

class ScanQrCodeScreenState extends OnboardingScreenState {
  @override
  Widget getOnboardWidget(BuildContext context) {
    return null;
  }

}