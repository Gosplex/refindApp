import '../../saved_posts/models/saved_post_model.dart';
import '../models/analytics_model.dart';
import '../models/collection_stats.dart';
import '../models/reminder_stats.dart';
import '../models/source_stats.dart';
import '../models/weekly_stats.dart';

class AnalyticsService {
  static AnalyticsModel generate(List<SavedPost> posts, Map<String, String> collectionMap) {
    final total = posts.length;

    final revisitedPosts = posts.where((p) => p.visitCount > 0).toList();

    final revisitRate = total == 0 ? 0 : (revisitedPosts.length / total) * 100;

    final backlogCount = posts.where((p) => p.visitCount == 0).length;

    final currentStreak = _calculateStreak(posts);

    final weekly = _weeklyStats(posts);

    final reminderStats = _reminderStats(posts);

    final avgTime = _avgTimeToRevisit(posts);

    final sourceStats = _sourceStats(posts);

    final collectionStats = _collectionStats(posts, collectionMap);

    final topLinks = _topLinks(posts);

    return AnalyticsModel(
      revisitRate: (revisitRate ?? 0).toDouble(),
      backlogCount: backlogCount,
      currentStreak: currentStreak,
      weeklySaved: weekly.saved,
      weeklyRevisited: weekly.revisited,
      weeklyImprovement: weekly.improvement,
      totalReminders: reminderStats.totalReminders,
      revisitedAfterReminder: reminderStats.revisitedAfterReminder,
      reminderEffectiveness: reminderStats.effectiveness,
      avgTimeToRevisitDays: avgTime,
      topSavedSource: sourceStats.topSaved,
      topRevisitedSource: sourceStats.topRevisited,
      topCollection: collectionStats.topCollection,
      leastUsedCollection: collectionStats.leastUsedCollection,
      topLinks: topLinks,
    );
  }

  // STREAK
  static int _calculateStreak(List<SavedPost> posts) {
    final visitedDates =
        posts
            .where((p) => p.lastVisitedAt != null)
            .map(
              (p) => DateTime(
                p.lastVisitedAt!.year,
                p.lastVisitedAt!.month,
                p.lastVisitedAt!.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < visitedDates.length; i++) {
      final expected = DateTime(today.year, today.month, today.day - i);

      if (visitedDates.contains(expected)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // WEEKLY
  static WeeklyStats _weeklyStats(List<SavedPost> posts) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final lastWeekStart = now.subtract(const Duration(days: 14));

    final thisWeekPosts = posts
        .where((p) => p.createdAt.isAfter(weekAgo))
        .toList();

    final lastWeekPosts = posts
        .where(
          (p) =>
              p.createdAt.isAfter(lastWeekStart) &&
              p.createdAt.isBefore(weekAgo),
        )
        .toList();

    final weeklySaved = thisWeekPosts.length;

    final weeklyRevisited = thisWeekPosts.where((p) => p.visitCount > 0).length;

    final lastWeekRevisited = lastWeekPosts
        .where((p) => p.visitCount > 0)
        .length;

    final improvement = lastWeekRevisited == 0
        ? 0
        : ((weeklyRevisited - lastWeekRevisited) / lastWeekRevisited) * 100;

    return WeeklyStats(
      saved: weeklySaved,
      revisited: weeklyRevisited,
      improvement: (improvement ?? 0).toDouble(),
    );
  }

  // REMINDERS
  static ReminderStats _reminderStats(List<SavedPost> posts) {
    int totalReminders = 0;
    int revisitedAfterReminder = 0;

    for (final p in posts) {
      totalReminders += p.reminderCount;

      if (p.lastRemindedAt != null &&
          p.lastVisitedAt != null &&
          p.lastVisitedAt!.isAfter(p.lastRemindedAt!)) {
        revisitedAfterReminder++;
      }
    }

    final effectiveness = totalReminders == 0
        ? 0
        : (revisitedAfterReminder / totalReminders) * 100;

    return ReminderStats(
      totalReminders: totalReminders,
      revisitedAfterReminder: revisitedAfterReminder,
      effectiveness: (effectiveness ?? 0).toDouble(),
    );
  }

  // AVG TIME
  static double _avgTimeToRevisit(List<SavedPost> posts) {
    final revisited = posts.where((p) => p.lastVisitedAt != null);

    if (revisited.isEmpty) return 0;

    final durations = revisited.map(
      (p) => p.lastVisitedAt!.difference(p.createdAt).inHours / 24,
    );

    final avg = durations.reduce((a, b) => a + b) / revisited.length;

    return double.parse(avg.toStringAsFixed(1));
  }

  // SOURCE
  static SourceStats _sourceStats(List<SavedPost> posts) {
    final savedMap = <String, int>{};
    final revisitedMap = <String, int>{};

    for (final p in posts) {
      final domain = p.domain ?? 'unknown';

      savedMap[domain] = (savedMap[domain] ?? 0) + 1;

      if (p.visitCount > 0) {
        revisitedMap[domain] = (revisitedMap[domain] ?? 0) + 1;
      }
    }

    String? topSaved;
    String? topRevisited;

    if (savedMap.isNotEmpty) {
      topSaved = savedMap.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    if (revisitedMap.isNotEmpty) {
      topRevisited = revisitedMap.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return SourceStats(topSaved: topSaved, topRevisited: topRevisited);
  }

  // COLLECTIONS
  static CollectionStats _collectionStats(
      List<SavedPost> posts,
      Map<String, String> collectionMap,
      ) {
    final map = <String, int>{};

    for (final p in posts) {
      if (p.collectionId == null) continue;

      map[p.collectionId!] = (map[p.collectionId!] ?? 0) + 1;
    }

    if (map.isEmpty) {
      return CollectionStats();
    }

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CollectionStats(
      topCollection: collectionMap[sorted.first.key],
      leastUsedCollection: collectionMap[sorted.last.key],
    );
  }

  // TOP LINKS
  static List<SavedPost> _topLinks(List<SavedPost> posts) {
    final sorted = [...posts]
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));

    return sorted.take(3).toList();
  }
}
