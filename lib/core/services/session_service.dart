import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionService {
  Future<int?> getCurrentUserId();
  Future<void> startSession(int userId);
  Future<void> endSession();
}

class SecureStorageSessionService implements SessionService {
  static const _userIdKey = 'usuario_id';

  final FlutterSecureStorage _storage;

  SecureStorageSessionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<int?> getCurrentUserId() async {
    final storedId = await _storage.read(key: _userIdKey);
    if (storedId == null) return null;
    return int.tryParse(storedId);
  }

  @override
  Future<void> startSession(int userId) {
    return _storage.write(key: _userIdKey, value: userId.toString());
  }

  @override
  Future<void> endSession() {
    return _storage.delete(key: _userIdKey);
  }
}
