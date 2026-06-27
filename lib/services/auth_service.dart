import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config.dart';
import '../main.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  String? _email;
  String? get email => _email;
  bool get isLoggedIn => _email != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(kEmailKey);
  }

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(kDeviceIdKey);
    if (id == null) {
      id = 'dev_' + const Uuid().v4().replaceAll('-', '').substring(0, 20);
      await prefs.setString(kDeviceIdKey, id);
    }
    return id;
  }

  Future<Map<String, dynamic>> login(String email, String clave, String terminal) async {
    try {
      final deviceId = await getDeviceId();
      final res = await supabase.rpc('activar_licencia', params: {
        'p_clave':     clave.toUpperCase().trim(),
        'p_email':     email.trim().toLowerCase(),
        'p_device_id': deviceId,
      });

      if (res == null || res['ok'] != true) {
        return {'ok': false, 'error': (res?['error'] as String?) ?? 'Error al activar'};
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kEmailKey, email.trim().toLowerCase());
      await prefs.setString(kTokenKey, (res['token'] as String?) ?? '');
      await prefs.setString(kTerminalKey, terminal);
      _email = email.trim().toLowerCase();

      return {
        'ok': true,
        'plan': res['plan'] ?? 'Basico',
        'vence': res['vence'] ?? '',
      };
    } catch (e) {
      return {'ok': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kEmailKey);
    await prefs.remove(kTokenKey);
    _email = null;
  }
}
