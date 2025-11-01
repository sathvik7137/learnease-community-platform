import 'package:flutter/material.dart';
import '../services/user_content_service.dart';

class UsernameSetupDialog extends StatefulWidget {
  const UsernameSetupDialog({super.key});

  @override
  State<UsernameSetupDialog> createState() => _UsernameSetupDialogState();
}

class _UsernameSetupDialogState extends State<UsernameSetupDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final username = _controller.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a username';
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _errorMessage = 'Username must be at least 3 characters';
      });
      return;
    }

    if (username.length > 20) {
      setState(() {
        _errorMessage = 'Username must be less than 20 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check uniqueness with backend
    final taken = await UserContentService.isUsernameTaken(username);
    if (taken) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Username is already taken. Please choose another.';
      });
      return;
    }

    await UserContentService.setUsername(username);

    if (mounted) {
      Navigator.of(context).pop(username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Welcome! 👋'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your username to start contributing to the community!',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'e.g., JavaExpert',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
              prefixIcon: const Icon(Icons.person),
            ),
            maxLength: 20,
            onSubmitted: (_) => _saveUsername(),
          ),
          const SizedBox(height: 8),
          Text(
            'This name will appear on your contributions',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUsername,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue'),
        ),
      ],
    );
  }
}

// Helper function to show the dialog
Future<String?> showUsernameSetupDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UsernameSetupDialog(),
  );
}
