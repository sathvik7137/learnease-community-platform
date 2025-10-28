import 'package:flutter/services.dart';

class SoundService {
  static bool _soundEnabled = true;
  static bool _hapticEnabled = true;

  // Enable/disable sounds
  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  // Enable/disable haptics
  static void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }

  // Play tap sound (using system sound for web compatibility)
  static Future<void> playTapSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Use system sound for web compatibility
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silently fail if sound not available
    }
  }

  // Play success sound
  static Future<void> playSuccessSound() async {
    if (!_soundEnabled) return;
    
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Silently fail
    }
  }

  // Haptic feedback for light tap
  static Future<void> lightHaptic() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently fail if haptic not available
    }
  }

  // Haptic feedback for medium tap
  static Future<void> mediumHaptic() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail
    }
  }

  // Haptic feedback for selection change
  static Future<void> selectionHaptic() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail
    }
  }

  // Vibrate for success/achievement (using HapticFeedback)
  static Future<void> successVibration() async {
    if (!_hapticEnabled) return;
    
    try {
      // Use heavy impact for success
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail
    }
  }

  // Combined tap feedback (sound + haptic)
  static Future<void> tapFeedback() async {
    await Future.wait([
      playTapSound(),
      lightHaptic(),
    ]);
  }

  // Combined success feedback
  static Future<void> successFeedback() async {
    await Future.wait([
      playSuccessSound(),
      successVibration(),
    ]);
  }
}
