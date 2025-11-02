import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'sign_in_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/theme_toggle_widget.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  final String userEmail;
  final String username;

  const SettingsScreen({
    Key? key,
    required this.userEmail,
    required this.username,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('Course Updates'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: Text('Quiz Reminders'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: Text('Achievements'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: Text('Comments & Messages'),
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Privacy Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Profile Visibility'),
                  subtitle: Text('Public'),
                  onTap: () {},
                ),
                ListTile(
                  title: Text('Show Progress'),
                  subtitle: Text('Only to followers'),
                  onTap: () {},
                ),
                ListTile(
                  title: Text('Activity Status'),
                  subtitle: Text('Visible to all'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download Your Data'),
          content: Text('Your learning progress and certificates will be exported as PDF.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Download started! Check your downloads folder.')),
                );
              },
              child: Text('Download'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Language & Region'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  title: Text('English'),
                  value: 'en',
                  groupValue: 'en',
                  onChanged: (value) {},
                ),
                RadioListTile(
                  title: Text('Spanish'),
                  value: 'es',
                  groupValue: 'en',
                  onChanged: (value) {},
                ),
                RadioListTile(
                  title: Text('French'),
                  value: 'fr',
                  groupValue: 'en',
                  onChanged: (value) {},
                ),
                RadioListTile(
                  title: Text('German'),
                  value: 'de',
                  groupValue: 'en',
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Help & Support'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email Support'),
                  subtitle: Text('support@learnease.com'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('Live Chat'),
                  subtitle: Text('Chat with our team'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Report a Bug'),
                  subtitle: Text('Help us improve'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.book),
                  title: Text('FAQ'),
                  subtitle: Text('Common questions'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About Learn Ease'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Learn Ease is a comprehensive learning platform designed to help you master Java and DBMS concepts with interactive courses, quizzes, and community support.',
                ),
                SizedBox(height: 16),
                Text(
                  '© 2024 Learn Ease. All rights reserved.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Color(0xFF1A237E);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
        actions: const [ThemeToggleWidget()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader('Account', isDark),
              SizedBox(height: 12),
              _buildSettingsTile(
                context: context,
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Update your profile information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        currentUsername: widget.username,
                        email: widget.userEmail,
                      ),
                    ),
                  );
                },
                isDark: isDark,
              ),
              SizedBox(height: 16),

              // Preferences Section
              _buildSectionHeader('Preferences', isDark),
              SizedBox(height: 12),
              _buildSettingsTile(
                context: context,
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {
                  _showNotificationSettings(context);
                },
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.privacy_tip,
                title: 'Privacy Settings',
                subtitle: 'Control your privacy',
                onTap: () {
                  _showPrivacySettings(context);
                },
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.language,
                title: 'Language & Region',
                subtitle: 'Set your preferred language',
                onTap: () {
                  _showLanguageSettings(context);
                },
                isDark: isDark,
              ),
              SizedBox(height: 16),

              // Data Section
              _buildSectionHeader('Data & Privacy', isDark),
              SizedBox(height: 12),
              _buildSettingsTile(
                context: context,
                icon: Icons.download,
                title: 'Download Learning Data',
                subtitle: 'Export your progress and certificates',
                onTap: () {
                  _showDownloadDialog(context);
                },
                isDark: isDark,
              ),
              SizedBox(height: 16),

              // Support Section
              _buildSectionHeader('Support', isDark),
              SizedBox(height: 12),
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help or report issues',
                onTap: () {
                  _showHelpSupport(context);
                },
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.info_outline,
                title: 'About App',
                subtitle: 'Version 1.0.0 | Learn Ease',
                onTap: () {
                  _showAboutApp(context);
                },
                isDark: isDark,
              ),
              SizedBox(height: 24),

              // Logout Button at bottom
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed ?? false) {
                      await _authService.clearTokens();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => SignInScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.logout, color: Colors.red.shade600),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Color(0xFF1A237E),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.blue.shade600,
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
