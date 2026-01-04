import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class VaultService {
  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Access your secure vault',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> saveSecret(String key, String value) async =>
      await _storage.write(key: key, value: value);

  Future<String?> getSecret(String key) async =>
      await _storage.read(key: key);
}