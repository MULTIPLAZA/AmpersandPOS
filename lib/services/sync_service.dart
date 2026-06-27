import 'package:flutter/foundation.dart';

import '../models/categoria.dart';
import '../models/producto.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'db_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  /// Uploads local ventas that have not yet been sent to the server.
  Future<void> sincronizarVentas() async {
    final ventas = await DbService.instance.getVentasSinSincronizar();
    if (ventas.isEmpty) return;

    final token = await AuthService.instance.getToken();
    if (token == null) return;

    final terminal = await AuthService.instance.getTerminal() ?? '';

    for (final venta in ventas) {
      try {
        // Escape single quotes inside the JSON blob so it doesn't break the SP call.
        final escapedItems = venta.itemsJson.replaceAll("'", "''");

        await ApiService.instance.post(
          "Exec SPGuardarVenta @Token='$token',"
          " @IDTurno=${venta.idTurno},"
          " @Total=${venta.total},"
          " @MetodoPago='${venta.metodoPago}',"
          " @Items='$escapedItems',"
          " @Terminal='$terminal'",
        );

        if (venta.id != null) {
          await DbService.instance.marcarVentaSincronizada(venta.id!);
        }
      } catch (e) {
        // Non-fatal: log and continue with next venta.
        debugPrint('SyncService.sincronizarVentas — venta ${venta.id}: $e');
      }
    }
  }

  /// Downloads the product catalog (categories + products) from the server.
  Future<void> descargarCatalogo() async {
    final token = await AuthService.instance.getToken();
    if (token == null) return;

    // Categories
    final catResponse = await ApiService.instance.post(
      "Exec SPListarCategorias @Token='$token'",
    );
    if (catResponse.isNotEmpty) {
      for (final row in (catResponse[0] as List)) {
        final cat = Categoria.fromJson(row as Map<String, dynamic>);
        await DbService.instance.upsertCategoria(cat);
      }
    }

    // Products
    final prodResponse = await ApiService.instance.post(
      "Exec SPListarProductos @Token='$token', @SoloActivos=1",
    );
    if (prodResponse.isNotEmpty) {
      for (final row in (prodResponse[0] as List)) {
        final prod = Producto.fromJson(row as Map<String, dynamic>);
        await DbService.instance.upsertProducto(prod);
      }
    }
  }

  /// Uploads pending ventas and then refreshes the local catalog.
  /// Errors in either step are swallowed so callers never crash.
  Future<void> sincronizarTodo() async {
    try {
      await sincronizarVentas();
    } catch (e) {
      debugPrint('SyncService.sincronizarVentas failed: $e');
    }
    try {
      await descargarCatalogo();
    } catch (e) {
      debugPrint('SyncService.descargarCatalogo failed: $e');
    }
  }
}
