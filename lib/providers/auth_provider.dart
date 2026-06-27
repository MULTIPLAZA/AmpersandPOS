import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkSession() async {
    _isAuthenticated = AuthService.instance.isLoggedIn;
    if (_isAuthenticated) {
      SyncService.instance.sincronizarPendientes();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String clave, String terminal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await AuthService.instance.login(email, clave, terminal);
      if (res['ok'] == true) {
        _isAuthenticated = true;
        SyncService.instance.sincronizarPendientes();
        return true;
      } else {
        _error = (res['error'] as String?) ?? 'Credenciales inválidas';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
}
