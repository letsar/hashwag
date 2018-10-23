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
  AnimationController controller1;
  AnimationController controller2;

  @override
  void initState() {
    super.initState();
    arrowController = new ArrowController();
    controller1 = AnimationController(
        vsync: this, duration: Duration(milliseconds: 5000));
    controller2 = AnimationController(
        vsync: this, duration: Duration(milliseconds: 5000));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: GestureDetector(
        onTap: () {
          arrowController.startArrowTransition(
              context, ArrowFlightDirection.forward);
        },
        child: Row(
          children: <Widget>[
            Column(
              children: <Widget>[
                Arrow(
                  tag: 'source',
                  targetTag: 'target',
                  animation: controller1.view,
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
                Container(
                  width: 60.0,
                  height: 60.0,
                  color: Colors.blue,
                ),
                Container(
                  width: 60.0,
                  height: 60.0,
                  color: Colors.green,
                ),
                Arrow(
                  tag: 'target',
                  animation: controller2.view,
                  child: Container(
                    width: 60.0,
                    height: 60.0,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
