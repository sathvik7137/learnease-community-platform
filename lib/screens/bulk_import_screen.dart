import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import '../models/user_content.dart';
import '../services/user_content_service.dart';
import '../widgets/username_setup_dialog.dart';
import '../widgets/theme_toggle_widget.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final TextEditingController _fileContentController = TextEditingController();
  ContentType _selectedType = ContentType.topic;
  CourseCategory _selectedCategory = CourseCategory.java;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _username;
  List<Map<String, dynamic>> _parsedItems = [];
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await UserContentService.getUsername();
    if (username != null && username.isNotEmpty) {
      setState(() {
        _username = username;
      });
      return;
    }

    if (mounted) {
      final newUsername = await showUsernameSetupDialog(context);
      if (newUsername == null) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _username = newUsername;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json'],
      );

      if (result != null && result.files.isNotEmpty) {
        String content;
        
        // For web, use bytes property; for other platforms, use file path
        if (result.files.single.bytes != null) {
          // Web platform - use bytes
          content = String.fromCharCodes(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          // Desktop/mobile platforms - use file path
          final file = io.File(result.files.single.path!);
          content = await file.readAsString();
        } else {
          throw Exception('Cannot access file content');
        }

        setState(() {
          _fileContentController.text = content;
          _errorMessage = null;
          _successMessage = null;
          _parsedItems = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  void _parseFileContent() {
    final content = _fileContentController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or load file content';
      });
      return;
    }

    try {
      List<Map<String, dynamic>> items = [];

      // Try parsing as JSON array first
      if (content.startsWith('[')) {
        final jsonArray = jsonDecode(content) as List;
        items = jsonArray.cast<Map<String, dynamic>>();
      }
      // Try parsing as JSON objects separated by newlines
      else if (content.contains('\n')) {
        final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
        for (final line in lines) {
          try {
            final parsed = jsonDecode(line) as Map<String, dynamic>;
            items.add(parsed);
          } catch (e) {
            // Skip invalid JSON lines
            print('Skipping invalid line: $line');
          }
        }
      }
      // Try single JSON object
      else {
        final parsed = jsonDecode(content) as Map<String, dynamic>;
        items = [parsed];
      }

      if (items.isEmpty) {
        setState(() {
          _errorMessage = 'No valid items found in file. Please check the format.';
        });
        return;
      }

      setState(() {
        _parsedItems = items;
        _errorMessage = null;
        _successMessage = 'Found ${items.length} items ready to import';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing file: $e\n\nMake sure each line is valid JSON.';
        _parsedItems = [];
      });
    }
  }

  Future<void> _uploadAll() async {
    if (_parsedItems.isEmpty) {
      setState(() {
        _errorMessage = 'No items to upload. Please parse the file first.';
      });
      return;
    }

    if (_username == null) {
      setState(() {
        _errorMessage = 'Username not set. Please restart.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _uploadedCount = 0;
    });

    try {
      // Convert all parsed items to UserContent objects
      List<UserContent> contents = [];
      for (int i = 0; i < _parsedItems.length; i++) {
        try {
          final content = UserContentService.createContentFromJson(
            _parsedItems[i],
            _username!,
            _selectedCategory,
            defaultType: _selectedType,
          );
          if (content != null) {
            contents.add(content);
          }
        } catch (e) {
          print('Error creating content for item ${i + 1}: $e');
        }
      }

      if (contents.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No valid items could be created from the parsed data.';
        });
        return;
      }

      // Upload all at once using batch method
      final result = await UserContentService.batchAddContributions(contents);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadedCount = _parsedItems.length;
          
          final successCount = result['successCount'] ?? 0;
          final failureCount = result['failureCount'] ?? 0;
          
          _successMessage = '✅ Uploaded: $successCount/${_parsedItems.length}';
          
          if (failureCount > 0) {
            _errorMessage = '⚠️ Failed to upload: $failureCount items';
          }
        });

        // Show completion dialog
        if ((result['successCount'] ?? 0) > 0) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Bulk Import Complete'),
                content: Text(
                  'Successfully uploaded ${result['successCount']} items!\n'
                  'Total: ${result['totalCount']}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true); // Go back to community screen
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error uploading: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _fileContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Import Content'),
        actions: [
          const ThemeToggleWidget(),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
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
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Category selector
                  const Text(
                    'Course Category:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: CourseCategory.values.map((category) {
                      return ChoiceChip(
                        label: Text(_getCategoryLabel(category)),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // File picker buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Pick File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showTemplate,
                          icon: const Icon(Icons.description),
                          label: const Text('Template'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // File content editor
                  const Text(
                    'File Content (or paste JSON):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _fileContentController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: 'Paste JSON content here...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parse button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _parseFileContent,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Parse Content'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Show parsed items count
                  if (_parsedItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✅ Found ${_parsedItems.length} items',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preview: ${_parsedItems.take(2).map((item) => '• ${item['title'] ?? item['question'] ?? 'Item'}').join('\n')}${_parsedItems.length > 2 ? '\n• ... and ${_parsedItems.length - 2} more' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Progress indicator
                  if (_isLoading)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _uploadedCount / _parsedItems.length,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading: $_uploadedCount/${_parsedItems.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Upload button
                  ElevatedButton.icon(
                    onPressed: _isLoading || _parsedItems.isEmpty ? null : _uploadAll,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isLoading
                        ? 'Uploading...'
                        : 'Upload All (${_parsedItems.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  String _getTypeLabel(ContentType type) {
    return type.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
  }

  String _getCategoryLabel(CourseCategory category) {
    return category.toString().split('.').last.toUpperCase();
  }

  void _showTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Import Template'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'JSON Array Format:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '''[
  {
    "title": "Topic Name",
    "content": "Topic content here"
  },
  {
    "question": "Quiz question?",
    "options": ["A", "B", "C", "D"],
    "correctAnswer": 0
  }
]''',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[200]
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Or newline-separated JSON:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '''{"title": "Topic 1", "content": "..."}
{"title": "Topic 2", "content": "..."}
{"question": "Q1?", "options": [...]}''',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[200]
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Import Help'),
        content: const SingleChildScrollView(
          child: Text(
            '''How to use Bulk Import:

1. **Pick File**: Select a .txt or .json file from your device

2. **Or Paste JSON**: Manually paste your content in the text area

3. **Parse**: Click "Parse Content" to validate your JSON

4. **Review**: Check the preview of found items

5. **Upload**: Click "Upload All" to save all items at once

Supported Formats:
• JSON Array: [item1, item2, ...]
• Newline-separated JSON: item1\\nitem2\\n...
• Single JSON object: {...}

Tips:
• Each item must be valid JSON
• Use "Template" button to see examples
• Invalid lines are skipped
• Wait for upload to complete
            ''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
