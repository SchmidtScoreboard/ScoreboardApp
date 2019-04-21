import 'package:flutter/material.dart';
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _settingsClicked() {
    setState(() {
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget> [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _settingsClicked,
          ),
        ],
      ),
      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Text(
      //         'You have clicked the button this many times:',
      //       ),
      //       Text(
      //         '$_counter',
      //         style: Theme.of(context).textTheme.display1,
      //       ),
      //     ],
      //   ),
      // ),
      body: ScoreboardScreens(),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), 
    );
  }
}

class ScoreboardScreens extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ScoreboardScreensState();
  }
}

class ScoreboardScreensState extends State<ScoreboardScreens> {

  List<Screen> _screenList = [
      Screen("NHL"),
      Screen("MLB")
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(    body: _fillScreens(),
    );
  }

  Widget _fillScreens() {
    return new ListView.builder(
      padding: const EdgeInsets.all(10.0),
      itemCount: _screenList.length,
      itemBuilder: (context, i) {

        return _buildRow(_screenList[i]);
      },
    );
  }

  Widget _buildRow(Screen screen) {
    return new Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () { 
          print("Tapped on ${screen.title}");
        },
        child: Text(screen.title)
      ),
    );
  }
}

class Screen {

  Screen(String title) {
    this.title = title;
  }
  String title;


}
