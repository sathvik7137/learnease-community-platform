import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final double? size;
  final EdgeInsets? padding;
  final Color? lightModeColor;
  final Color? darkModeColor;

  const ThemeToggleButton({
    Key? key,
    this.size,
    this.padding,
    this.lightModeColor,
    this.darkModeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
        
        return Padding(
          padding: padding ?? const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                themeProvider.toggleTheme();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    key: ValueKey<bool>(isDarkMode),
                    size: size ?? 24,
                    color: isDarkMode
                        ? (darkModeColor ?? Colors.amber[300])
                        : (lightModeColor ?? Colors.indigo[700]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
