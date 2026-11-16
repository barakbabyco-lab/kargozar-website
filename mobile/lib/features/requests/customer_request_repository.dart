import '../../core/network/kargozar_api_client.dart';

class CustomerRequestEvent {
  const CustomerRequestEvent({
    required this.status,
    this.publicMessage,
    this.createdAt,
  });

  final String status;
  final String? publicMessage;
  final DateTime? createdAt;

  factory CustomerRequestEvent.fromJson(Map<String, dynamic> json) =>
      CustomerRequestEvent(
        status: json['status']?.toString() ?? '',
        publicMessage: json['public_message']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class CustomerServiceRequest {
  const CustomerServiceRequest({
    required this.id,
    required this.trackingCode,
    required this.status,
    this.customerNote,
    this.serviceTitle,
    this.createdAt,
    this.events = const [],
  });

  final String id;
  final String trackingCode;
  final String status;
  final String? customerNote;
  final String? serviceTitle;
  final DateTime? createdAt;
  final List<CustomerRequestEvent> events;

  factory CustomerServiceRequest.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    final serviceMap = service is Map<String, dynamic> ? service : null;
    return CustomerServiceRequest(
      id: (json['id'] ?? json['public_id'] ?? '').toString(),
      trackingCode: json['tracking_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      customerNote: json['customer_note']?.toString(),
      serviceTitle: serviceMap?['title']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      events: json['events'] is List
          ? (json['events'] as List)
              .whereType<Map<String, dynamic>>()
              .map(CustomerRequestEvent.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class CustomerRequestRepository {
  const CustomerRequestRepository(this._api);

  final KargozarApiClient _api;

  Future<CustomerServiceRequest> create({
    required String serviceId,
    String? customerNote,
    required String idempotencyKey,
  }) async {
    final response = await _api.createServiceRequest(
      serviceId: serviceId,
      customerNote: customerNote,
      idempotencyKey: idempotencyKey,
    );
    return _fromResponse(response);
  }

  Future<List<CustomerServiceRequest>> getMine({int page = 1}) async {
    final response = await _api.getMyRequests(page: page);
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('فهرست درخواست‌ها معتبر نیست.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(CustomerServiceRequest.fromJson)
        .toList(growable: false);
  }

  Future<CustomerServiceRequest> getByTrackingCode(String trackingCode) async {
    return _fromResponse(await _api.getMyRequest(trackingCode));
  }

  CustomerServiceRequest _fromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('پاسخ پرونده معتبر نیست.');
    }
    return CustomerServiceRequest.fromJson(data);
  }
}
