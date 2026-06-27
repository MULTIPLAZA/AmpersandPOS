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

  /// Checks whether the stored licence token is still valid.
  /// On success it fires a background sync without awaiting it.
  Future<void> checkSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _isAuthenticated = await AuthService.instance.verificarLicencia();
      if (_isAuthenticated) {
        // Fire-and-forget: refresh catalogue / pending sales in the background.
        SyncService.instance.sincronizarTodo();
      }
    } catch (e) {
      _isAuthenticated = false;
      _error = 'Error al verificar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Activates a new licence with the provided credentials.
  /// Returns [true] when the server accepted the activation.
  Future<bool> login(String email, String clave, String terminal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final ok =
          await AuthService.instance.activarLicencia(email, clave, terminal);
      if (ok) {
        _isAuthenticated = true;
        // Fire-and-forget sync after successful login.
        SyncService.instance.sincronizarTodo();
      } else {
        _error = 'Credenciales inválidas o licencia no encontrada.';
      }
      return ok;
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the stored session and marks the user as unauthenticated.
  Future<void> logout() async {
    await AuthService.instance.clearSession();
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
}
