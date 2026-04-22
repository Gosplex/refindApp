
import '../../saved_posts/models/saved_post_model.dart';

class AnalyticsModel {
  final double revisitRate;

  final int backlogCount;

  final int currentStreak;

  final int weeklySaved;
  final int weeklyRevisited;
  final double weeklyImprovement;

  final int totalReminders;
  final int revisitedAfterReminder;
  final double reminderEffectiveness;

  final double avgTimeToRevisitDays;

  final String? topSavedSource;
  final String? topRevisitedSource;

  final String? topCollection;
  final String? leastUsedCollection;

  final List<SavedPost> topLinks;

  const AnalyticsModel({
    required this.revisitRate,
    required this.backlogCount,
    required this.currentStreak,
    required this.weeklySaved,
    required this.weeklyRevisited,
    required this.weeklyImprovement,
    required this.totalReminders,
    required this.revisitedAfterReminder,
    required this.reminderEffectiveness,
    required this.avgTimeToRevisitDays,
    this.topSavedSource,
    this.topRevisitedSource,
    this.topCollection,
    this.leastUsedCollection,
    required this.topLinks,
  });
}