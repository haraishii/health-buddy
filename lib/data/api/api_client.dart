import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL of the Go backend. Override per run:
///   flutter run --dart-define=API_URL=http://10.0.2.2:8080   (Android emulator)
///   flutter run --dart-define=API_URL=https://your-api.example.com
/// The default works for Chrome, the iOS simulator, and a USB phone after `adb reverse tcp:8080 tcp:8080`.
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

/// An error the UI can show as is. [statusCode] is 0 when the server could not be reached.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON-over-HTTP client: adds the bearer token, decodes JSON, and turns failures into [ApiException].
class ApiClient {
  ApiClient({this.baseUrl = apiBaseUrl, http.Client? httpClient, this.timeout = const Duration(seconds: 20)})
    : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  /// Set by the session after sign in; cleared on sign out.
  String? token;

  /// Called when an authenticated request returns 401 (token expired or user deleted).
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String?>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body ?? const {});
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body: body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Map<String, String?>? query, Object? body}) async {
    final params = {
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params.isEmpty ? null : params);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(timeout));
    } on TimeoutException {
      throw const ApiException(0, 'The server took too long to respond. Please try again.');
    } on http.ClientException {
      // Also covers socket errors: package:http wraps them in ClientException on every platform.
      throw const ApiException(0, 'Cannot reach the server. Check your connection and the API address.');
    }

    final dynamic json = response.body.isEmpty ? null : _tryDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    if (response.statusCode == 401 && token != null) onUnauthorized?.call();
    final message = json is Map && json['error'] is String
        ? json['error'] as String
        : 'Something went wrong (${response.statusCode}).';
    throw ApiException(response.statusCode, _capitalize(message));
  }

  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void close() => _http.close();
}
