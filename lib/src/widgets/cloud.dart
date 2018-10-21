import 'package:flutter/widgets.dart';
import 'package:hashwag/src/rendering/cloud.dart';

class Cloud extends MultiChildRenderObjectWidget {
  Cloud({
    Key key,
    this.placementDelegate = const ArchimedeanSpiralPlacementDelegate(),
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  /// The delegate that controls the placement of the children.
  final CloudPlacementDelegate placementDelegate;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCloud(
      placementDelegate: placementDelegate,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCloud renderObject) {
    renderObject..placementDelegate = placementDelegate;
  }
}
