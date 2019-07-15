
import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
import 'channel.dart';
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
  void initState() {
    super.initState();
    channel = new Channel();
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
        if (snapshot.hasData) {
          settings = snapshot.data;
          return _buildHome();
        } else if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(
            title: Text(widget.title),
            ),
            body: ListView(
              children: <Widget>[
                Card(
                  child: Column(children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.error),
                      title: Text("Could not connect to scoreboard"),
                      subtitle: Text("Make sure it is powered and connected to wifi"),
                    ),
                  ],))
              ]
            )
              
          );

        } else {
          return Scaffold(appBar: AppBar(
            title: Text(widget.title),
            ),
            body: Center(
              child: CircularProgressIndicator()),
          );
        }
      }
    );
  }

  Widget _buildHome() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget> [
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
        ],
      ),
      body: Container(
        child: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: settings.screens.length,
          itemBuilder: (context, i) {
            return _buildRow(settings.screens[i]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            settings.screenOn != settings.screenOn;
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