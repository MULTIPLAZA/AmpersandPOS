import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../config.dart';
import 'auth_service.dart';
import 'db_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  Future<String> _getTerminal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kTerminalKey) ?? 'Terminal 1';
  }

  /// Sube al Supabase todas las ventas pendientes guardadas en SQLite offline.
  /// Inserta en pos_ventas igual que mi-pos (items como JSON, licencia_email).
  Future<void> sincronizarPendientes() async {
    final ventas = await DbService.instance.getVentasSinSincronizar();
    final email = AuthService.instance.email;
    if (email == null || ventas.isEmpty) return;

    final terminal = await _getTerminal();

    for (final venta in ventas) {
      try {
        final items = jsonDecode(venta.itemsJson) as List<dynamic>;

        final row = {
          'licencia_email': email,
          'terminal':       terminal,
          'sucursal':       'Principal',
          'fecha':          venta.fecha,
          'total':          venta.total,
          'metodo_pago':    venta.metodoPago.toUpperCase(),
          'comprobante':    '',
          'items':          jsonEncode(items.map((i) => {
            'id':     i['id'],
            'nombre': i['nombre'],
            'name':   i['nombre'],
            'qty':    i['cantidad'],
            'price':  i['precio'],
            'precio': i['precio'],
            'costo':  i['costo'] ?? 0,
            'iva':    i['iva'] ?? '10',
            'cat':    i['categoria'] ?? '',
          }).toList()),
        };

        await supabase.from('pos_ventas').insert(row);
        await DbService.instance.marcarVentaSincronizada(venta.id!);
      } catch (_) {
        // Deja la venta como pendiente para reintentar después
      }
    }
  }
}
