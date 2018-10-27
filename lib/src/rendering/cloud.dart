import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

abstract class CloudPlacementDelegate {
  double get ratio;

  /// Returns an offset for the specified iteration.
  ///
  /// For a given iteration, the offset should be unique.
  Offset getOffset(int iteration, double ratio);
}

class ArchimedeanSpiralPlacementDelegate implements CloudPlacementDelegate {
  const ArchimedeanSpiralPlacementDelegate({
    this.ratio,
  });

  final double ratio;

  Offset getOffset(int iteration, double ratio) {
    ratio = this.ratio ?? ratio;
    final double ratioX = ratio >= 1 ? ratio : 1.0;
    final double ratioY = ratio <= 1 ? ratio : 1.0;
    final double t = iteration / 10.0;
    final double x = ratioX * t * math.cos(t);
    final double y = ratioY * t * math.sin(t);
    return Offset(x, y);
  }
}

class CloudParentData extends ContainerBoxParentData<RenderBox> {
  // The index of the child in the children list.
  int index;

  /// The child's width.
  double width;

  /// The child's height.
  double height;

  Rect get rect => Rect.fromLTWH(
        offset.dx,
        offset.dy,
        width,
        height,
      );
}

class RenderCloud extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, CloudParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, CloudParentData> {
  RenderCloud({
    CloudPlacementDelegate placementDelegate,
    List<RenderBox> children,
  })  : assert(placementDelegate != null),
        _placementDelegate = placementDelegate {
    addAll(children);
  }

  bool _hasVisualOverflow = false;

  /// The delegate that controls the placement of the children.
  CloudPlacementDelegate get placementDelegate => _placementDelegate;
  CloudPlacementDelegate _placementDelegate;
  set placementDelegate(CloudPlacementDelegate value) {
    assert(value != null);
    if (_placementDelegate == value) {
      return;
    }
    _placementDelegate = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! CloudParentData)
      child.parentData = CloudParentData();
  }

  @override
  void performLayout() {
    _hasVisualOverflow = false;

    if (childCount == 0) {
      size = constraints.smallest;
      assert(size.isFinite);
      return;
    }

    Rect bounds;

    final Size maxSize = constraints.biggest;
    final double ratio =
        maxSize.isFinite ? maxSize.width / maxSize.height : 1.0;

    RenderBox child = firstChild;
    int index = 0;
    while (child != null) {
      final CloudParentData childParentData = child.parentData;
      childParentData.index = index;

      child.layout(constraints, parentUsesSize: true);

      final Size childSize = child.size;
      childParentData.width = childSize.width;
      childParentData.height = childSize.height;

      // Place the child.
      if (childParentData.index == 0) {
        // The first child is always at the center.
        childParentData.offset = Offset(
          -childParentData.width / 2,
          -childParentData.height / 2,
        );
        bounds = childParentData.rect;
      } else {
        // Place the child following the placement strategy
        // until it does not overlap any previous child.
        final int dt = 1;
        int iteration = -dt;
        do {
          childParentData.offset = placementDelegate.getOffset(
            iteration += dt,
            ratio,
          );

          // In order to avoid vertical elements to be stacked at the same
          // place, we move the element of its size and repeat the operation.
          if (_overlapsPreviousElement(childParentData)) {
            childParentData.offset -=
                Offset(childParentData.width, childParentData.height);
          }
        } while (_overlapsPreviousElement(childParentData));

        bounds = bounds.expandToInclude(childParentData.rect);
      }

      child = childParentData.nextSibling;
      index++;
    }

    size = constraints
        .tighten(width: bounds.width, height: bounds.height)
        .smallest;

    _hasVisualOverflow =
        size.width < bounds.width || size.height < bounds.height;

    // Center the cloud.
    Offset boundsCenter = bounds.center;
    Offset cloudCenter = size.center(Offset.zero);
    Offset translation = cloudCenter - boundsCenter;

    // Move the whole cloud to the center.
    child = firstChild;
    while (child != null) {
      final CloudParentData childParentData = child.parentData;
      childParentData.offset += translation;
      child = childParentData.nextSibling;
    }
  }

  bool _overlapsPreviousElement(CloudParentData data) {
    RenderBox child = firstChild;
    CloudParentData childParentData = child.parentData;
    while (child != null && childParentData.index < data.index) {
      if (data.rect.overlaps(childParentData.rect)) {
        return true;
      }
      child = childParentData.nextSibling;
      childParentData = child.parentData;
    }
    return false;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  bool hitTestChildren(HitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow)
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        defaultPaint,
      );
    else
      defaultPaint(context, offset);
  }
}
