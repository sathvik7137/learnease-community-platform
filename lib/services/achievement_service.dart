import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import 'sound_service.dart';

class AchievementService {
  static const String _achievementsKey = 'unlockedAchievements';
  
  // Get unlocked achievements
  static Future<List<String>> getUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_achievementsKey) ?? [];
  }
  
  // Unlock an achievement
  static Future<bool> unlockAchievement(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = await getUnlockedAchievements();
    
    if (!unlocked.contains(achievementId)) {
      unlocked.add(achievementId);
      await prefs.setStringList(_achievementsKey, unlocked);
      await SoundService.successFeedback();
      return true;
    }
    
    return false;
  }
  
  // Check if achievement is unlocked
  static Future<bool> isUnlocked(String achievementId) async {
    final unlocked = await getUnlockedAchievements();
    return unlocked.contains(achievementId);
  }
  
  // Get achievement progress
  static Future<Map<String, int>> getAchievementProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> progress = {};
    
    for (final achievement in achievements) {
      progress[achievement.id] = prefs.getInt('progress_${achievement.id}') ?? 0;
    }
    
    return progress;
  }
  
  // Update achievement progress and check if unlocked
  static Future<Achievement?> updateProgress(
    AchievementType type,
    int currentCount,
  ) async {
    // Find relevant achievements
    final relevantAchievements = achievements.where((a) => a.type == type).toList();
    
    for (final achievement in relevantAchievements) {
      final isAlreadyUnlocked = await isUnlocked(achievement.id);
      
      if (!isAlreadyUnlocked) {
        // Save progress locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('progress_${achievement.id}', currentCount);

        // Check if achievement should be unlocked
        if (currentCount >= achievement.requiredCount) {
          final wasUnlocked = await unlockAchievement(achievement.id);
          if (wasUnlocked) {
            return achievement;
          }
        }
      }
    }
    
    return null;
  }
  
  // Get unlocked count
  static Future<int> getUnlockedCount() async {
    final unlocked = await getUnlockedAchievements();
    return unlocked.length;
  }
  
  // Get total achievements count
  static int getTotalCount() {
    return achievements.length;
  }
}
