import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../main.dart';
import '../models/turno.dart';
import '../models/venta.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class TurnoProvider extends ChangeNotifier {
  Turno? _turnoActivo;
  bool _isLoading = false;

  Turno? get turnoActivo => _turnoActivo;
  bool get isLoading => _isLoading;
  bool get hayTurnoActivo => _turnoActivo != null;

  Future<String> _getTerminal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kTerminalKey) ?? 'Terminal 1';
  }

  Future<void> cargarTurnoActivo() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Buscar en SQLite local
      _turnoActivo = await DbService.instance.getTurnoActivo();

      // 2. Si no hay local, buscar en Supabase
      if (_turnoActivo == null) {
        try {
          final email = AuthService.instance.email;
          if (email != null) {
            final rows = await supabase
                .from('pos_turno')
                .select()
                .eq('licencia_email', email)
                .eq('estado', 'ABIERTO')
                .order('fecha_apertura', ascending: false)
                .limit(1);

            if (rows.isNotEmpty) {
              final turno = Turno.fromSupabase(rows.first);
              await DbService.instance.guardarTurno(turno);
              _turnoActivo = turno;
            }
          }
        } catch (_) {
          // Sin internet — no hay turno activo
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> abrirTurno(double efectivoInicial) async {
    _isLoading = true;
    notifyListeners();
    try {
      final email = AuthService.instance.email;
      final terminal = await _getTerminal();
      if (email == null) return false;

      final row = {
        'licencia_email':   email,
        'terminal':         terminal,
        'sucursal':         'Principal',
        'efectivo_inicial': efectivoInicial,
        'estado':           'ABIERTO',
        'fecha_apertura':   DateTime.now().toIso8601String(),
      };

      int? supaId;
      try {
        final res = await supabase
            .from('pos_turno')
            .insert(row)
            .select('id')
            .single();
        supaId = res['id'] as int?;
      } catch (_) {
        // Sin internet — abrimos solo local
      }

      final turno = Turno(
        id: supaId,
        efectivoInicial: efectivoInicial,
        estado: 'ABIERTO',
        fechaApertura: DateTime.now().toIso8601String(),
        terminal: terminal,
      );
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

  Future<bool> cerrarTurno(double totalContado) async {
    final turno = _turnoActivo;
    if (turno == null || turno.id == null) return false;

    _isLoading = true;
    notifyListeners();
    try {
      final List<Venta> ventas = await DbService.instance.getVentasTurno(turno.id!);
      final double totalVentas = ventas.fold(0.0, (sum, v) => sum + v.total);
      final double diferencia = totalContado - totalVentas;

      try {
        await supabase.from('pos_turno').update({
          'estado':        'CERRADO',
          'fecha_cierre':  DateTime.now().toIso8601String(),
          'total_contado': totalContado,
          'diferencia':    diferencia,
        }).eq('id', turno.id!);
      } catch (_) {
        // Sin internet — cerrar solo local
      }

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
