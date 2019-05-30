import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';
 
abstract class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).primaryColorDark,
              Theme.of(context).primaryColor,
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
    padding: const EdgeInsets.symmetric(vertical:40, horizontal: 20),
    child:
      Text(text, style: TextStyle(fontSize: 18, color: Colors.white),)
  );
}

Widget getOnboardButton(BuildContext context, String text, Widget target) {
  return RaisedButton(
    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
    child: Text(text),  
    color: Theme.of(context).accentColor, 
    elevation: 4,
    highlightElevation: 8,
    shape: StadiumBorder(),
    onPressed: () {
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
      Column(
        children: widgets,
      )
    )
  );

}
class SplashScreen extends OnboardingScreen {

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
  Widget getOnboardWidget(BuildContext context) {
    return layoutWidgets(<Widget>[
      getOnboardTitle("Connect to your Scoreboard"),
      getOnboardInstruction("In your device's Settings app, connect to the wifi network as shown on your scoreboard"),
      getOnboardButton(context, "Get Started", SplashScreen())
    ]);
  }
  
}