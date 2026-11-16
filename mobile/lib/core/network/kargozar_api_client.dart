import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lightweight client for the versioned Kargozar API.
///
/// Configure the API root at build time, for example:
/// flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
///
/// No credentials or customer data are persisted by this class. The caller
/// supplies the current bearer token and is responsible for secure storage.
class KargozarApiClient {
  KargozarApiClient({
    String? baseUrl,
    http.Client? httpClient,
    String? accessToken,
  })  : _baseUri = Uri.parse(
          (baseUrl ?? const String.fromEnvironment('API_BASE_URL')).trim(),
        ),
        _http = httpClient ?? http.Client(),
        _accessToken = accessToken;

  final Uri _baseUri;
  final http.Client _http;
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
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
    final root = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    return root.resolve(path).replace(queryParameters: query);
  }

  Map<String, String> _headers({bool authenticated = false}) {
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
  }) =>
      _send(
        'POST',
        'auth/otp/verify',
        body: {'mobile': mobile, 'code': code},
      );

  Future<void> logout() async {
    await _send('POST', 'auth/logout', authenticated: true);
    _accessToken = null;
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
