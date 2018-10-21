import 'package:flutter/material.dart';
import 'package:hashwag/src/rendering/cloud.dart';
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

class _MyHomePageState extends State<MyHomePage> {
  math.Random _rnd = math.Random();

  @override
  Widget build(BuildContext context) {
    List<Widget> cloudItems = List<Widget>();
    // for (var i = 0; i < 50; i++) {
    //   var color = i % 2 == 0 ? Colors.green : Colors.blue;
    //   var height = _rnd.nextDouble() * 50 + 20;
    //   var width = _rnd.nextDouble() * 50 + 20;
    //   cloudItems.add(Container(
    //     width: width,
    //     height: height,
    //     color: color,
    //     child: Text('$i'),
    //   ));
    // }
    for (var i = 0; i < 50; i++) {
      if (i == 0) {
        cloudItems.add(Text(
          '#FlutterIsComing',
          style: TextStyle(fontSize: 48.0, color: Colors.blue),
        ));
      } else {
        double fontSize = _rnd.nextInt(36) + 12.0;
        cloudItems.add(Text(
          '#FlutterIsComing',
          style: TextStyle(fontSize: fontSize),
        ));
      }
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: FittedBox(
          child: Cloud(
            children: cloudItems,
            placementDelegate:
                ArchimedeanSpiralPlacementDelegate(ratio: 16.0 / 9.0),
          ),
        ),
      ),
    );
  }
}

// class SpiralPainter extends CustomPainter {
//   SpiralPainter(this.max);

//   final int max;

//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()..color = Colors.black;

//     final center = size.center(Offset.zero);
//     final dx = center.dx;
//     final dy = center.dy;
//     Spiral spiral = _ArchimedeanSpiral(size);
//     for (var i = 0; i < max; i++) {
//       Offset offset = spiral.getOffset(i);
//       offset = offset.translate(dx, dy);
//       canvas.drawCircle(offset, 1.0, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return false;
//   }
// }
