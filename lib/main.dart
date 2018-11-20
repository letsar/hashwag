import 'package:flutter/material.dart';
import 'package:hashwag/src/flutter_hashtags.dart';
import 'package:flutter_sidekick/flutter_sidekick.dart';
import 'package:flutter_scatter/flutter_scatter.dart';

int _count = kFlutterHashtags.length;
const LerpCurve _start = LerpCurve(0.0, 0.80, curve: Curves.easeIn);
const LerpCurve _end = LerpCurve(0.4, 1.0, curve: Curves.easeIn);

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
  SidekickController sidekickController;
  double sourceOpacity = 0.0;
  double targetOpacity = 0.0;
  bool animating = false;

  @override
  void initState() {
    super.initState();
    sidekickController =
        SidekickController(vsync: this, duration: Duration(milliseconds: 5000));
    sidekickController.addStatusListener(handleStatusChanged);
  }

  void dispose() {
    sidekickController.removeStatusListener(handleStatusChanged);
    sidekickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;
    final Matrix4 transform = Matrix4.identity()..scale(20.0, 20.0, 1.0);
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (!animating) {
            animating = true;
            sidekickController
                .moveToTarget(context)
                .then((_) => Future.delayed(Duration(milliseconds: 10)))
                .then((_) => sidekickController.moveToSource(context))
                .then((_) => animating = false);
          }
        },
        child: Stack(
          children: <Widget>[
            Opacity(
              opacity: targetOpacity,
              child: Center(
                child: FittedBox(child: HashtagWidget(false, ratio)),
              ),
            ),
            Opacity(
              opacity: sourceOpacity,
              child: Transform(
                alignment: Alignment.center,
                transform: transform,
                child: HashtagWidget(true, ratio),
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

class HashtagWidget extends StatelessWidget {
  HashtagWidget(this.isSource, this.ratio);
  final bool isSource;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    List<Widget> cloudItems = List<Widget>();
    for (var i = 0; i < _count; i++) {
      final FlutterHashtag hashtag = kFlutterHashtags[i];
      cloudItems.add(Hashtag(
        i,
        isSource,
        hashtag,
      ));
    }
    return Scatter(
      fillGaps: true,
      children: cloudItems,
      delegate: ArchimedeanSpiralScatterDelegate(ratio: ratio),
    );
  }
}

class Hashtag extends StatelessWidget {
  Hashtag(this.index, this.isSource, this.hashtag);
  final int index;
  final bool isSource;
  final FlutterHashtag hashtag;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = Theme.of(context).textTheme.body1.copyWith(
          fontSize: hashtag.size.toDouble(),
          color: hashtag.color,
        );
    final tween = Tween<double>(
        begin: hashtag.size.toDouble(), end: hashtag.size.toDouble() / 2.0);
    final double pos = index / _count;
    return Sidekick(
      tag: isSource ? 'source_$index' : 'target_$index',
      targetTag: isSource ? 'target_$index' : null,
      animationBuilder: (animation) => CurvedAnimation(
            parent: animation,
            curve: Interval(
              _start.transform(pos),
              _end.transform(pos),
              curve: isSource
                  ? Curves.fastOutSlowIn
                  : FlippedCurve(Curves.fastOutSlowIn),
            ),
          ),
      child: RotatedBox(
        quarterTurns: hashtag.rotated ? 1 : 0,
        child: Text(
          hashtag.hashtag,
          style: style,
        ),
      ),
      flightShuttleBuilder: (
        context,
        animation,
        type,
        from,
        to,
      ) {
        // var s = style.copyWith(
        //     fontSize:
        //         Tween<double>(begin: from.size.height, end: to.size.height)
        //             .evaluate(animation));

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
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
      },
    );
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
