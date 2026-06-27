import 'package:flutter/foundation.dart';
import '../models/turno.dart';
import '../models/venta.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class TurnoProvider extends ChangeNotifier {
  Turno? _turnoActivo;
  bool _isLoading = false;

  Turno? get turnoActivo => _turnoActivo;
  bool get isLoading => _isLoading;
  bool get hayTurnoActivo => _turnoActivo != null;

  /// Loads the active shift from the local DB.
  /// If nothing is found locally it queries [SPObtenerTurnoActivo] on the
  /// server and persists the result so subsequent launches work offline.
  Future<void> cargarTurnoActivo() async {
    _isLoading = true;
    notifyListeners();
    try {
      _turnoActivo = await DbService.instance.getTurnoActivo();

      if (_turnoActivo == null) {
        // Fall back to server lookup.
        try {
          final token = await AuthService.instance.getToken();
          if (token != null) {
            final rows = await ApiService.instance
                .post("Exec SPObtenerTurnoActivo @Token='$token'");
            if (rows.isNotEmpty && (rows[0] as List).isNotEmpty) {
              final turno =
                  Turno.fromJson((rows[0] as List).first as Map<String, dynamic>);
              await DbService.instance.guardarTurno(turno);
              _turnoActivo = turno;
            }
          }
        } catch (_) {
          // Server unavailable – no active shift found.
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Opens a new shift on the server and stores it locally.
  /// Returns [true] on success.
  Future<bool> abrirTurno(double efectivoInicial) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await AuthService.instance.getToken();
      final terminal = await AuthService.instance.getTerminal();
      if (token == null || terminal == null) return false;

      final rows = await ApiService.instance.post(
        "Exec SPAbrirTurno @Token='$token', "
        "@EfectivoInicial=$efectivoInicial, @Terminal='$terminal'",
      );
      if (rows.isEmpty || (rows[0] as List).isEmpty) return false;

      final turno = Turno.fromJson((rows[0] as List).first as Map<String, dynamic>);
      await DbService.instance.guardarTurno(turno);
      _turnoActivo = turno;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Closes the active shift.
  ///
  /// [totalContado] is the physical cash amount counted at closing time.
  /// The provider calculates the difference against the sum of local sales
  /// and sends it to [SPCerrarTurno]. Returns [true] on success.
  Future<bool> cerrarTurno(double totalContado) async {
    final turno = _turnoActivo;
    if (turno == null || turno.id == null) return false;

    _isLoading = true;
    notifyListeners();
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return false;

      // Sum all sales registered locally for this shift.
      final List<Venta> ventas =
          await DbService.instance.getVentasTurno(turno.id!);
      final double totalVentas =
          ventas.fold(0.0, (sum, v) => sum + v.total);
      final double diferencia = totalContado - totalVentas;

      final rows = await ApiService.instance.post(
        "Exec SPCerrarTurno @Token='$token', @IDTurno=${turno.id}, "
        "@TotalContado=$totalContado, @Diferencia=$diferencia",
      );
      if (rows.isEmpty || (rows[0] as List).isEmpty) return false;

      await DbService.instance.cerrarTurnoLocal(turno.id!);
      _turnoActivo = null;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
