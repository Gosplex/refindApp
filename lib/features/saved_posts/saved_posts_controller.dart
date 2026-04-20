import 'package:uuid/uuid.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

import '../reminders/reminder_service.dart';
import 'models/saved_post_model.dart';
import 'services/saved_posts_service.dart';

class SavedPostsController {
  final SavedPostsService _service = SavedPostsService();
  final Uuid _uuid = const Uuid();

  Future<bool> addPost(String url) async {
    if (url.trim().isEmpty) return false;

    final canAdd = await _service.canAddPost();
    if (!canAdd) {
      return false;
    }

    final post = SavedPost(
      id: _uuid.v4(),
      title: url,
      url: url,
      createdAt: DateTime.now(),
    );

    await _service.addPost(post);
    await _service.incrementPostUsage();
    _fetchAndUpdateMetadata(post);

    return true;
  }

  Stream<List<SavedPost>> getPosts() {
    return _service.getPosts();
  }

  Stream<List<SavedPost>> getPostsStream() {
    return _service.getPostsStream();
  }

  Future<void> deletePost(String id) async {
    await _service.deletePost(id);
    await ReminderService.cancelReminders(id);
  }

  Future<void> dismissPost(String id) async {
    await _service.dismissPost(id);
    await ReminderService.cancelReminders(id);
  }

  Future<void> markReminderTriggered(String id) async {
    await _service.incrementReminder(id);
  }

  Future<void> _fetchAndUpdateMetadata(SavedPost post) async {
    try {
      final data = await MetadataFetch.extract(post.url);

      if (data == null) return;

      final uri = Uri.parse(post.url);

      final updatedData = {
        "title": data.title ?? post.url,
        "description": data.description,
        "image": data.image,
        "source": data.url,
        "domain": uri.host,
        "tags": _generateTags(data),
      };

      await _service.updatePost(post.id, updatedData);

      final updatedPost = SavedPost(
        id: post.id,
        title: data.title ?? post.url,
        description: data.description,
        image: data.image,
        url: post.url,
        domain: uri.host,
        createdAt: post.createdAt,
        tags: _generateTags(data),
      );

      await ReminderService.scheduleReminder(updatedPost);
    } catch (e) {
      print("Metadata fetch error: $e");
    }
  }

  Future<void> deleteAllPosts() async {
    final posts = await _service.getPosts().first;

    for (final post in posts) {
      await ReminderService.cancelReminders(post.id);
    }

    await _service.deleteAllPosts();
  }

  List<String> _generateTags(Metadata data) {
    final tags = <String>{};

    final text = [
      data.title,
      data.description,
      data.url,
    ].whereType<String>().join(" ").toLowerCase();

    // -------------------------------
    // 1. DOMAIN-BASED TAGS (IMPROVED)
    // -------------------------------
    if (data.url != null && data.url!.isNotEmpty) {
      try {
        final uri = Uri.parse(data.url!);
        final host = uri.host.replaceAll('www.', '');

        final domainTags = {
          'youtube': 'video',
          'youtu.be': 'video',
          'twitter': 'social',
          'x.com': 'social',
          'facebook': 'social',
          'instagram': 'social',
          'linkedin': 'social',
          'github': 'code',
          'gitlab': 'code',
          'bitbucket': 'code',
          'medium': 'article',
          'dev.to': 'article',
          'hashnode': 'article',
          'substack': 'article',
          'stackoverflow': 'qa',
          'stackexchange': 'qa',
          'reddit': 'community',
          'notion': 'docs',
          'docs.google': 'docs',
          'drive.google': 'storage',
          'dropbox': 'storage',
          'figma': 'design',
          'dribbble': 'design',
          'behance': 'design',
          'amazon': 'shopping',
          'flipkart': 'shopping',
          'netflix': 'entertainment',
          'primevideo': 'entertainment',
          'coursera': 'learning',
          'udemy': 'learning',
          'spotify': 'audio',
        };

        domainTags.forEach((key, value) {
          if (host.contains(key)) tags.add(value);
        });

        // Add root domain (cleaner)
        final root = host.split('.').first;
        if (root.length > 2) tags.add(root);

      } catch (e) {
        // Ignore bad URLs
      }
    }

    // -------------------------------
    // 2. SMART KEYWORD EXTRACTION (BETTER)
    // -------------------------------
    const stopwords = {
      'the', 'and', 'for', 'with', 'this', 'that', 'from',
      'your', 'have', 'are', 'was', 'will', 'you', 'how',
      'into', 'about', 'what', 'when', 'where', 'which',
    };

    final words = text.split(RegExp(r'[^a-z0-9]+'));

    for (final word in words) {
      if (word.length > 3 &&
          !stopwords.contains(word) &&
          !word.startsWith('http')) {
        tags.add(word);
      }
    }

    // -------------------------------
    // 3. PRIORITY + LIMIT
    // -------------------------------
    final priorityOrder = [
      'video',
      'article',
      'code',
      'social',
      'learning',
      'design',
      'qa',
    ];

    final sortedTags = tags.toList()
      ..sort((a, b) {
        final aIndex = priorityOrder.indexOf(a);
        final bIndex = priorityOrder.indexOf(b);

        if (aIndex == -1 && bIndex == -1) return 0;
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;

        return aIndex.compareTo(bIndex);
      });

    return sortedTags.take(6).toList();
  }
}