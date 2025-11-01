import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_content.dart';
import '../services/user_content_service.dart';
import '../widgets/username_setup_dialog.dart';
import 'bulk_import_screen.dart';

class AddContentScreen extends StatefulWidget {
  final UserContent? existingContent; // For editing
  
  const AddContentScreen({super.key, this.existingContent});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  final TextEditingController _jsonController = TextEditingController();
  ContentType _selectedType = ContentType.topic;
  CourseCategory _selectedCategory = CourseCategory.java;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    
    // If editing, populate with existing content
    if (widget.existingContent != null) {
      _selectedType = widget.existingContent!.type;
      _selectedCategory = widget.existingContent!.category;
      final contentWithType = {
        'type': _selectedType.toString().split('.').last,
        ...widget.existingContent!.content,
      };
      _jsonController.text = _prettyPrintJson(contentWithType);
    }
  }

  Future<void> _loadUsername() async {
    final username = await UserContentService.getUsername();

    if (username != null && username.isNotEmpty) {
      setState(() {
        _username = username;
      });
      return;
    }

    // If we're editing existing content, prefer the existing contribution's
    // author name and persist it silently so we don't prompt the user again.
    if (widget.existingContent != null) {
      final existingAuthor = widget.existingContent!.authorName;
      if (existingAuthor.isNotEmpty) {
        await UserContentService.setUsername(existingAuthor);
        if (mounted) {
          setState(() {
            _username = existingAuthor;
          });
        }
        return;
      }
    }

    // Otherwise show the username setup dialog as before
    if (mounted) {
      final newUsername = await showUsernameSetupDialog(context);
      if (newUsername == null) {
        // User cancelled
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _username = newUsername;
      });
    }
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    // Use Dart's JSON encoder with indentation to produce valid JSON
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      // Fallback: return a compact json string
      return jsonEncode(json);
    }
  }

  void _loadTemplate() {
    final template = ContentTemplates.getTemplate(_selectedType);
    setState(() {
      _jsonController.text = template;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _submitContent() async {
    if (_username == null) {
      setState(() {
        _errorMessage = 'Username not set. Please restart the app.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Validate JSON
    final jsonString = _jsonController.text.trim();
    Map<String, dynamic> parsedJson;
    try {
      parsedJson = UserContentService.validateAndParseJson(jsonString) as Map<String, dynamic>;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e is FormatException ? e.message : 'Invalid JSON format. Please check your syntax.';
      });
      return;
    }

    // Save or update
    bool success;
    if (widget.existingContent != null) {
      // When editing, users may have included a 'type' key in the JSON editor from templates.
      // Remove it to avoid duplication/conflict because 'type' is stored separately.
      parsedJson.remove('type');

      // Update existing - directly update content without creating new UserContent
      final updatedContent = widget.existingContent!.copyWith(
        content: parsedJson,
        category: _selectedCategory,
      );
      success = await UserContentService.updateContribution(
        widget.existingContent!.id,
        updatedContent,
      );
    } else {
      // Add new - create UserContent from JSON
      // Pass the selected type as default in case JSON doesn't have 'type' field
      final content = UserContentService.createContentFromJson(
        parsedJson,
        _username!,
        _selectedCategory,
        defaultType: _selectedType,
      );
      
      if (content == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid content format. Please check the template.';
        });
        return;
      }
      
      success = await UserContentService.addContribution(content);
    }

    if (success) {
      setState(() {
        _isLoading = false;
        _successMessage = widget.existingContent != null
            ? 'Content updated successfully! ✅'
            : 'Content added successfully! ✅';
      });
      
      // Wait a moment then go back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save content. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingContent != null ? 'Edit Content' : 'Add Content'),
        actions: [
          // Bulk import button (only for new content, not editing)
          if (widget.existingContent == null)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BulkImportScreen()),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context, true); // Return to community screen
                }
              },
              tooltip: 'Bulk Import',
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: _username == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Username display
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Contributing as: $_username',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Content type selector
                  const Text(
                    'Content Type:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ContentType.values.map((type) {
                      return ChoiceChip(
                        label: Text(_getTypeLabel(type)),
                        selected: _selectedType == type,
                        onSelected: widget.existingContent == null
                            ? (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedType = type;
                                    _errorMessage = null;
                                    _successMessage = null;
                                  });
                                }
                              }
                            : null, // Disable when editing
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Course category selector
                  const Text(
                    'Course Category:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.code, size: 18),
                              SizedBox(width: 4),
                              Text('Java'),
                            ],
                          ),
                          selected: _selectedCategory == CourseCategory.java,
                          onSelected: widget.existingContent == null
                              ? (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = CourseCategory.java;
                                    });
                                  }
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.storage, size: 18),
                              SizedBox(width: 4),
                              Text('DBMS'),
                            ],
                          ),
                          selected: _selectedCategory == CourseCategory.dbms,
                          onSelected: widget.existingContent == null
                              ? (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = CourseCategory.dbms;
                                    });
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Load template button
                  if (widget.existingContent == null)
                    ElevatedButton.icon(
                      onPressed: _loadTemplate,
                      icon: const Icon(Icons.file_copy),
                      label: const Text('Load Template'),
                    ),
                  const SizedBox(height: 16),
                  
                  // JSON input field
                  const Text(
                    'Content (JSON format):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _jsonController,
                    maxLines: 20,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Paste your JSON content here...',
                      errorText: _errorMessage,
                      helperText: 'Tap "Load Template" to see the format',
                      helperMaxLines: 2,
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  
                  // Success message
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitContent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.existingContent != null
                                ? 'Update Content'
                                : 'Submit Content',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.topic:
        return '📚 Topic';
      case ContentType.quiz:
        return '❓ Quiz';
      case ContentType.fillBlank:
        return '✍️ Fill Blank';
      case ContentType.codeExample:
        return '💻 Code Example';
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Add Content'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '1. Select the content type you want to add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('2. Tap "Load Template" to see the JSON format'),
              const SizedBox(height: 8),
              const Text('3. Edit the template with your content'),
              const SizedBox(height: 8),
              const Text('4. Make sure to keep the JSON format valid'),
              const SizedBox(height: 8),
              const Text('5. Tap "Submit Content" to save'),
              const SizedBox(height: 16),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Use \\n for new lines in strings'),
              const Text('• Keep quotes around string values'),
              const Text('• Arrays use square brackets [ ]'),
              const Text('• Don\'t forget commas between items'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
