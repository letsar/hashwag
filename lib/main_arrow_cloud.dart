import 'package:flutter/material.dart';
import 'package:hashwag/src/flutter_hashtags.dart';
import 'package:hashwag/src/rendering/cloud.dart';
import 'package:hashwag/src/widgets/arrow.dart';
import 'package:hashwag/src/widgets/cloud.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
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
  double sourceOpacity = 0.0;
  double targetOpacity = 0.0;
  static int _count = kFlutterHashtags.length;
  static const LerpCurve _start = LerpCurve(0.0, 0.80, curve: Curves.easeIn);
  static const LerpCurve _end = LerpCurve(0.4, 1.0, curve: Curves.easeIn);
  bool animating = false;

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
    List<Widget> cloudItems = List<Widget>();
    for (var i = 0; i < _count; i++) {
      final FlutterHashtag hashtag = kFlutterHashtags[i];
      cloudItems.add(buildItem(
        context,
        i,
        isSource,
        hashtag,
      ));
    }
    return cloudItems;
  }

  Widget buildItem(
      BuildContext context, int index, bool isSource, FlutterHashtag hashtag) {
    final TextStyle style = Theme.of(context).textTheme.body1.copyWith(
          fontSize: hashtag.size.toDouble(),
          color: hashtag.color,
        );
    final double pos = index / _count;
    return Arrow(
      tag: isSource ? 'source_$index' : 'target_$index',
      targetTag: isSource ? 'target_$index' : null,
      animationBuilder: (animation) => CurvedAnimation(
            parent: animation,
            curve: Interval(
              _start.transform(pos),
              _end.transform(pos),
              curve: Curves.fastOutSlowIn,
            ),
          ),
      child: FittedBox(
        child: RotatedBox(
          quarterTurns: hashtag.rotated ? 1 : 0,
          child: Text(
            hashtag.hashtag,
            style: style,
          ),
        ),
      ),
      flightShuttleBuilder: (
        context,
        animation,
        type,
        from,
        to,
      ) {
        return FittedBox(
          child: Opacity(
            opacity: (animation.value * 2).clamp(0.0, 1.0),
            child: RotatedBox(
              quarterTurns: hashtag.rotated ? 1 : 0,
              child: Text(
                hashtag.hashtag,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;
    final List<Widget> sources = buildItems(context, true);
    final List<Widget> targets = buildItems(context, false);
    final Matrix4 transform = Matrix4.identity()..scale(25.0, 25.0, 1.0);
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (!animating) {
            animating = true;
            arrowController
                .forward(context)
                .then((_) => Future.delayed(Duration(milliseconds: 1000)))
                .then((_) => arrowController.reverse(context))
                .then((_) => animating = false);
          }
        },
        child: Stack(
          children: <Widget>[
            Opacity(
              opacity: targetOpacity,
              child: Center(
                child: FittedBox(
                  child: Cloud(
                    children: targets,
                    placementDelegate:
                        ArchimedeanSpiralPlacementDelegate(ratio: ratio),
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
                      ArchimedeanSpiralPlacementDelegate(ratio: ratio),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        setState(() {
          targetOpacity = 1.0;
          sourceOpacity = 0.0;
        });
        break;
      case AnimationStatus.dismissed:
        setState(() {
          sourceOpacity = 0.0;
          targetOpacity = 0.0;
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
