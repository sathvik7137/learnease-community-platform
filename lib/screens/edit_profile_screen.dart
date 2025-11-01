import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_content_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentUsername;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.currentUsername,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _checkingUsername = false;
  List<String> _usernameSuggestions = [];
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    super.dispose();
  }

  // Check username availability when user stops typing
  Future<void> _onUsernameChanged() async {
    final username = _usernameController.text.trim();
    
    // Don't check if username is empty or unchanged
    if (username.isEmpty || username == widget.currentUsername) {
      setState(() {
        _usernameError = null;
        _usernameSuggestions = [];
      });
      return;
    }
    
    // Basic validation
    if (username.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters';
        _usernameSuggestions = [];
      });
      return;
    }
    
    if (username.length > 20) {
      setState(() {
        _usernameError = 'Username must be less than 20 characters';
        _usernameSuggestions = [];
      });
      return;
    }
    
    // Check if username is taken
    setState(() {
      _checkingUsername = true;
      _usernameError = null;
      _usernameSuggestions = [];
    });
    
    final isTaken = await UserContentService.isUsernameTaken(username);
    
    if (isTaken) {
      // Get suggestions for alternative usernames
      final suggestions = await UserContentService.suggestUsernames(username);
      if (mounted) {
        setState(() {
          _usernameError = 'This username is already taken';
          _usernameSuggestions = suggestions;
          _checkingUsername = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _usernameError = null;
          _usernameSuggestions = [];
          _checkingUsername = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim();
    
    // If username hasn't changed, just go back
    if (newUsername == widget.currentUsername) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService().updateUserProfile(username: newUsername);

      if (!mounted) return;

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
      } else if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate profile was updated
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.indigo.withOpacity(0.5),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade50.withOpacity(0.5),
              Colors.purple.shade50.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Icon
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.indigo.shade100,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email (Read-only)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.email, color: Colors.indigo, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.email,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Username field
                  Text(
                    'Username',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Stack(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Enter your username',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.person_outline, color: Colors.indigo),
                              suffixIcon: _checkingUsername
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                                        ),
                                      ),
                                    )
                                  : _usernameError == null && _usernameController.text.isNotEmpty && _usernameController.text != widget.currentUsername
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Username cannot be empty';
                              }
                              if (value.trim().length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              if (_usernameError != null) {
                                return _usernameError;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Show error message if username is taken
                  if (_usernameError != null && _usernameError!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _usernameError!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Show suggestions if username is taken
                  if (_usernameSuggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Try these suggestions:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _usernameSuggestions.map((suggestion) {
                                return GestureDetector(
                                  onTap: () {
                                    _usernameController.text = suggestion;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.indigo.shade300),
                                    ),
                                    child: Text(
                                      suggestion,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: Colors.indigo.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your username will be visible to other users in the community.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
