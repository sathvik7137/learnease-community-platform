import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleWidget extends StatelessWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        
        return GestureDetector(
          onTap: () {
            themeProvider.toggleTheme();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.amber.withOpacity(0.5) : Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: isDark ? 0.5 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.sunny,
                    color: isDark ? Colors.amber : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isDark ? 'Dark' : 'Light',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.amber : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Full Theme Settings Card
class ThemeSettingsCard extends StatelessWidget {
  const ThemeSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final colors = Theme.of(context).colorScheme;
        
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Theme',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Choose between light and dark mode',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildThemeOption(
                        context,
                        title: 'Light Mode',
                        icon: Icons.sunny,
                        isSelected: !isDark,
                        onTap: () => themeProvider.setTheme(ThemeMode.light),
                      ),
                      Divider(
                        color: colors.outline.withOpacity(0.2),
                        height: 12,
                      ),
                      _buildThemeOption(
                        context,
                        title: 'Dark Mode',
                        icon: Icons.dark_mode,
                        isSelected: isDark,
                        onTap: () => themeProvider.setTheme(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.outline,
                  width: 2,
                ),
                color: isSelected ? colors.primary.withOpacity(0.2) : null,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: colors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? colors.primary : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
