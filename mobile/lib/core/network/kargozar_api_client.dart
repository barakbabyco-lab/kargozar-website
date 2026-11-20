import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'access_token_store.dart';

/// Lightweight client for the versioned Kargozar API.
///
/// Configure the API root at build time, for example:
/// flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
///
/// Access tokens are persisted through the platform secure-storage facility.
class KargozarApiClient {
  KargozarApiClient({
    String? baseUrl,
    http.Client? httpClient,
    String? accessToken,
    AccessTokenStore? tokenStore,
    SecureGuestSupportTokenStore? guestTokenStore,
  })  : _tokenStore = tokenStore ?? SecureAccessTokenStore(),
        _guestTokenStore = guestTokenStore ?? SecureGuestSupportTokenStore(),
        _baseUri = Uri.parse(
          (baseUrl ?? const String.fromEnvironment('API_BASE_URL')).trim(),
        ),
        _http = httpClient ?? http.Client(),
        _accessToken = accessToken;

  final Uri _baseUri;
  final http.Client _http;
  final AccessTokenStore _tokenStore;
  final SecureGuestSupportTokenStore _guestTokenStore;
  String? _accessToken;
  String? _guestSupportToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// Restore the previous customer session before making authenticated calls.
  Future<void> restoreAccessToken() async {
    _accessToken = await _tokenStore.read();
  }

  Future<void> setAccessToken(String? token) async {
    _accessToken = token;
    if (token == null || token.isEmpty) {
      await _tokenStore.clear();
    } else {
      await _tokenStore.write(token);
    }
  }

  void close() {
    _http.close();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    if (!_baseUri.hasScheme || _baseUri.host.isEmpty) {
      throw const KargozarApiException(
        code: 'API_NOT_CONFIGURED',
        message: 'نشانی سرور هنوز تنظیم نشده است.',
        statusCode: 0,
      );
    }
    // Remote customer traffic must never use cleartext HTTP. Allow HTTP only
    // for local emulator/development hosts.
    const localHosts = {'localhost', '127.0.0.1', '::1', '10.0.2.2'};
    if (_baseUri.scheme != 'https' &&
        !(_baseUri.scheme == 'http' &&
            localHosts.contains(_baseUri.host.toLowerCase()))) {
      throw const KargozarApiException(
        code: 'API_INSECURE_URL',
        message: 'ارتباط با سرور باید از طریق نشانی امن HTTPS انجام شود.',
        statusCode: 0,
      );
    }
    if (_baseUri.userInfo.isNotEmpty ||
        _baseUri.hasQuery ||
        _baseUri.hasFragment) {
      throw const KargozarApiException(
        code: 'API_INVALID_URL',
        message: 'نشانی سرور معتبر نیست.',
        statusCode: 0,
      );
    }

    final root = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    return root.resolve(path).replace(queryParameters: query);
  }

  Future<String> _ensureGuestSupportToken() async {
    final existing = _guestSupportToken ?? await _guestTokenStore.read();
    if (existing != null && RegExp(r'^[a-f0-9]{64}
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (authenticated && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (guestSupportToken != null && guestSupportToken.isNotEmpty) {
      headers['X-Support-Guest-Token'] = guestSupportToken;
    }
    return headers;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool authenticated = false,
    String? guestSupportToken,
    String? idempotencyKey,
  }) async {
    final uri = _uri(path, query);
    late final http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(_headers(authenticated: authenticated, guestSupportToken: guestSupportToken));
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        request.headers['Idempotency-Key'] = idempotencyKey;
      }
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request);
      response = await http.Response.fromStream(streamed);
    } on Exception {
      throw const KargozarApiException(
        code: 'NETWORK_ERROR',
        message: 'ارتباط با سرور برقرار نشد. اتصال اینترنت را بررسی کنید.',
        statusCode: 0,
      );
    }

    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final root = decoded is Map<String, dynamic> ? decoded : null;
      final error = root?['error'];
      final errorMap = error is Map<String, dynamic> ? error : null;
      throw KargozarApiException(
        code: errorMap?['code']?.toString() ?? 'HTTP_ERROR',
        message: errorMap?['message']?.toString() ??
            'درخواست با خطا مواجه شد. دوباره تلاش کنید.',
        statusCode: response.statusCode,
        fields: errorMap?['fields'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(errorMap!['fields'] as Map)
            : const {},
      );
    }

    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }

  Future<Map<String, dynamic>> requestOtp(String mobile) => _send(
        'POST',
        'auth/otp/request',
        body: {'mobile': mobile},
      );

  Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String code,
  }) async {
    final response = await _send(
      'POST',
      'auth/otp/verify',
      body: {'mobile': mobile, 'code': code},
    );
    final data = response['data'];
    final token = data is Map<String, dynamic>
        ? data['access_token']?.toString()
        : null;
    if (token == null || token.isEmpty) {
      throw const KargozarApiException(
        code: 'INVALID_AUTH_RESPONSE',
        message: 'پاسخ احراز هویت سرور معتبر نیست.',
        statusCode: 502,
      );
    }
    await _tokenStore.write(token);
    _accessToken = token;
    return response;
  }

  Future<void> logout() async {
    try {
      await _send('POST', 'auth/logout', authenticated: true);
    } finally {
      // A failed network request must not leave a locally usable session.
      _accessToken = null;
      await _tokenStore.clear();
    }
  }

  Future<Map<String, dynamic>> getCategories() =>
      _send('GET', 'service-categories');

  Future<Map<String, dynamic>> getServices({
    String? category,
    String? query,
    int page = 1,
  }) {
    final parameters = <String, String>{'page': page.toString()};
    if (category != null && category.isNotEmpty) {
      parameters['category'] = category;
    }
    if (query != null && query.isNotEmpty) parameters['q'] = query;
    return _send('GET', 'services', query: parameters);
  }

  Future<Map<String, dynamic>> getService(String slug) =>
      _send('GET', 'services/${Uri.encodeComponent(slug)}');

  Future<Map<String, dynamic>> createServiceRequest({
    required String serviceId,
    String? customerNote,
    required String idempotencyKey,
  }) =>
      _send(
        'POST',
        'service-requests',
        authenticated: true,
        idempotencyKey: idempotencyKey,
        body: {
          'service_id': serviceId,
          if (customerNote != null && customerNote.isNotEmpty)
            'customer_note': customerNote,
        },
      );

  Future<Map<String, dynamic>> startGuestSupportConversation(String body) async {
    final token = await _ensureGuestSupportToken();
    return _send('POST', 'guest/support-conversations',
        guestSupportToken: token, body: {'body': body});
  }

  Future<Map<String, dynamic>> getGuestSupportMessages(int conversationId) async {
    final token = await _ensureGuestSupportToken();
    return _send('GET', 'guest/support-conversations/$conversationId/messages',
        guestSupportToken: token);
  }

  Future<Map<String, dynamic>> sendGuestSupportMessage(int conversationId, String body) async {
    final token = await _ensureGuestSupportToken();
    return _send('POST', 'guest/support-conversations/$conversationId/messages',
        guestSupportToken: token, body: {'body': body});
  }

  Future<Map<String, dynamic>> getMyRequests({int page = 1}) => _send(
        'GET',
        'me/service-requests',
        query: {'page': page.toString()},
        authenticated: true,
      );

  Future<Map<String, dynamic>> getMyRequest(String trackingCode) => _send(
        'GET',
        'me/service-requests/${Uri.encodeComponent(trackingCode)}',
        authenticated: true,
      );
}

/// Normalized API error safe to display in the customer application.
class KargozarApiException implements Exception {
  const KargozarApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.fields = const {},
  });

  final String code;
  final String message;
  final int statusCode;
  final Map<String, dynamic> fields;

  @override
  String toString() => message;
}
).hasMatch(existing)) {
      _guestSupportToken = existing;
      return existing;
    }
    final random = Random.secure();
    final token = List<int>.generate(32, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await _guestTokenStore.write(token);
    _guestSupportToken = token;
    return token;
  }

  Map<String, String> _headers({bool authenticated = false, String? guestSupportToken}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (authenticated && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool authenticated = false,
    String? idempotencyKey,
  }) async {
    final uri = _uri(path, query);
    late final http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(_headers(authenticated: authenticated));
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        request.headers['Idempotency-Key'] = idempotencyKey;
      }
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request);
      response = await http.Response.fromStream(streamed);
    } on Exception {
      throw const KargozarApiException(
        code: 'NETWORK_ERROR',
        message: 'ارتباط با سرور برقرار نشد. اتصال اینترنت را بررسی کنید.',
        statusCode: 0,
      );
    }

    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final root = decoded is Map<String, dynamic> ? decoded : null;
      final error = root?['error'];
      final errorMap = error is Map<String, dynamic> ? error : null;
      throw KargozarApiException(
        code: errorMap?['code']?.toString() ?? 'HTTP_ERROR',
        message: errorMap?['message']?.toString() ??
            'درخواست با خطا مواجه شد. دوباره تلاش کنید.',
        statusCode: response.statusCode,
        fields: errorMap?['fields'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(errorMap!['fields'] as Map)
            : const {},
      );
    }

    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }

  Future<Map<String, dynamic>> requestOtp(String mobile) => _send(
        'POST',
        'auth/otp/request',
        body: {'mobile': mobile},
      );

  Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String code,
  }) async {
    final response = await _send(
      'POST',
      'auth/otp/verify',
      body: {'mobile': mobile, 'code': code},
    );
    final data = response['data'];
    final token = data is Map<String, dynamic>
        ? data['access_token']?.toString()
        : null;
    if (token == null || token.isEmpty) {
      throw const KargozarApiException(
        code: 'INVALID_AUTH_RESPONSE',
        message: 'پاسخ احراز هویت سرور معتبر نیست.',
        statusCode: 502,
      );
    }
    await _tokenStore.write(token);
    _accessToken = token;
    return response;
  }

  Future<void> logout() async {
    try {
      await _send('POST', 'auth/logout', authenticated: true);
    } finally {
      // A failed network request must not leave a locally usable session.
      _accessToken = null;
      await _tokenStore.clear();
    }
  }

  Future<Map<String, dynamic>> getCategories() =>
      _send('GET', 'service-categories');

  Future<Map<String, dynamic>> getServices({
    String? category,
    String? query,
    int page = 1,
  }) {
    final parameters = <String, String>{'page': page.toString()};
    if (category != null && category.isNotEmpty) {
      parameters['category'] = category;
    }
    if (query != null && query.isNotEmpty) parameters['q'] = query;
    return _send('GET', 'services', query: parameters);
  }

  Future<Map<String, dynamic>> getService(String slug) =>
      _send('GET', 'services/${Uri.encodeComponent(slug)}');

  Future<Map<String, dynamic>> createServiceRequest({
    required String serviceId,
    String? customerNote,
    required String idempotencyKey,
  }) =>
      _send(
        'POST',
        'service-requests',
        authenticated: true,
        idempotencyKey: idempotencyKey,
        body: {
          'service_id': serviceId,
          if (customerNote != null && customerNote.isNotEmpty)
            'customer_note': customerNote,
        },
      );

  Future<Map<String, dynamic>> startSupportConversation(String body) => _send(
        'POST',
        'support-conversations',
        authenticated: true,
        body: {'body': body},
      );

  Future<Map<String, dynamic>> getSupportMessages(int conversationId) => _send(
        'GET',
        'me/support-conversations/$conversationId/messages',
        authenticated: true,
      );

  Future<Map<String, dynamic>> sendSupportMessage(int conversationId, String body) => _send(
        'POST',
        'me/support-conversations/$conversationId/messages',
        authenticated: true,
        body: {'body': body},
      );

  Future<Map<String, dynamic>> getMyRequests({int page = 1}) => _send(
        'GET',
        'me/service-requests',
        query: {'page': page.toString()},
        authenticated: true,
      );

  Future<Map<String, dynamic>> getMyRequest(String trackingCode) => _send(
        'GET',
        'me/service-requests/${Uri.encodeComponent(trackingCode)}',
        authenticated: true,
      );
}

/// Normalized API error safe to display in the customer application.
class KargozarApiException implements Exception {
  const KargozarApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.fields = const {},
  });

  final String code;
  final String message;
  final int statusCode;
  final Map<String, dynamic> fields;

  @override
  String toString() => message;
}
