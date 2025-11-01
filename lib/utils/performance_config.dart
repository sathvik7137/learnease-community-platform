import 'package:flutter/material.dart';

/// Global performance configuration for smooth animations and responsive UI
class PerformanceConfig {
  // Animation durations - optimized for smooth, snappy feel
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Page transition duration
  static const Duration pageTransition = Duration(milliseconds: 200);
  
  // Button feedback duration
  static const Duration buttonFeedback = Duration(milliseconds: 80);
  
  // Scroll physics for smooth scrolling
  static const ScrollPhysics defaultScrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
  
  // Curves for smooth animations
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve buttonCurve = Curves.easeInOutCirc;
  static const Curve pageCurve = Curves.fastLinearToSlowEaseIn;
  
  /// Recommended list view settings for performance
  static const int preloadItemCount = 10; // Items to cache ahead
  static const double cacheExtent = 500.0; // Pixels to cache
  
  /// Get optimized scroll behavior
  static ScrollBehavior getScrollBehavior() {
    return const ScrollBehavior().copyWith(
      scrollbars: true,
      overscroll: true,
      physics: defaultScrollPhysics,
    );
  }
}

/// Optimized page route with smooth transitions
class OptimizedPageRoute<T> extends MaterialPageRoute<T> {
  OptimizedPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
    builder: builder,
    settings: settings,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
  );

  @override
  Duration get transitionDuration => PerformanceConfig.pageTransition;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: PerformanceConfig.pageCurve)),
      ),
      child: child,
    );
  }
}

/// Optimized fade page route
class OptimizedFadeRoute<T> extends MaterialPageRoute<T> {
  OptimizedFadeRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
    builder: builder,
    settings: settings,
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
