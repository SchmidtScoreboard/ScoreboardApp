import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'settings.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreboard',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran:"flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'My Scoreboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScoreboardSettings settings;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScoreboardSettings>(
      future: configRequest(settings),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          settings = snapshot.data;
          return _buildHome();
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return CircularProgressIndicator();
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
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: settings.screens.length,
        itemBuilder: (context, i) {
          return _buildRow(settings.screens[i]);
        },
      )
    );
  }

  Widget _buildRow(Screen screen) {
    return new Card( 
      color: screen.id == settings.activeScreen ? Colors.white : Colors.grey,
      
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () { 
          if(screen.id != settings.activeScreen) {
            Future<ScoreboardSettings> responseFuture = sportRequest(screen.id);
            responseFuture.then((ScoreboardSettings set) {
              setState(() {settings = set; }); 
            }).catchError((e) { 
                print("Something went wrong :(");
            });
          }
          
        },
        child: Column(children: <Widget>[
          ListTile(
            leading: Icon(Icons.album),
            title: Text(screen.name,
            style: TextStyle(fontSize: 24),),
            subtitle: Text(screen.subtitle),
          ),
        ],)
      ),
    );
  }
}