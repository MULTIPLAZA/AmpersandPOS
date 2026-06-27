import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kLicTokenKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kEmailKey);
  }

  Future<String?> getTerminal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kTerminalKey);
  }

  /// Returns the stored device ID, generating and persisting one if absent.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(kDeviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(kDeviceIdKey, deviceId);
    }
    return deviceId;
  }

  /// Calls SPActivarLicencia, stores token + email + terminal on success.
  Future<bool> activarLicencia(
    String email,
    String clave,
    String terminal,
  ) async {
    try {
      final deviceId = await getDeviceId();

      final response = await ApiService.instance.post(
        "Exec SPActivarLicencia @Email='$email', @Clave='$clave',"
        " @DeviceID='$deviceId', @NombreTerminal='$terminal', @Modo='ACTIVAR'",
      );

      if (response.isEmpty || (response[0] as List).isEmpty) return false;

      final row = (response[0] as List).first as Map<String, dynamic>;
      final token = row['Token'] as String?;
      if (token == null || token.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kLicTokenKey, token);
      await prefs.setString(kEmailKey, email);
      await prefs.setString(kTerminalKey, terminal);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns true when the server confirms the stored token is still valid.
  Future<bool> verificarLicencia() async {
    try {
      final token = await getToken();
      final email = await getEmail();
      if (token == null || email == null) return false;

      final deviceId = await getDeviceId();

      final response = await ApiService.instance.post(
        "Exec SPVerificarLicencia @Token='$token',"
        " @Email='$email', @DeviceID='$deviceId'",
      );

      // Accessing response[0][0] throws if the server returned no rows.
      final _ = (response[0] as List).first;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes session credentials from SharedPreferences.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kLicTokenKey);
    await prefs.remove(kEmailKey);
    await prefs.remove(kTerminalKey);
  }
}
