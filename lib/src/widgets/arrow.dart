import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A function that lets [Arrow]s self supply a [Widget] that is shown during the
/// arrow's flight from its position to the target's position.
typedef ArrowFlightShuttleBuilder = Widget Function(
  BuildContext flightContext,
  Animation<double> animation,
  ArrowFlightDirection flightDirection,
  BuildContext fromArrowContext,
  BuildContext toArrowContext,
);

typedef _OnFlightEnded = void Function(_ArrowFlight flight);

/// Direction of the arrow's flight.
enum ArrowFlightDirection {
  /// A flight from the arrow to the target.
  ///
  /// The animation goes from 0 to 1.
  ///
  /// If no custom [ArrowFlightShuttleBuilder] is supplied, the
  /// [Arrow] child is shown in flight.
  forward,

  /// A flight from the target to the arrow.
  ///
  /// The animation goes from 1 to 0.
  ///
  /// If no custom [ArrowFlightShuttleBuilder] is supplied, the target's
  /// [Arrow] child is shown in flight.
  reverse,
}

// The bounding box for context in global coordinates.
Rect _globalBoundingBoxFor(BuildContext context) {
  final RenderBox box = context.findRenderObject();
  assert(box != null && box.hasSize);
  return MatrixUtils.transformRect(
      box.getTransformTo(null), Offset.zero & box.size);
}

class Arrow extends StatefulWidget {
  const Arrow({
    Key key,
    @required this.tag,
    this.targetTag,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    @required this.animation,
    @required this.child,
  })  : assert(tag != null),
        assert(child != null),
        super(key: key);

  /// The identifier for this particular arrow.
  final Object tag;

  /// The identifier of the target.
  ///
  /// If [null] that means this arrow is only the target of another arrow.
  final Object targetTag;

  /// Defines how the destination arrow's bounds change as it flies from the starting
  /// position to the destination position.
  ///
  /// A arrow flight begins with the destination arrow's [child] aligned with the
  /// starting arrow's child. The [Tween<Rect>] returned by this callback is used
  /// to compute the arrow's bounds as the flight animation's value goes from 0.0
  /// to 1.0.
  ///
  /// If this property is null, the default, then the value of
  /// [ArrowController.createRectTween] is used. The [ArrowController] created by
  /// [MaterialApp] creates a [MaterialRectAreTween].
  final CreateRectTween createRectTween;

  /// The widget subtree that will "fly" from one the initial position to another.
  ///
  /// The appearance of this subtree should be similar to the appearance of
  /// the subtrees of any other arrows in the application with the [targetTag].
  /// Changes in scale and aspect ratio work well in arrow animations, changes
  /// in layout or composition do not.
  final Widget child;

  /// Optional override to supply a widget that's shown during the arrow's flight.
  ///
  /// When both the source and destination [Arrows]s provide a [flightShuttleBuilder],
  /// the destination's [flightShuttleBuilder] takes precedence.
  ///
  /// If none is provided, the destination Arrow child is shown in-flight
  /// by default.
  final ArrowFlightShuttleBuilder flightShuttleBuilder;

  /// Placeholder widget left in place as the Arrows's child once the flight takes off.
  ///
  /// By default, an empty SizedBox keeping the Arrow child's original size is
  /// left in place once the Arrow shuttle has taken flight.
  final TransitionBuilder placeholderBuilder;

  final Animation<double> animation;

  // Returns a map of all of the arrows in context, indexed by arrow tag.
  static Map<Object, _ArrowState> _allArrowsFor(BuildContext context) {
    assert(context != null);
    final Map<Object, _ArrowState> result = <Object, _ArrowState>{};
    void visitor(Element element) {
      if (element.widget is Arrow) {
        final StatefulElement arrow = element;
        final Arrow arrowWidget = element.widget;
        final Object tag = arrowWidget.tag;
        assert(tag != null);
        assert(() {
          if (result.containsKey(tag)) {
            throw FlutterError(
                'There are multiple arrows that share the same tag within a subtree.\n'
                'Within each subtree for which arrows are to be animated, '
                'each Arrow must have a unique non-null tag.\n'
                'In this case, multiple arrows had the following tag: $tag\n'
                'Here is the subtree for one of the offending arrows:\n'
                '${element.toStringDeep(prefixLineOne: "# ")}');
          }
          return true;
        }());
        final _ArrowState arrowState = arrow.state;
        result[tag] = arrowState;
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return result;
  }

  @override
  _ArrowState createState() => new _ArrowState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('tag', tag));
  }
}

class _ArrowState extends State<Arrow> {
  final GlobalKey _key = GlobalKey();
  Size _placeholderSize;

  void startFlight() {
    assert(mounted);
    final RenderBox box = context.findRenderObject();
    assert(box != null && box.hasSize);
    setState(() {
      _placeholderSize = box.size;
    });
  }

  void endFlight() {
    if (mounted) {
      setState(() {
        _placeholderSize = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_placeholderSize != null) {
      if (widget.placeholderBuilder == null) {
        return SizedBox(
          width: _placeholderSize.width,
          height: _placeholderSize.height,
        );
      } else {
        return widget.placeholderBuilder(context, widget.child);
      }
    }
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

/// Everything known about an arrow flight that's to be started or diverted.
class _ArrowFlightManifest {
  _ArrowFlightManifest({
    @required this.type,
    @required this.overlay,
    @required this.rect,
    @required this.fromArrow,
    @required this.toArrow,
    @required this.createRectTween,
    @required this.shuttleBuilder,
  }) : assert(fromArrow.widget.targetTag == toArrow.widget.tag);

  final ArrowFlightDirection type;
  final OverlayState overlay;
  final Rect rect;
  final _ArrowState fromArrow;
  final _ArrowState toArrow;
  final CreateRectTween createRectTween;
  final ArrowFlightShuttleBuilder shuttleBuilder;

  Object get tag => fromArrow.widget.tag;

  Object get targetTag => toArrow.widget.tag;

  Animation<double> get animation {
    return CurvedAnimation(
      parent: (type == ArrowFlightDirection.forward)
          ? toArrow.widget.animation
          : fromArrow.widget.animation,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  String toString() {
    return '_ArrowFlightManifest($type from $tag to $targetTag';
  }
}

/// Builds the in-flight arrow widget.
class _ArrowFlight {
  _ArrowFlight(this.onFlightEnded) {
    _proxyAnimation = ProxyAnimation()
      ..addStatusListener(_handleAnimationUpdate);
  }

  final _OnFlightEnded onFlightEnded;

  Tween<Rect> arrowRectTween;
  Widget shuttle;

  Animation<double> _arrowOpacity = kAlwaysCompleteAnimation;
  ProxyAnimation _proxyAnimation;
  _ArrowFlightManifest manifest;
  OverlayEntry overlayEntry;
  bool _aborted = false;

  Tween<Rect> _doCreateRectTween(Rect begin, Rect end) {
    final CreateRectTween createRectTween =
        manifest.toArrow.widget.createRectTween ?? manifest.createRectTween;
    if (createRectTween != null) return createRectTween(begin, end);
    return RectTween(begin: begin, end: end);
  }

  static final Animatable<double> _reverseTween =
      Tween<double>(begin: 1.0, end: 0.0);

  // The OverlayEntry WidgetBuilder callback for the hero's overlay.
  Widget _buildOverlay(BuildContext context) {
    assert(manifest != null);
    shuttle ??= manifest.shuttleBuilder(
      context,
      manifest.animation,
      manifest.type,
      manifest.fromArrow.context,
      manifest.toArrow.context,
    );
    assert(shuttle != null);

    return AnimatedBuilder(
      animation: _proxyAnimation,
      child: shuttle,
      builder: (BuildContext context, Widget child) {
        final RenderBox toArrowBox =
            manifest.toArrow.context?.findRenderObject();
        if (_aborted || toArrowBox == null || !toArrowBox.attached) {
          // The toArrow no longer exists or it's no longer the flight's destination.
          // Continue flying while fading out.
          if (_arrowOpacity.isCompleted) {
            _arrowOpacity = _proxyAnimation.drive(
              _reverseTween.chain(
                  CurveTween(curve: Interval(_proxyAnimation.value, 1.0))),
            );
          }
        } else if (toArrowBox.hasSize) {
          // The toArrow has been laid out. If it's no longer where the arrow animation is
          // supposed to end up then recreate the arrowRect tween.
          final Offset toArrowOrigin = toArrowBox.localToGlobal(Offset.zero);
          if (toArrowOrigin != arrowRectTween.end.topLeft) {
            final Rect arrowRectEnd = toArrowOrigin & arrowRectTween.end.size;
            arrowRectTween =
                _doCreateRectTween(arrowRectTween.begin, arrowRectEnd);
          }
        }

        final Rect rect = arrowRectTween.evaluate(_proxyAnimation);
        final Size size = manifest.rect.size;
        final RelativeRect offsets = RelativeRect.fromSize(rect, size);

        return Positioned(
          top: offsets.top,
          right: offsets.right,
          bottom: offsets.bottom,
          left: offsets.left,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Opacity(
                opacity: _arrowOpacity.value,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAnimationUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _proxyAnimation.parent = null;

      assert(overlayEntry != null);
      overlayEntry.remove();
      overlayEntry = null;

      manifest.fromArrow.endFlight();
      manifest.toArrow.endFlight();
      onFlightEnded(this);
    }
  }

  // The simple case: we're either starting a forward or a reverse animation.
  void start(_ArrowFlightManifest initialManifest) {
    assert(!_aborted);
    // assert(() {
    //   final Animation<double> initial = initialManifest.animation;
    //   assert(initial != null);
    //   final ArrowFlightDirection type = initialManifest.type;
    //   assert(type != null);
    //   switch (type) {
    //     case ArrowFlightDirection.reverse:
    //       return initial.value == 1.0 &&
    //           initial.status == AnimationStatus.reverse;
    //     case ArrowFlightDirection.forward:
    //       return initial.value == 0.0 &&
    //           initial.status == AnimationStatus.forward;
    //   }
    //   return null;
    // }());

    manifest = initialManifest;

    if (manifest.type == ArrowFlightDirection.reverse)
      _proxyAnimation.parent = ReverseAnimation(manifest.animation);
    else
      _proxyAnimation.parent = manifest.animation;

    manifest.fromArrow.startFlight();
    manifest.toArrow.startFlight();

    arrowRectTween = _doCreateRectTween(
      _globalBoundingBoxFor(manifest.fromArrow.context),
      _globalBoundingBoxFor(manifest.toArrow.context),
    );

    overlayEntry = OverlayEntry(builder: _buildOverlay);
    manifest.overlay.insert(overlayEntry);
  }

  void abort() {
    _aborted = true;
  }

  @override
  String toString() {
    final Object tag = manifest.tag;
    final Object targetTag = manifest.targetTag;
    return 'ArrowFlight(from: $tag, to: $targetTag, ${_proxyAnimation.parent})';
  }
}

/// Manages the [Arrow] transitions.
class ArrowController {
  /// Creates a arrow controller with the given [RectTween] constructor if any.
  ///
  /// The [createRectTween] argument is optional. If null, the controller uses a
  /// linear [Tween<Rect>].
  ArrowController({this.createRectTween});

  /// Used to create [RectTween]s that interpolate the position of arrows in flight.
  ///
  /// If null, the controller uses a linear [RectTween].
  final CreateRectTween createRectTween;

  // All of the arrows that are currently in the overlay and in motion.
  // Indexed by the arrow tag.
  final Map<Object, _ArrowFlight> _flights = <Object, _ArrowFlight>{};

  void startArrowTransition(
    BuildContext context,
    ArrowFlightDirection flightType,
  ) {
    final Rect rect = _globalBoundingBoxFor(context);

    final Map<Object, _ArrowState> arrows = Arrow._allArrowsFor(context);

    for (Object tag in arrows.keys) {
      final Arrow fromArrow = arrows[tag].widget;
      final Arrow toArrow = arrows[fromArrow.targetTag]?.widget;

      if (toArrow != null) {
        final ArrowFlightShuttleBuilder fromShuttleBuilder =
            fromArrow.flightShuttleBuilder;
        final ArrowFlightShuttleBuilder toShuttleBuilder =
            toArrow.flightShuttleBuilder;

        final _ArrowFlightManifest manifest = _ArrowFlightManifest(
          type: flightType,
          overlay: Overlay.of(context),
          rect: rect,
          fromArrow: arrows[tag],
          toArrow: arrows[fromArrow.targetTag],
          createRectTween: createRectTween,
          shuttleBuilder: toShuttleBuilder ??
              fromShuttleBuilder ??
              _defaultArrowFlightShuttleBuilder,
        );

        _flights[tag] = _ArrowFlight(_handleFlightEnded)..start(manifest);
      } else if (_flights[tag] != null) {
        _flights[tag].abort();
      }
    }
  }

  void _handleFlightEnded(_ArrowFlight flight) {
    _flights.remove(flight.manifest.tag);
  }

  static final ArrowFlightShuttleBuilder _defaultArrowFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    ArrowFlightDirection flightDirection,
    BuildContext fromArrowContext,
    BuildContext toArrowContext,
  ) {
    final Arrow toArrow = toArrowContext.widget;
    return toArrow.child;
  };
}
