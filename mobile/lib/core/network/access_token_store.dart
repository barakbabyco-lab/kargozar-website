import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction keeps authentication persistence testable without platform
/// channels. Production uses the operating system's secure storage.
abstract interface class AccessTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureAccessTokenStore implements AccessTokenStore {
  SecureAccessTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'kargozar_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}


/// A separate installation-scoped credential for anonymous support chat.
class SecureGuestSupportTokenStore {
  SecureGuestSupportTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'kargozar_guest_support_token';
  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
}
