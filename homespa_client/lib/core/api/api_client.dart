import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Thin JSON client for the Kaizen platform mobile API.
/// Attaches the bearer token from [AuthSession.current] when present and
/// surfaces the server's `{error: "..."}` message as [ApiException].
class ApiClient {
  static const String baseUrl = 'https://kaizenspa-admin.vercel.app/api/mobile';

  final http.Client _client;
  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final request = http.Request(method, uri);
    request.headers['Content-Type'] = 'application/json';
    final session = AuthSession.current;
    if (session != null) {
      request.headers['Authorization'] = 'Bearer ${session.token}';
    }
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Tidak dapat terhubung. Periksa koneksi internet Anda.',
        0,
      );
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Request failed (${response.statusCode})';
      throw ApiException(message, response.statusCode);
    }
    return decoded;
  }
}

/// Single shared instance — the API is stateless per-request and the token is
/// read from [AuthSession.current] on every call.
final apiClient = ApiClient();
