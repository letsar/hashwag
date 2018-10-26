import 'package:flutter/material.dart';
import 'package:hashwag/src/rendering/cloud.dart';
import 'package:hashwag/src/widgets/arrow.dart';
import 'dart:math' as math;

import 'package:hashwag/src/widgets/cloud.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      //showPerformanceOverlay: true,
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
  double sourceOpacity = 0.0;
  double targetOpacity = 0.0;
  static const int _count = 50;
  static const double _overlap = 0.8;
  static const double _duration = 1.0 / (_count - _overlap * (_count - 1));
  static const double _overlapDuration = _duration * _overlap;
  static const LerpCurve _start = LerpCurve(0.0, 0.80, curve: Curves.easeIn);
  static const LerpCurve _end = LerpCurve(0.4, 1.0, curve: Curves.easeIn);

  @override
  void initState() {
    super.initState();
    arrowController =
        ArrowController(vsync: this, duration: Duration(milliseconds: 7000));
    arrowController.addStatusListener(handleStatusChanged);
  }

  void dispose() {
    arrowController.removeStatusListener(handleStatusChanged);
    arrowController.dispose();
    super.dispose();
  }

  List<Widget> buildItems(BuildContext context, bool isSource) {
    List<double> starts = List<double>();
    List<double> ends = List<double>();
    Tween<double> r;

    final TextStyle textStyle = Theme.of(context).textTheme.body1;
    List<Widget> cloudItems = List<Widget>();
    for (var i = 0; i < _count; i++) {
      //starts.add((_duration - _overlapDuration) * i);
      //ends.add((_duration - _overlapDuration) * i + _duration);
      starts.add(_start.transform(i / _count));
      ends.add(_end.transform(i / _count));
      if (i == 0) {
        cloudItems.add(buildItem(context, i, isSource,
            textStyle.copyWith(fontSize: 48.0, color: Colors.blue)));
      } else {
        double fontSize = 12.0 + i ~/ 3;
        cloudItems.add(buildItem(
            context, i, isSource, textStyle.copyWith(fontSize: fontSize)));
      }
    }
    return cloudItems;
  }

  Widget buildItem(
      BuildContext context, int index, bool isSource, TextStyle style) {
    final double pos = index / _count;
    return Arrow(
      tag: isSource ? 'source_$index' : 'target_$index',
      targetTag: isSource ? 'target_$index' : null,
      animationBuilder: (animation) => CurvedAnimation(
            parent: animation,
            curve: Interval(
              _start.transform(pos),
              _end.transform(pos),
              curve: Curves.easeIn,
            ),
          ),
      child: FittedBox(
        child: Text(
          '#FlutterIsComing',
          style: style,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> sources = buildItems(context, true);
    final List<Widget> targets = buildItems(context, false);
    final Matrix4 transform = Matrix4.identity()..scale(8.0, 8.0, 1.0);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Opacity(
                  opacity: targetOpacity,
                  child: Center(
                    child: FittedBox(
                      child: Cloud(
                        children: targets,
                        placementDelegate: ArchimedeanSpiralPlacementDelegate(
                            ratio: 16.0 / 9.0),
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: sourceOpacity,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: Cloud(
                      children: sources,
                      placementDelegate:
                          ArchimedeanSpiralPlacementDelegate(ratio: 16.0 / 9.0),
                    ),
                  ),
                ),
              ],
            ),
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

  void handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        setState(() {
          sourceOpacity = 0.0;
          targetOpacity = 0.0;
        });
        break;
      case AnimationStatus.completed:
        setState(() {
          targetOpacity = 1.0;
        });
        break;
      case AnimationStatus.dismissed:
        setState(() {
          sourceOpacity = 0.0;
        });
        break;
      default:
    }
  }
}

class LerpCurve extends Curve {
  /// Creates an interval curve.
  ///
  /// The arguments must not be null.
  const LerpCurve(this.begin, this.end, {this.curve = Curves.linear})
      : assert(begin != null),
        assert(end != null),
        assert(curve != null);

  /// The largest value for which this interval is 0.0.
  ///
  /// From t=0.0 to t=`begin`, the interval's value is 0.0.
  final double begin;

  /// The smallest value for which this interval is 1.0.
  ///
  /// From t=`end` to t=1.0, the interval's value is 1.0.
  final double end;

  /// The curve to apply between [begin] and [end].
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(begin >= 0.0);
    assert(begin <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
    assert(end >= begin);
    return curve.transform(begin + (end - begin) * t);
  }
}
