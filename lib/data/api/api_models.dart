// JSON models for the Go backend (backend/README.md lists every endpoint).
// Field names mirror the API; dates stay as 'YYYY-MM-DD' strings like the API sends them.

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _dn(Object? v) => (v as num?)?.toDouble();
List<String> _strings(Object? v) => [for (final s in (v as List? ?? const [])) s as String];
List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) fromJson) => [
  for (final e in (v as List? ?? const [])) fromJson(e as Map<String, dynamic>),
];

/// Formats a date the way the API expects (the phone's local calendar day).
String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ApiUser {
  const ApiUser({
    required this.id,
    required this.email,
    required this.name,
    required this.status,
    required this.lifeStage,
    this.birthDate,
    this.age,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.stepsTarget,
    this.createdAt,
    this.reminderDaily = true,
    this.reminderBedtime = true,
    this.bedtimeTime = '22:30',
    this.weeklySummary = false,
    this.language = 'en',
  });

  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(
    id: j['id'] as int,
    email: j['email'] as String,
    name: j['name'] as String,
    status: j['status'] as String,
    lifeStage: j['life_stage'] as String,
    birthDate: j['birth_date'] as String?,
    age: j['age'] as int?,
    sex: j['sex'] as String?,
    heightCm: _dn(j['height_cm']),
    weightKg: _dn(j['weight_kg']),
    stepsTarget: j['steps_target'] as int?,
    createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String),
    reminderDaily: j['reminder_daily'] as bool? ?? true,
    reminderBedtime: j['reminder_bedtime'] as bool? ?? true,
    bedtimeTime: j['bedtime_time'] as String? ?? '22:30',
    weeklySummary: j['weekly_summary'] as bool? ?? false,
    language: j['language'] as String? ?? 'en',
  );

  final int id;
  final String email;
  final String name;
  final String status;

  /// general, pregnant_t1..t3, breastfeeding_0_6m, breastfeeding_7_12m
  final String lifeStage;
  final String? birthDate;
  final int? age;

  /// 'M' or 'F'
  final String? sex;
  final double? heightCm;
  final double? weightKg;

  /// null = the app default from the database.
  final int? stepsTarget;
  final DateTime? createdAt;
  final bool reminderDaily;
  final bool reminderBedtime;

  /// HH:MM, 24-hour.
  final String bedtimeTime;
  final bool weeklySummary;

  /// 'en' or 'id'
  final String language;

  /// Daily targets need birth date and sex; calories burned needs weight.
  bool get profileComplete => birthDate != null && sex != null && weightKg != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'status': status,
    'life_stage': lifeStage,
    'birth_date': birthDate,
    'age': age,
    'sex': sex,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'steps_target': stepsTarget,
    'created_at': createdAt?.toIso8601String(),
    'reminder_daily': reminderDaily,
    'reminder_bedtime': reminderBedtime,
    'bedtime_time': bedtimeTime,
    'weekly_summary': weeklySummary,
    'language': language,
  };
}

class AuthResult {
  const AuthResult({required this.token, required this.expiresAt, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
    token: j['token'] as String,
    expiresAt: DateTime.parse(j['expires_at'] as String),
    user: ApiUser.fromJson(j['user'] as Map<String, dynamic>),
  );

  final String token;
  final DateTime expiresAt;
  final ApiUser user;
}

class Targets {
  const Targets({
    required this.group,
    required this.energyKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
    required this.waterMl,
    required this.stepsTarget,
    this.sleepHoursMin,
    this.sleepHoursMax,
  });

  factory Targets.fromJson(Map<String, dynamic> j) => Targets(
    group: j['group'] as String,
    energyKcal: _d(j['energy_kcal']),
    proteinG: _d(j['protein_g']),
    fatG: _d(j['fat_g']),
    carbsG: _d(j['carbs_g']),
    fiberG: _d(j['fiber_g']),
    waterMl: _d(j['water_ml']),
    stepsTarget: j['steps_target'] as int,
    sleepHoursMin: _dn(j['sleep_hours_min']),
    sleepHoursMax: _dn(j['sleep_hours_max']),
  );

  final String group;
  final double energyKcal;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double fiberG;
  final double waterMl;
  final int stepsTarget;
  final double? sleepHoursMin;
  final double? sleepHoursMax;
}

/// One day of a user's data (meals, water, steps, sleep, stress, exercise).
class DayStats {
  const DayStats({
    required this.date,
    required this.caloriesIn,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.waterMl,
    required this.exerciseMinutes,
    required this.caloriesBurned,
    this.steps,
    this.sleepHours,
    this.stressAvg,
  });

  factory DayStats.fromJson(Map<String, dynamic> j) => DayStats(
    date: j['date'] as String,
    caloriesIn: _d(j['calories_in']),
    proteinG: _d(j['protein_g']),
    carbsG: _d(j['carbs_g']),
    fatG: _d(j['fat_g']),
    fiberG: _d(j['fiber_g']),
    waterMl: _d(j['water_ml']),
    exerciseMinutes: j['exercise_minutes'] as int,
    caloriesBurned: _d(j['calories_burned']),
    steps: j['steps'] as int?,
    sleepHours: _dn(j['sleep_hours']),
    stressAvg: _dn(j['stress_avg']),
  );

  final String date;
  final double caloriesIn;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double waterMl;
  final int exerciseMinutes;
  final double caloriesBurned;
  final int? steps;
  final double? sleepHours;
  final double? stressAvg;
}

class GoalProgress {
  const GoalProgress({required this.key, required this.current, required this.unit, this.target});

  factory GoalProgress.fromJson(Map<String, dynamic> j) => GoalProgress(
    key: j['key'] as String,
    current: _d(j['current']),
    target: _dn(j['target']),
    unit: j['unit'] as String,
  );

  /// steps, water, protein, sleep_last_night, calories, carbs, fat, fiber
  final String key;
  final double current;
  final double? target;
  final String unit;

  double get progress => target == null || target == 0 ? 0 : (current / target!).clamp(0.0, 1.0);
}

/// GET /me/summary: everything Home and the Food page need for one day.
class DaySummary {
  const DaySummary({
    required this.date,
    required this.user,
    required this.totals,
    required this.goals,
    required this.healthScore,
    required this.weekAverages,
    this.targets,
    this.targetsError,
    this.latestStress,
    this.stressLevel,
    this.activityLevel,
    this.tip,
  });

  factory DaySummary.fromJson(Map<String, dynamic> j) => DaySummary(
    date: j['date'] as String,
    user: ApiUser.fromJson(j['user'] as Map<String, dynamic>),
    totals: DayStats.fromJson(j['totals'] as Map<String, dynamic>),
    goals: _list(j['goals'], GoalProgress.fromJson),
    targets: j['targets'] == null ? null : Targets.fromJson(j['targets'] as Map<String, dynamic>),
    targetsError: j['targets_error'] as String?,
    latestStress: j['latest_stress'] == null ? null : StressLog.fromJson(j['latest_stress'] as Map<String, dynamic>),
    stressLevel: j['stress_level'] as String?,
    activityLevel: j['activity_level'] as String?,
    healthScore: HealthScoreSummary.fromJson(j['health_score'] as Map<String, dynamic>),
    weekAverages: j['week_averages'] as Map<String, dynamic>,
    tip: j['tip'] == null ? null : Tip.fromJson(j['tip'] as Map<String, dynamic>),
  );

  final String date;
  final ApiUser user;
  final DayStats totals;
  final List<GoalProgress> goals;
  final Targets? targets;

  /// Why targets are missing, e.g. the profile has no birth date yet.
  final String? targetsError;
  final StressLog? latestStress;

  /// Low, Medium or High: today's check-in, otherwise the 7-day average.
  final String? stressLevel;

  /// Low, Moderate or High over the last 7 days.
  final String? activityLevel;

  /// Over the 7 days ending on [date].
  final HealthScoreSummary healthScore;

  /// Same keys as [Analytics.averages], for the 7 days ending on [date].
  final Map<String, dynamic> weekAverages;

  /// The most relevant tip from the coach tip library, or null when none applies.
  final Tip? tip;

  GoalProgress? goal(String key) {
    for (final g in goals) {
      if (g.key == key) return g;
    }
    return null;
  }
}

/// GET /me/analytics: per-day series plus averages and comparisons with the previous period.
class Analytics {
  const Analytics({
    required this.from,
    required this.to,
    required this.days,
    required this.scores,
    required this.healthScore,
    required this.averages,
    required this.previousAverages,
    required this.nutritionPercent,
    required this.vsPrevious,
    required this.insights,
    required this.healthyMeals,
    required this.healthyMealsSentence,
    required this.insightSentences,
    required this.tips,
    this.recommendation,
  });

  factory Analytics.fromJson(Map<String, dynamic> j) => Analytics(
    from: j['from'] as String,
    to: j['to'] as String,
    days: _list(j['days'], DayStats.fromJson),
    scores: _list(j['scores'], DayScore.fromJson),
    healthScore: HealthScoreSummary.fromJson(j['health_score'] as Map<String, dynamic>),
    averages: j['averages'] as Map<String, dynamic>,
    previousAverages: j['previous_averages'] as Map<String, dynamic>,
    nutritionPercent: {
      for (final e in ((j['nutrition_percent'] as Map<String, dynamic>?) ?? const {}).entries) e.key: _d(e.value),
    },
    vsPrevious: j['vs_previous'] as Map<String, dynamic>,
    insights: j['insights'] as Map<String, dynamic>,
    healthyMeals: j['healthy_meals'] as int,
    healthyMealsSentence: j['healthy_meals_sentence'] as String,
    insightSentences: _strings(j['insight_sentences']),
    recommendation: j['recommendation'] as String?,
    tips: _list(j['tips'], Tip.fromJson),
  );

  final String from;
  final String to;
  final List<DayStats> days;

  /// Health Score per day, same order as [days].
  final List<DayScore> scores;
  final HealthScoreSummary healthScore;

  /// Keys: calories_in, protein_g, ..., steps, sleep_hours, stress, exercise_days, exercise_minutes, calories_burned.
  final Map<String, dynamic> averages;
  final Map<String, dynamic> previousAverages;

  /// Percent of daily target: calories, protein, carbs, fat, fiber, water. Empty when the profile is incomplete.
  final Map<String, double> nutritionPercent;

  /// sleep_hours_diff, steps_change_percent, stress_change_percent, exercise_change_percent,
  /// healthy_meals_change_pct (null when there is no data to compare).
  final Map<String, dynamic> vsPrevious;

  /// Numbers for the insight templates, e.g. stress_exercise_vs_rest_percent.
  final Map<String, dynamic> insights;
  final int healthyMeals;
  final String healthyMealsSentence;

  /// Ready-to-show AI Insights lines.
  final List<String> insightSentences;

  /// The most relevant tip for this period.
  final String? recommendation;
  final List<Tip> tips;

  double? average(String key) => _dn(averages[key]);
  double? change(String key) => _dn(vsPrevious[key]);
}

/// Provisional Health Score (weights are still an open decision in the brief).
class HealthScoreSummary {
  const HealthScoreSummary({required this.balance, this.latest, this.latestDate, this.average, this.changePercent});

  factory HealthScoreSummary.fromJson(Map<String, dynamic> j) => HealthScoreSummary(
    latest: _dn(j['latest']),
    latestDate: j['latest_date'] as String?,
    average: _dn(j['average']),
    changePercent: _dn(j['change_percent']),
    balance: Balance.fromJson(j['balance'] as Map<String, dynamic>),
  );

  final double? latest;
  final String? latestDate;
  final double? average;
  final double? changePercent;
  final Balance balance;
}

class Balance {
  const Balance({this.nutrition, this.sleep, this.stress, this.exercise});

  factory Balance.fromJson(Map<String, dynamic> j) => Balance(
    nutrition: _dn(j['nutrition']),
    sleep: _dn(j['sleep']),
    stress: _dn(j['stress']),
    exercise: _dn(j['exercise']),
  );

  final double? nutrition;
  final double? sleep;
  final double? stress;
  final double? exercise;
}

class DayScore {
  const DayScore({required this.date, this.score});

  factory DayScore.fromJson(Map<String, dynamic> j) => DayScore(date: j['date'] as String, score: _dn(j['score']));

  final String date;
  final double? score;
}

/// A tip picked by the backend from the coach tip library, already in the user's language.
class Tip {
  const Tip({required this.id, required this.topic, required this.text});

  factory Tip.fromJson(Map<String, dynamic> j) =>
      Tip(id: j['id'] as String, topic: j['topic'] as String, text: j['text'] as String);

  final String id;
  final String topic;
  final String text;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.serving,
    required this.servingGrams,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.labels,
    this.nameEn,
  });

  factory Food.fromJson(Map<String, dynamic> j) => Food(
    id: j['id'] as String,
    name: j['name'] as String,
    nameEn: j['name_en'] as String?,
    category: j['category'] as String,
    serving: j['serving'] as String,
    servingGrams: _d(j['serving_grams']),
    caloriesKcal: _d(j['calories_kcal']),
    proteinG: _d(j['protein_g']),
    carbsG: _d(j['carbs_g']),
    fatG: _d(j['fat_g']),
    fiberG: _d(j['fiber_g']),
    labels: _strings(j['labels']),
  );

  final String id;
  final String name;
  final String? nameEn;
  final String category;
  final String serving;
  final double servingGrams;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  /// From the approved Package 6 rules, e.g. Healthy, High fat.
  final List<String> labels;
}

class Product {
  const Product({
    required this.barcode,
    required this.brand,
    required this.productName,
    required this.servingSize,
    required this.servingUnit,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.labels,
    this.variant,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    barcode: j['barcode'] as String,
    brand: j['brand'] as String,
    productName: j['product_name'] as String,
    variant: j['variant'] as String?,
    servingSize: _d(j['serving_size']),
    servingUnit: j['serving_unit'] as String,
    caloriesKcal: _d(j['calories_kcal']),
    proteinG: _d(j['protein_g']),
    carbsG: _d(j['carbs_g']),
    fatG: _d(j['fat_g']),
    labels: _strings(j['labels']),
  );

  final String barcode;
  final String brand;
  final String productName;
  final String? variant;
  final double servingSize;
  final String servingUnit;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<String> labels;
}

class Activity {
  const Activity({
    required this.id,
    required this.name,
    required this.group,
    required this.met,
    required this.intensity,
    this.nameEn,
  });

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'] as String,
    name: j['activity_name'] as String,
    nameEn: j['activity_name_en'] as String?,
    group: j['activity_group'] as String,
    met: _d(j['met']),
    intensity: j['intensity'] as String,
  );

  final String id;
  final String name;
  final String? nameEn;

  /// The Log Exercise button: walk, run, cycling, swim, gym, yoga, sports, daily, other.
  final String group;
  final double met;

  /// light, moderate or vigorous (derived from MET by the backend).
  final String intensity;
}

class MealLog {
  const MealLog({
    required this.id,
    required this.loggedOn,
    required this.mealTime,
    required this.name,
    required this.category,
    required this.servings,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.labels,
    this.foodId,
    this.barcode,
  });

  factory MealLog.fromJson(Map<String, dynamic> j) => MealLog(
    id: j['id'] as int,
    loggedOn: j['logged_on'] as String,
    mealTime: j['meal_time'] as String,
    foodId: j['food_id'] as String?,
    barcode: j['barcode'] as String?,
    name: j['name'] as String,
    category: j['category'] as String,
    servings: _d(j['servings']),
    caloriesKcal: _d(j['calories_kcal']),
    proteinG: _d(j['protein_g']),
    carbsG: _d(j['carbs_g']),
    fatG: _d(j['fat_g']),
    labels: _strings(j['labels']),
  );

  final int id;
  final String loggedOn;

  /// breakfast, lunch, dinner or snack
  final String mealTime;
  final String? foodId;
  final String? barcode;
  final String name;

  /// Package 1 category, 'packaged' (barcode) or 'custom'.
  final String category;
  final double servings;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// e.g. Healthy, High fat (from the approved label rules).
  final List<String> labels;
}

class ExerciseLog {
  const ExerciseLog({
    required this.id,
    required this.loggedOn,
    required this.activityId,
    required this.activityName,
    required this.intensity,
    required this.minutes,
    required this.caloriesKcal,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
    id: j['id'] as int,
    loggedOn: j['logged_on'] as String,
    activityId: j['activity_id'] as String,
    activityName: j['activity_name'] as String,
    intensity: j['intensity'] as String,
    minutes: j['minutes'] as int,
    caloriesKcal: _d(j['calories_kcal']),
  );

  final int id;
  final String loggedOn;
  final String activityId;
  final String activityName;
  final String intensity;
  final int minutes;
  final double caloriesKcal;
}

class StressLog {
  const StressLog({
    required this.id,
    required this.loggedOn,
    required this.level,
    required this.factorIds,
    this.category,
  });

  factory StressLog.fromJson(Map<String, dynamic> j) => StressLog(
    id: j['id'] as int,
    loggedOn: j['logged_on'] as String,
    level: j['level'] as int,
    category: j['category'] as String?,
    factorIds: _strings(j['factor_ids']),
  );

  final int id;
  final String loggedOn;

  /// 1 = calm, 10 = very stressed.
  final int level;

  /// Low, Medium or High.
  final String? category;
  final List<String> factorIds;
}

class StressFactor {
  const StressFactor({required this.id, required this.name, required this.nameEn});

  factory StressFactor.fromJson(Map<String, dynamic> j) =>
      StressFactor(id: j['id'] as String, name: j['name'] as String, nameEn: j['name_en'] as String);

  final String id;
  final String name;
  final String nameEn;
}

class QuickQuestion {
  const QuickQuestion({
    required this.id,
    required this.text,
    required this.topic,
    required this.isDefault,
    this.textEn,
  });

  factory QuickQuestion.fromJson(Map<String, dynamic> j) => QuickQuestion(
    id: j['id'] as String,
    text: j['question_text'] as String,
    textEn: j['question_text_en'] as String?,
    topic: j['topic'] as String,
    isDefault: j['is_default'] as bool,
  );

  final String id;
  final String text;
  final String? textEn;
  final String topic;
  final bool isDefault;
}

class CoachTip {
  const CoachTip({required this.id, required this.topic, required this.triggerCondition, required this.text});

  factory CoachTip.fromJson(Map<String, dynamic> j) => CoachTip(
    id: j['id'] as String,
    topic: j['topic'] as String,
    triggerCondition: j['trigger_condition'] as String,
    text: j['tip_text'] as String,
  );

  final String id;
  final String topic;
  final String triggerCondition;
  final String text;
}

/// GET /coach/content (Package 7). Restricted topics, reminders and insight templates stay as raw maps.
class CoachContent {
  const CoachContent({
    required this.tips,
    required this.quickQuestions,
    required this.restrictedTopics,
    required this.reminders,
    required this.insightTemplates,
  });

  factory CoachContent.fromJson(Map<String, dynamic> j) => CoachContent(
    tips: _list(j['tips'], CoachTip.fromJson),
    quickQuestions: _list(j['quick_questions'], QuickQuestion.fromJson),
    restrictedTopics: _list(j['restricted_topics'], (m) => m),
    reminders: _list(j['reminders'], (m) => m),
    insightTemplates: _list(j['insight_templates'], (m) => m),
  );

  final List<CoachTip> tips;
  final List<QuickQuestion> quickQuestions;
  final List<Map<String, dynamic>> restrictedTopics;
  final List<Map<String, dynamic>> reminders;
  final List<Map<String, dynamic>> insightTemplates;
}

class StressBand {
  const StressBand({required this.category, required this.scaleMin, required this.scaleMax});

  factory StressBand.fromJson(Map<String, dynamic> j) =>
      StressBand(category: j['category'] as String, scaleMin: j['scale_min'] as int, scaleMax: j['scale_max'] as int);

  /// Low, Medium or High
  final String category;
  final int scaleMin;
  final int scaleMax;
}

/// What Stress Check needs: the "What's on your mind?" chips and the Low/Medium/High bands.
class StressInfo {
  const StressInfo({required this.factors, required this.bands});

  factory StressInfo.fromJson(Map<String, dynamic> j) =>
      StressInfo(factors: _list(j['factors'], StressFactor.fromJson), bands: _list(j['bands'], StressBand.fromJson));

  final List<StressFactor> factors;
  final List<StressBand> bands;

  StressBand? bandFor(int level) {
    for (final b in bands) {
      if (level >= b.scaleMin && level <= b.scaleMax) return b;
    }
    return null;
  }
}

class CoachPoint {
  const CoachPoint({required this.topic, required this.text});

  factory CoachPoint.fromJson(Map<String, dynamic> j) =>
      CoachPoint(topic: j['topic'] as String, text: j['text'] as String);

  final String topic;
  final String text;
}

/// A structured AI Coach answer built by the backend from the user's data.
class CoachReply {
  const CoachReply({
    required this.kind,
    required this.text,
    required this.points,
    required this.recommendations,
    this.recommendationsTitle,
    this.referral,
  });

  factory CoachReply.fromJson(Map<String, dynamic> j) => CoachReply(
    kind: j['kind'] as String,
    text: j['text'] as String,
    points: _list(j['points'], CoachPoint.fromJson),
    recommendationsTitle: j['recommendations_title'] as String?,
    recommendations: _strings(j['recommendations']),
    referral: j['referral'] as String?,
  );

  /// answer, restricted (sensitive topic, safe answer only) or fallback.
  final String kind;
  final String text;
  final List<CoachPoint> points;
  final String? recommendationsTitle;
  final List<String> recommendations;

  /// Who to contact, for restricted topics.
  final String? referral;
}

class ChatMessage {
  const ChatMessage({required this.id, required this.role, required this.text, required this.createdAt, this.reply});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as int,
    role: j['role'] as String,
    text: j['text'] as String,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    reply: j['reply'] == null ? null : CoachReply.fromJson(j['reply'] as Map<String, dynamic>),
  );

  final int id;

  /// user or coach
  final String role;
  final String text;
  final DateTime createdAt;
  final CoachReply? reply;

  bool get fromUser => role == 'user';
}
