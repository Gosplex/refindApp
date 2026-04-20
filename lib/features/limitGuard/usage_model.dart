class UsageModel {
  final int totalPostsCreated;
  final String plan;

  UsageModel({
    required this.totalPostsCreated,
    required this.plan,
  });

  factory UsageModel.fromMap(Map<String, dynamic> data) {
    return UsageModel(
      totalPostsCreated: data['totalPostsCreated'] ?? 0,
      plan: data['plan'] ?? 'free',
    );
  }
}