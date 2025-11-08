import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'sign_in_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/theme_toggle_button.dart';
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
      builder: (context) => AlertDialog(
        title: const Text('About Learn Ease'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Learn Ease is a comprehensive learning platform designed to help you master Java and DBMS concepts with interactive courses, quizzes, and community support.',
              ),
              const SizedBox(height: 16),
              const Text(
                '© 2024 Learn Ease. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ WARNING: This action is IRREVERSIBLE',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deleting your account will permanently remove:',
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Your profile and all personal data'),
                  Text('• All learning progress and achievements'),
                  Text('• All quiz results and certificates'),
                  Text('• All community contributions'),
                  Text('• All saved preferences and settings'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'An OTP will be sent to your email for verification.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedWithAccountDeletion(context);
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedWithAccountDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please confirm your email address to proceed with account deletion:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.userEmail,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestDeleteAccountOtp(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDeleteAccountOtp(BuildContext context) async {
    try {
      final result = await _authService.sendDeleteAccountOtp(widget.userEmail);
      
      if (!mounted) return;

      if (result['sent'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        _showDeleteAccountOtpDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error'] ?? 'Failed to send OTP'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountOtpDialog(BuildContext context) {
    final otpController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Enter OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the OTP sent to your email:'),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, letterSpacing: 4),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: '000000',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'OTP is valid for 10 minutes',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (otpController.text.isEmpty || otpController.text.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final result = await _authService.deleteAccount(
                          widget.userEmail,
                          otpController.text,
                        );

                        if (!mounted) return;

                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Account deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await Future.delayed(const Duration(seconds: 1));
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                              (route) => false,
                            );
                          }
                        } else {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ ${result['error'] ?? 'Failed to delete account'}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
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
        actions: const [
          ThemeToggleButton(size: 24, padding: EdgeInsets.only(right: 16)),
        ],
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

              // Danger Zone Section
              _buildSectionHeader('Danger Zone', isDark),
              SizedBox(height: 12),
              _buildSettingsTile(
                context: context,
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and data',
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
                isDark: isDark,
                isDestructive: true,
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
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? Colors.red.shade300
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red.shade600 : Colors.blue.shade600,
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
                      color: isDestructive
                          ? Colors.red.shade600
                          : (isDark ? Colors.white : Colors.black87),
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
