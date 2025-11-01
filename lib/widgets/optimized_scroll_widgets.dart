import 'package:flutter/material.dart';
import '../utils/performance_config.dart';

/// Optimized ListView with smooth scrolling and better performance
class OptimizedListView extends ListView {
  OptimizedListView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    Widget? prototypeItem,
    bool shrinkWrap = false,
    double cacheExtent = 500.0,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    required List<Widget> children,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics ?? PerformanceConfig.defaultScrollPhysics,
    padding: padding,
    itemExtent: itemExtent,
    prototypeItem: prototypeItem,
    shrinkWrap: shrinkWrap,
    cacheExtent: cacheExtent,
    semanticChildCount: semanticChildCount,
    dragStartBehavior: dragStartBehavior,
    keyboardDismissBehavior: keyboardDismissBehavior,
    restorationId: restorationId,
    clipBehavior: clipBehavior,
    children: children,
  );

  /// Factory for builder pattern with optimized defaults
  factory OptimizedListView.builder({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    Widget? prototypeItem,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double cacheExtent = 500.0,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return OptimizedListView(
      key: key,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics ?? PerformanceConfig.defaultScrollPhysics,
      padding: padding,
      itemExtent: itemExtent,
      prototypeItem: prototypeItem,
      shrinkWrap: false,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      children: [
        for (int i = 0; i < itemCount; i++)
          if (addAutomaticKeepAlives)
            AutomaticKeepAliveWrapper(child: itemBuilder(null, i))
          else
            itemBuilder(null, i),
      ],
    );
  }
}

/// Wrapped widget that keeps itself alive during scroll
class AutomaticKeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const AutomaticKeepAliveWrapper({Key? key, required this.child})
      : super(key: key);

  @override
  State<AutomaticKeepAliveWrapper> createState() =>
      _AutomaticKeepAliveWrapperState();
}

class _AutomaticKeepAliveWrapperState extends State<AutomaticKeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

/// Optimized single child scroll view with smooth physics
class OptimizedSingleChildScrollView extends SingleChildScrollView {
  OptimizedSingleChildScrollView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    EdgeInsetsGeometry? padding,
    bool? primary,
    ScrollPhysics? physics,
    ScrollController? controller,
    Widget? child,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    Clip clipBehavior = Clip.hardEdge,
    String? restorationId,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    padding: padding,
    primary: primary,
    physics: physics ?? PerformanceConfig.defaultScrollPhysics,
    controller: controller,
    dragStartBehavior: dragStartBehavior,
    clipBehavior: clipBehavior,
    restorationId: restorationId,
    child: child,
  );
}

/// Optimized RefreshIndicator with snappy refresh
class OptimizedRefreshIndicator extends RefreshIndicator {
  OptimizedRefreshIndicator({
    Key? key,
    required Future<void> Function() onRefresh,
    required Widget child,
    Color? color,
    Color? backgroundColor,
    double displacement = 40.0,
    EdgeInsetsGeometry? margin,
    double strokeWidth = RefreshIndicator.defaultStrokeWidth,
    double triggerMode = 0.0,
    ScrollNotificationPredicate notificationPredicate = defaultScrollNotificationPredicate,
    String? semanticsLabel,
    String? semanticsValue,
  }) : super(
    key: key,
    onRefresh: onRefresh,
    child: child,
    color: color,
    backgroundColor: backgroundColor,
    displacement: displacement,
    margin: margin,
    strokeWidth: strokeWidth,
    triggerMode: RefreshIndicatorTriggerMode.onEdge,
    notificationPredicate: notificationPredicate,
    semanticsLabel: semanticsLabel,
    semanticsValue: semanticsValue,
  );
}
