import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config.dart';
import '../main.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  String? get userId => supabase.auth.currentUser?.id;
  bool get isLoggedIn => supabase.auth.currentSession != null;

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(kDeviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(kDeviceIdKey, id);
    }
    return id;
  }

  Future<String?> getTerminalName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kTerminalKey);
  }

  Future<void> _saveTerminalName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kTerminalKey, name);
  }

  /// Login con email/clave. Retorna mapa con ok, error, plan, vence, nombreNegocio.
  Future<Map<String, dynamic>> login(String email, String clave, String terminal) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: clave,
      );

      if (res.user == null) {
        return {'ok': false, 'error': 'Credenciales incorrectas'};
      }

      // Verificar licencia activa
      final licencia = await supabase
          .from('licencias')
          .select()
          .eq('id', res.user!.id)
          .eq('activo', true)
          .maybeSingle();

      if (licencia == null) {
        await supabase.auth.signOut();
        return {'ok': false, 'error': 'No tienes licencia activa. Contactá a NODO.'};
      }

      final vence = DateTime.parse(licencia['fecha_vence'] as String);
      if (vence.isBefore(DateTime.now())) {
        await supabase.auth.signOut();
        return {'ok': false, 'error': 'Licencia vencida el ${licencia['fecha_vence']}'};
      }

      // Registrar dispositivo
      final deviceId = await getDeviceId();
      await _saveTerminalName(terminal);

      await supabase.from('activaciones').upsert({
        'id_licencia': res.user!.id,
        'device_id': deviceId,
        'nombre_terminal': terminal,
        'activo': true,
      }, onConflict: 'device_id');

      return {
        'ok': true,
        'plan': licencia['plan'],
        'vence': licencia['fecha_vence'],
        'nombre_negocio': licencia['nombre_negocio'] ?? '',
      };
    } on AuthException catch (e) {
      return {'ok': false, 'error': e.message};
    } catch (e) {
      return {'ok': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
