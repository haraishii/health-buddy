import 'api_client.dart';
import 'api_models.dart';

/// One method per backend endpoint. Methods under "me" need a signed-in session.
/// Dates default to today on the phone, so "today" follows the user's time zone, not the server's.
class HealthBuddyApi {
  HealthBuddyApi(this.client);

  final ApiClient client;

  static const _v1 = '/api/v1';

  static String _day(DateTime? d) => apiDate(d ?? DateTime.now());

  // --- auth ---

  Future<AuthResult> signUp({required String name, required String email, required String password}) async =>
      AuthResult.fromJson(
        await client.post('$_v1/auth/signup', {'name': name, 'email': email, 'password': password})
            as Map<String, dynamic>,
      );

  Future<AuthResult> signIn({required String email, required String password}) async => AuthResult.fromJson(
    await client.post('$_v1/auth/signin', {'email': email, 'password': password}) as Map<String, dynamic>,
  );

  // --- profile and targets ---

  Future<ApiUser> me() async => ApiUser.fromJson(await client.get('$_v1/me') as Map<String, dynamic>);

  /// Only the non-null arguments are changed. [birthDate] is sent as YYYY-MM-DD; [sex] is 'M' or 'F';
  /// [bedtimeTime] is HH:MM. [clearStepsTarget] goes back to the default steps target from the database.
  Future<ApiUser> updateMe({
    String? name,
    String? status,
    DateTime? birthDate,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? lifeStage,
    int? stepsTarget,
    bool clearStepsTarget = false,
    bool? reminderDaily,
    bool? reminderBedtime,
    String? bedtimeTime,
    bool? weeklySummary,
    String? language,
  }) async {
    final body = <String, Object>{
      'name': ?name,
      'status': ?status,
      if (birthDate != null) 'birth_date': apiDate(birthDate),
      'sex': ?sex,
      'height_cm': ?heightCm,
      'weight_kg': ?weightKg,
      'life_stage': ?lifeStage,
      'steps_target': ?stepsTarget,
      if (clearStepsTarget) 'clear_steps_target': true,
      'reminder_daily': ?reminderDaily,
      'reminder_bedtime': ?reminderBedtime,
      'bedtime_time': ?bedtimeTime,
      'weekly_summary': ?weeklySummary,
      'language': ?language,
    };
    return ApiUser.fromJson(await client.patch('$_v1/me', body) as Map<String, dynamic>);
  }

  /// Throws ApiException 422 when the profile has no birth date or sex yet.
  Future<Targets> targets() async => Targets.fromJson(await client.get('$_v1/me/targets') as Map<String, dynamic>);

  Future<DaySummary> summary({DateTime? date}) async =>
      DaySummary.fromJson(await client.get('$_v1/me/summary', query: {'date': _day(date)}) as Map<String, dynamic>);

  /// Defaults to the 7 days ending today.
  Future<Analytics> analytics({DateTime? from, DateTime? to}) async => Analytics.fromJson(
    await client.get('$_v1/me/analytics', query: {'from': from == null ? null : apiDate(from), 'to': _day(to)})
        as Map<String, dynamic>,
  );

  // --- meals ---

  Future<List<MealLog>> meals({DateTime? date}) async {
    final json = await client.get('$_v1/me/meals', query: {'date': _day(date)}) as Map<String, dynamic>;
    return [for (final m in json['items'] as List) MealLog.fromJson(m as Map<String, dynamic>)];
  }

  /// Log a food from the database ([foodId]) or a packaged product ([barcode]).
  Future<MealLog> addMeal({
    required String mealTime,
    String? foodId,
    String? barcode,
    double servings = 1,
    DateTime? date,
  }) async => MealLog.fromJson(
    await client.post('$_v1/me/meals', {
      'date': _day(date),
      'meal_time': mealTime,
      'food_id': ?foodId,
      'barcode': ?barcode,
      'servings': servings,
    }) as Map<String, dynamic>,
  );

  /// Log something that is not in the database, e.g. an edited Scan Meal photo result. Values are per serving.
  Future<MealLog> addCustomMeal({
    required String mealTime,
    required String name,
    required double caloriesKcal,
    double proteinG = 0,
    double carbsG = 0,
    double fatG = 0,
    double servings = 1,
    DateTime? date,
  }) async => MealLog.fromJson(
    await client.post('$_v1/me/meals', {
      'date': _day(date),
      'meal_time': mealTime,
      'servings': servings,
      'custom': {'name': name, 'calories_kcal': caloriesKcal, 'protein_g': proteinG, 'carbs_g': carbsG, 'fat_g': fatG},
    }) as Map<String, dynamic>,
  );

  Future<void> deleteMeal(int id) => client.delete('$_v1/me/meals/$id');

  // --- exercise, stress, water, sleep, steps ---

  Future<List<ExerciseLog>> exercises({DateTime? from, DateTime? to}) async {
    final json = await client.get(
      '$_v1/me/exercises',
      query: {'from': from == null ? null : apiDate(from), 'to': _day(to)},
    ) as Map<String, dynamic>;
    return [for (final e in json['items'] as List) ExerciseLog.fromJson(e as Map<String, dynamic>)];
  }

  /// Throws ApiException 422 when the profile has no weight (needed for calories burned).
  Future<ExerciseLog> addExercise({
    required String activityId,
    required int minutes,
    String? note,
    DateTime? date,
  }) async => ExerciseLog.fromJson(
    await client.post('$_v1/me/exercises', {
      'date': _day(date),
      'activity_id': activityId,
      'minutes': minutes,
      'note': ?note,
    }) as Map<String, dynamic>,
  );

  Future<void> deleteExercise(int id) => client.delete('$_v1/me/exercises/$id');

  Future<List<StressLog>> stressLogs({DateTime? from, DateTime? to}) async {
    final json = await client.get(
      '$_v1/me/stress',
      query: {'from': from == null ? null : apiDate(from), 'to': _day(to)},
    ) as Map<String, dynamic>;
    return [for (final s in json['items'] as List) StressLog.fromJson(s as Map<String, dynamic>)];
  }

  Future<StressLog> addStress({
    required int level,
    List<String> factorIds = const [],
    String? note,
    DateTime? date,
  }) async => StressLog.fromJson(
    await client.post('$_v1/me/stress', {'date': _day(date), 'level': level, 'factor_ids': factorIds, 'note': ?note})
        as Map<String, dynamic>,
  );

  /// Returns the day's total in ml.
  Future<int> addWater({int amountMl = 250, DateTime? date}) async {
    final json =
        await client.post('$_v1/me/water', {'date': _day(date), 'amount_ml': amountMl}) as Map<String, dynamic>;
    return json['total_ml'] as int;
  }

  /// [date] is the morning the night ended ("Sleep last night").
  Future<void> setSleep({required double hours, DateTime? date}) =>
      client.put('$_v1/me/sleep/${_day(date)}', {'hours': hours});

  /// Daily total from Health Connect / HealthKit; replaces the stored value.
  Future<void> setSteps({required int steps, DateTime? date, String source = 'health_connect'}) =>
      client.put('$_v1/me/steps/${_day(date)}', {'steps': steps, 'source': source});

  // --- reference data ---

  /// [popular] sorts by how often all users logged each food (the "Popular" list when the query is empty).
  Future<List<Food>> searchFoods({
    String query = '',
    String? category,
    bool popular = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final json = await client.get(
      '$_v1/foods',
      query: {
        'q': query,
        'category': category,
        'sort': popular ? 'popular' : null,
        'limit': '$limit',
        'offset': '$offset',
      },
    ) as Map<String, dynamic>;
    return [for (final f in json['items'] as List) Food.fromJson(f as Map<String, dynamic>)];
  }

  Future<Food> food(String id) async => Food.fromJson(await client.get('$_v1/foods/$id') as Map<String, dynamic>);

  /// Throws ApiException 404 when the barcode is unknown.
  Future<Product> product(String barcode) async =>
      Product.fromJson(await client.get('$_v1/products/$barcode') as Map<String, dynamic>);

  Future<List<Activity>> activities({String? group}) async {
    final json = await client.get('$_v1/activities', query: {'group': group}) as Map<String, dynamic>;
    return [for (final a in json['items'] as List) Activity.fromJson(a as Map<String, dynamic>)];
  }

  Future<StressInfo> stressInfo() async =>
      StressInfo.fromJson(await client.get('$_v1/stress/questionnaire') as Map<String, dynamic>);

  // --- AI Coach ---

  /// Ask a quick question ([questionId]) or a typed one ([text]). Returns the saved question and answer.
  Future<({ChatMessage question, ChatMessage answer})> askCoach({String? questionId, String? text}) async {
    final json = await client.post('$_v1/me/coach/ask?date=${_day(null)}', {
      'question_id': ?questionId,
      'text': ?text,
    }) as Map<String, dynamic>;
    return (
      question: ChatMessage.fromJson(json['question'] as Map<String, dynamic>),
      answer: ChatMessage.fromJson(json['answer'] as Map<String, dynamic>),
    );
  }

  /// The latest messages, oldest first.
  Future<List<ChatMessage>> coachHistory({int limit = 50}) async {
    final json = await client.get('$_v1/me/coach/history', query: {'limit': '$limit'}) as Map<String, dynamic>;
    return [for (final m in json['items'] as List) ChatMessage.fromJson(m as Map<String, dynamic>)];
  }

  Future<CoachContent> coachContent() async =>
      CoachContent.fromJson(await client.get('$_v1/coach/content') as Map<String, dynamic>);
}
