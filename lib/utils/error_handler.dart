import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Global error handler for production builds
class GlobalErrorHandler {
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kReleaseMode) {
        // Log to your backend or crash reporting service
        _logError(details.exception, details.stack);
      }
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kReleaseMode) {
        _logError(error, stack);
      }
      return true;
    };
  }

  static void _logError(dynamic error, StackTrace? stack) {
    // TODO: Send to your backend logging endpoint
    // Example: POST to /api/logs/errors
    debugPrint('ERROR: $error');
    if (stack != null) {
      debugPrint('STACK: $stack');
    }
  }

  /// Wrap your app with error boundary
  static Widget errorBoundary(Widget child) {
    return ErrorBoundary(child: child);
  }
}

/// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    // Reset error state
    _hasError = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'re sorry for the inconvenience. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _error = null;
                      });
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!kReleaseMode) {
        return ErrorWidget(details.exception);
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _hasError = true;
          _error = details.exception;
        });
      });

      return Container();
    };
  }
}
