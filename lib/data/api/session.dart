import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'api_models.dart';
import 'health_buddy_api.dart';

/// Where the token and the signed-in user are kept between app launches.
abstract class SessionStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Encrypted storage (Android Keystore / iOS Keychain).
class SecureSessionStore implements SessionStore {
  const SecureSessionStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// For tests and previews: forgets everything when the app closes.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

enum SessionStatus { restoring, signedOut, signedIn }

/// The signed-in user and the API they talk to. Listen to it to switch between the login screen and the app.
class Session extends ChangeNotifier {
  Session({this.store = const SecureSessionStore(), ApiClient? client}) : api = HealthBuddyApi(client ?? ApiClient()) {
    // An expired token anywhere in the app sends the user back to the login screen.
    api.client.onUnauthorized = () => signOut();
  }

  final SessionStore store;
  final HealthBuddyApi api;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  SessionStatus _status = SessionStatus.restoring;
  SessionStatus get status => _status;

  ApiUser? _user;
  ApiUser? get user => _user;

  /// Bumped after every change (a logged meal, a profile edit, pull-to-refresh). Screens reload when it changes.
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  // Last successful response per request, so a screen opened again shows its data instantly
  // while fresh data loads in the background.
  final Map<String, Object> _cache = {};
  final Set<Future<Object?>> _inFlight = {};

  T? cached<T extends Object>(String key) => _cache[key] as T?;

  /// Runs [load] and remembers the result under [key]. Used by ApiBuilder.
  Future<T> fetch<T extends Object>(String key, Future<T> Function(HealthBuddyApi api) load) async {
    final future = load(api);
    _inFlight.add(future);
    try {
      final value = await future;
      _cache[key] = value;
      return value;
    } finally {
      _inFlight.remove(future);
    }
  }

  /// Call after saving anything: every visible screen reloads its data.
  void dataChanged() => dataVersion.value++;

  /// Pull-to-refresh: reload everything and wait until the visible screens have their new data.
  Future<void> refreshAll() async {
    dataChanged();
    // Let the screens start their requests, then wait for them (errors are shown by the screens).
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await Future.wait(_inFlight.map((f) => f.then((_) {}, onError: (_) {})));
  }

  /// Reads the saved token. Does not call the server, so the app opens instantly even when offline;
  /// an expired token is caught by the first request that returns 401.
  Future<void> restore() async {
    try {
      final token = await store.read(_tokenKey);
      final userJson = await store.read(_userKey);
      if (token != null && userJson != null) {
        api.client.token = token;
        _user = ApiUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _status = SessionStatus.signedIn;
      } else {
        _status = SessionStatus.signedOut;
      }
    } catch (_) {
      // Unreadable storage (e.g. restored backup on a new phone): start signed out.
      await _clear();
      _status = SessionStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async =>
      _save(await api.signIn(email: email.trim(), password: password));

  Future<void> signUp({required String name, required String email, required String password}) async =>
      _save(await api.signUp(name: name.trim(), email: email.trim(), password: password));

  Future<void> signOut() async {
    if (_status == SessionStatus.signedOut) return;
    await _clear();
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  /// Fetches the latest profile, e.g. after editing it on another device.
  Future<void> refreshUser() async => _setUser(await api.me());

  /// Saves profile or settings changes, keeps the cached user in sync and reloads the screens.
  /// See [HealthBuddyApi.updateMe] for the arguments.
  Future<void> updateProfile({
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
    await _setUser(
      await api.updateMe(
        name: name,
        status: status,
        birthDate: birthDate,
        sex: sex,
        heightCm: heightCm,
        weightKg: weightKg,
        lifeStage: lifeStage,
        stepsTarget: stepsTarget,
        clearStepsTarget: clearStepsTarget,
        reminderDaily: reminderDaily,
        reminderBedtime: reminderBedtime,
        bedtimeTime: bedtimeTime,
        weeklySummary: weeklySummary,
        language: language,
      ),
    );
    dataChanged();
  }

  Future<void> _save(AuthResult result) async {
    api.client.token = result.token;
    await store.write(_tokenKey, result.token);
    _status = SessionStatus.signedIn;
    await _setUser(result.user);
  }

  Future<void> _setUser(ApiUser user) async {
    _user = user;
    await store.write(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> _clear() async {
    api.client.token = null;
    _user = null;
    _cache.clear();
    await store.delete(_tokenKey);
    await store.delete(_userKey);
  }
}

/// Gives every screen access to the session: `SessionScope.of(context).api.summary()`.
class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'No SessionScope above this widget');
    return scope!.notifier!;
  }
}
