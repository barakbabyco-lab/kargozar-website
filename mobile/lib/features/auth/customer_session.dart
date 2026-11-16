import '../../core/network/kargozar_api_client.dart';

/// Coordinates customer authentication state for the app layer.
class CustomerSession {
  const CustomerSession(this._api);

  final KargozarApiClient _api;

  bool get isAuthenticated => _api.hasAccessToken;

  Future<bool> restore() async {
    await _api.restoreAccessToken();
    return isAuthenticated;
  }

  Future<void> requestOtp(String mobile) async {
    await _api.requestOtp(mobile);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String code,
  }) async {
    return _api.verifyOtp(mobile: mobile, code: code);
  }

  Future<void> signOut() => _api.logout();
}
