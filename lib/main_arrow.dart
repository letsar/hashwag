import 'package:flutter/material.dart';
import 'package:hashwag/src/widgets/arrow.dart';
import 'dart:math' as math;

import 'package:hashwag/src/widgets/cloud.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  ArrowController arrowController;

  @override
  void initState() {
    super.initState();
    arrowController =
        ArrowController(vsync: this, duration: Duration(milliseconds: 1000));
  }

  void dispose() {
    arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Arrow(
                    tag: 'source',
                    targetTag: 'target',
                    child: Container(
                      width: 60.0,
                      height: 60.0,
                      color: Colors.blue,
                    ),
                  ),
                  Arrow(
                    tag: 'source2',
                    targetTag: 'target2',
                    child: Container(
                      width: 60.0,
                      height: 60.0,
                      color: Colors.green,
                    ),
                  ),
                  Container(
                    width: 60.0,
                    height: 60.0,
                    color: Colors.yellow,
                  ),
                ],
              ),
              Expanded(
                child: SizedBox(),
              ),
              Column(
                children: <Widget>[
                  Arrow(
                    tag: 'target2',
                    child: Container(
                      width: 60.0,
                      height: 60.0,
                      color: Colors.blue,
                    ),
                  ),
                  Container(
                    width: 60.0,
                    height: 60.0,
                    color: Colors.green,
                  ),
                  Arrow(
                    tag: 'target',
                    child: Container(
                      width: 80.0,
                      height: 80.0,
                      color: Colors.yellow,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                child: Text('forward'),
                onPressed: () => arrowController.forward(context),
              ),
              Expanded(
                child: SizedBox(),
              ),
              RaisedButton(
                child: Text('reverse'),
                onPressed: () => arrowController.reverse(context),
              ),
            ],
          )
        ],
      ),
    );
  }
}
