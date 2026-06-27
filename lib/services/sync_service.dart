import 'dart:convert';
import '../main.dart';
import 'auth_service.dart';
import 'db_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  /// Sube al Supabase todas las ventas pendientes guardadas en SQLite offline.
  Future<void> sincronizarPendientes() async {
    final ventas = await DbService.instance.getVentasSinSincronizar();
    final userId = AuthService.instance.userId;
    if (userId == null || ventas.isEmpty) return;

    for (final venta in ventas) {
      try {
        // Insertar cabecera en Supabase
        final ventaRes = await supabase.from('ventas').insert({
          'id_licencia': userId,
          'id_turno': venta.idTurno,
          'terminal': venta.terminal ?? '',
          'total': venta.total,
          'metodo_pago': venta.metodoPago,
          'estado': 'completada',
          'fecha': venta.fecha,
        }).select('id_venta').single();

        final idVenta = ventaRes['id_venta'] as int;

        // Insertar líneas
        final items = jsonDecode(venta.itemsJson) as List<dynamic>;
        final lineas = items.map((item) => {
          'id_licencia': userId,
          'id_venta': idVenta,
          'id_producto': item['id'],
          'nombre_producto': item['nombre'],
          'cantidad': item['cantidad'],
          'precio_unitario': item['precio'],
          'iva': item['iva'] ?? '10',
          'categoria': item['categoria'],
        }).toList();

        if (lineas.isNotEmpty) {
          await supabase.from('venta_lineas').insert(lineas);
        }

        await DbService.instance.marcarVentaSincronizada(venta.id!);
      } catch (_) {
        // Deja la venta como pendiente para reintentar después
      }
    }
  }
}
