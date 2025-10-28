import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String progressKey = 'user_progress';
  static const String exerciseKey = 'exercise_progress';
  
  // Save progress for a specific topic
  static Future<void> saveProgress(String topicId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> progressData = {};
    final String? storedData = prefs.getString(progressKey);
    if (storedData != null) {
      progressData = jsonDecode(storedData) as Map<String, dynamic>;
    }
    progressData[topicId] = score;
    await prefs.setString(progressKey, jsonEncode(progressData));
  }

  // Get progress for a specific topic
  static Future<int> getTopicProgress(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(progressKey);
    if (storedData != null) {
      final Map<String, dynamic> progressData = jsonDecode(storedData) as Map<String, dynamic>;
      return progressData[topicId] as int? ?? 0;
    }
    return 0;
  }

  // Get overall course progress (percentage)
  static Future<double> getCourseProgress(List<String> topicIds) async {
    int completedTopics = 0;
    
    for (final topicId in topicIds) {
      final score = await getTopicProgress(topicId);
      if (score > 0) {
        completedTopics++;
      }
    }
    
    if (topicIds.isEmpty) return 0.0;
    return completedTopics / topicIds.length;
  }
  
  // Save exercise score (for fill-in-the-blanks, etc.)
  static Future<void> saveExerciseScore(String topicName, String exerciseType, int score) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> exerciseData = {};
    final String? storedData = prefs.getString(exerciseKey);
    if (storedData != null) {
      exerciseData = jsonDecode(storedData) as Map<String, dynamic>;
    }
    final String key = '${exerciseType}_$topicName';
    exerciseData[key] = score;
    await prefs.setString(exerciseKey, jsonEncode(exerciseData));
  }

  // Get exercise score
  static Future<int?> getExerciseScore(String topicName, String exerciseType) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(exerciseKey);
    if (storedData != null) {
      final String key = '${exerciseType}_$topicName';
      final Map<String, dynamic> exerciseData = jsonDecode(storedData) as Map<String, dynamic>;
      return exerciseData[key] as int?;
    }
    return null;
  }
}
