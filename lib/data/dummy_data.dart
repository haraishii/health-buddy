import 'models.dart';

// The ONLY place for sample data. Numbers come from the mockup.
// Screens read from here; never hardcode sample numbers inside a screen.
class DummyData {
  DummyData._();

  static const user = UserProfile(name: 'Annida', status: 'Student', joined: 'May 2026');

  static const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const healthScore = HealthScore(weekly: [72, 76, 68, 80, 85, 88, 85], changeVsLastWeek: 12);

  static const balance = BalanceScores(nutrition: 90, stress: 85, sleep: 80, exercise: 70);

  static const goals = [
    DailyGoal(label: 'Steps', current: 6240, target: 8000, unit: ''),
    DailyGoal(label: 'Water', current: 1.2, target: 2, unit: 'L'),
    DailyGoal(label: 'Protein', current: 42, target: 60, unit: 'g'),
    DailyGoal(label: 'Sleep last night', current: 6.17, target: 8, unit: 'h'),
  ];

  /// Percent of daily target (Analytics > Nutrition).
  static const nutritionPercent = {'Protein': 85, 'Carbs': 60, 'Fat': 80, 'Fiber': 40};

  /// Scale 1–10, Monday to Sunday.
  static const stressWeekly = [7, 6, 8, 5, 4, 3, 4];
  static const stressWeeklyAvg = 5.3;
  static const stressChangeVsLastWeek = -15;

  /// Active hours per day (Analytics > Exercise).
  static const exerciseHours = [4.7, 3.5, 1.5, 3.2, 5.8, 3.3, 4.6];
  static const exerciseDaysPerWeek = 4.2;
  static const avgSteps = 7842;
  static const avgKcalBurned = 320;

  static const trends = {'Exercise': 18, 'Stress': -15, 'Healthy meals': 22};

  static const insight = 'Your stress drops 20% on days you exercise.';
  static const recommendation = 'Walk 20 minutes after class to keep your progress going.';

  static const kcalTarget = 1900;
  static const meals = [
    Meal(title: 'Breakfast', items: [
      FoodItem(name: 'Oatmeal with banana', kcal: 320, protein: 9, carbs: 58, fat: 6, tag: 'Healthy'),
    ]),
    Meal(title: 'Lunch', items: [
      FoodItem(name: 'Chicken rice bowl', kcal: 640, protein: 28, carbs: 82, fat: 18),
      FoodItem(name: 'Iced tea, less sugar', kcal: 0, carbs: 18),
    ]),
    Meal(title: 'Snack', items: [
      FoodItem(name: 'Fried snacks', kcal: 460, protein: 5, carbs: 10, fat: 24, tag: 'High fat'),
    ]),
  ];

  /// Sample result for the Scan Meal screen.
  static const scanResult = FoodItem(name: 'Chicken rice bowl', kcal: 640, protein: 28, carbs: 82, fat: 18);

  static const popularFoods = [
    FoodItem(name: 'Nasi goreng', kcal: 520),
    FoodItem(name: 'Chicken rice bowl', kcal: 640),
    FoodItem(name: 'Gado-gado', kcal: 410),
    FoodItem(name: 'Banana', kcal: 105),
    FoodItem(name: 'Greek yogurt', kcal: 140),
  ];

  static const stressFactors = ['Exams', 'Assignments', 'Sleep', 'Friends', 'Family', 'Money'];

  static const activities = {'Walk': 3.5, 'Run': 8.0, 'Cycling': 6.0, 'Gym': 5.0, 'Yoga': 2.5, 'Sports': 7.0};

  static const coachQuickQuestions = {
    'Why am I feeling tired?': 'Mostly sleep: you averaged 6 h 10 m this week. Try winding down 30 minutes earlier tonight.',
    'What should I eat today?': 'You are 18 g short of your protein goal. For lunch, try grilled chicken or tofu with rice and vegetables.',
    'How can I reduce my stress?': 'Try the 1-minute breathing exercise in Stress Check. Your stress is 20% lower on days you exercise.',
    'Analyze my weekly progress': 'Your Health Score rose 12% to 85. Best day: Saturday (88). Exercise (70) has the most room to grow.',
  };
  static const coachFallback = 'Thanks! In the full app, the AI model answers this using your data from the last 7 days.';
}
