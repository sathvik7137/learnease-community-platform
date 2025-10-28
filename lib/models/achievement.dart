class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredCount;
  final AchievementType type;
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredCount,
    required this.type,
  });
}

enum AchievementType {
  topicsCompleted,
  quizzesTaken,
  perfectScore,
  learningStreak,
  courseCompleted,
}

// Predefined achievements
final List<Achievement> achievements = [
  Achievement(
    id: 'first_steps',
    title: 'First Steps',
    description: 'Complete your first topic',
    icon: '🎯',
    requiredCount: 1,
    type: AchievementType.topicsCompleted,
  ),
  Achievement(
    id: 'getting_started',
    title: 'Getting Started',
    description: 'Complete 5 topics',
    icon: '⭐',
    requiredCount: 5,
    type: AchievementType.topicsCompleted,
  ),
  Achievement(
    id: 'knowledge_seeker',
    title: 'Knowledge Seeker',
    description: 'Complete 10 topics',
    icon: '📚',
    requiredCount: 10,
    type: AchievementType.topicsCompleted,
  ),
  Achievement(
    id: 'quiz_master',
    title: 'Quiz Master',
    description: 'Take 10 quizzes',
    icon: '🎓',
    requiredCount: 10,
    type: AchievementType.quizzesTaken,
  ),
  Achievement(
    id: 'perfectionist',
    title: 'Perfectionist',
    description: 'Get a perfect score',
    icon: '💯',
    requiredCount: 1,
    type: AchievementType.perfectScore,
  ),
  Achievement(
    id: 'week_warrior',
    title: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: '🔥',
    requiredCount: 7,
    type: AchievementType.learningStreak,
  ),
  Achievement(
    id: 'java_champion',
    title: 'Java Champion',
    description: 'Complete Java course',
    icon: '☕',
    requiredCount: 1,
    type: AchievementType.courseCompleted,
  ),
  Achievement(
    id: 'database_guru',
    title: 'Database Guru',
    description: 'Complete DBMS course',
    icon: '🗄️',
    requiredCount: 1,
    type: AchievementType.courseCompleted,
  ),
];
