// Simple data classes for the hardcoded version.
// When a backend exists, add fromJson/toJson here without touching the screens.

class UserProfile {
  const UserProfile({required this.name, required this.status, required this.joined});
  final String name;
  final String status;
  final String joined;
}

class DailyGoal {
  const DailyGoal({required this.label, required this.current, required this.target, required this.unit});
  final String label;
  final double current;
  final double target;
  final String unit;
  double get progress => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

class HealthScore {
  const HealthScore({required this.weekly, required this.changeVsLastWeek});

  /// Monday to Sunday.
  final List<int> weekly;

  /// In percent, e.g. 12 means up 12%.
  final int changeVsLastWeek;
  int get latest => weekly.last;
}

class BalanceScores {
  const BalanceScores({required this.nutrition, required this.stress, required this.sleep, required this.exercise});
  final int nutrition;
  final int stress;
  final int sleep;
  final int exercise;
}

class FoodItem {
  const FoodItem({required this.name, required this.kcal, this.protein = 0, this.carbs = 0, this.fat = 0, this.tag});
  final String name;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String? tag;
}

class Meal {
  const Meal({required this.title, required this.items});
  final String title;
  final List<FoodItem> items;
  int get kcal => items.fold(0, (sum, f) => sum + f.kcal);
}

class ExerciseLog {
  const ExerciseLog({required this.activity, required this.minutes, required this.intensity, required this.kcal});
  final String activity;
  final int minutes;
  final String intensity;
  final int kcal;
}

class StressLog {
  const StressLog({required this.level, required this.factors});

  /// 1 = calm, 10 = very stressed.
  final int level;
  final List<String> factors;
}

class ChatMessage {
  const ChatMessage({required this.text, required this.fromUser, required this.time});
  final String text;
  final bool fromUser;
  final String time;
}
