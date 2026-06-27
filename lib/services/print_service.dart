import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/item_carrito.dart';

class PrintService {
  static final PrintService instance = PrintService._();
  PrintService._();

  /// Builds an ESC/POS receipt and sends it to the first available BLE printer.
  /// Silently returns on any error — printing is non-critical.
  Future<void> imprimirRecibo({
    required String empresa,
    required String fecha,
    required List<ItemCarrito> items,
    required double total,
    required String metodoPago,
    double? recibido,
    double? vuelto,
  }) async {
    try {
      final bytes = _buildRecibo(
        empresa: empresa,
        fecha: fecha,
        items: items,
        total: total,
        metodoPago: metodoPago,
        recibido: recibido,
        vuelto: vuelto,
      );

      final device = await _findDevice();
      if (device == null) {
        debugPrint('PrintService: no BLE printer found');
        return;
      }

      await _writeToDevice(device, bytes);
    } catch (e) {
      debugPrint('PrintService error: $e');
    }
  }

  // ── ESC/POS builder ─────────────────────────────────────────────────────────

  List<int> _buildRecibo({
    required String empresa,
    required String fecha,
    required List<ItemCarrito> items,
    required double total,
    required String metodoPago,
    double? recibido,
    double? vuelto,
  }) {
    final buf = <int>[];

    void add(List<int> b) => buf.addAll(b);
    void text(String s) => buf.addAll(utf8.encode(s));
    void lf() => buf.add(0x0A);

    // Init printer
    add([0x1B, 0x40]);

    // ── Header (centered) ───────────────────────────────────────────────────
    add([0x1B, 0x61, 0x01]); // center
    add([0x1B, 0x45, 0x01]); // bold on
    text(empresa);
    lf();
    add([0x1B, 0x45, 0x00]); // bold off
    text(fecha);
    lf();
    text('--------------------------------');
    lf();

    // ── Items (left aligned) ────────────────────────────────────────────────
    add([0x1B, 0x61, 0x00]); // left

    for (final item in items) {
      // Truncate long names to keep lines tidy on 32-column paper
      final nombre = item.producto.nombre.length > 16
          ? item.producto.nombre.substring(0, 16)
          : item.producto.nombre.padRight(16);
      final detalle =
          '${item.cantidad} x ${_gs(item.precioUnitario)} = ${_gs(item.totalItem)}';
      text('$nombre $detalle');
      lf();
    }

    text('--------------------------------');
    lf();

    // ── Totals (centered) ───────────────────────────────────────────────────
    add([0x1B, 0x61, 0x01]); // center
    add([0x1B, 0x45, 0x01]); // bold on
    text('TOTAL: ₲ ${_gs(total)}'); // ₲ = U+20B2
    lf();
    add([0x1B, 0x45, 0x00]); // bold off

    text('Método: $metodoPago');
    lf();

    if (recibido != null) {
      text('Recibido: ₲ ${_gs(recibido)}');
      lf();
    }
    if (vuelto != null) {
      text('Vuelto: ₲ ${_gs(vuelto)}');
      lf();
    }

    // Feed and partial cut
    add([0x0A, 0x0A, 0x0A, 0x1D, 0x56, 0x41, 0x03]);

    return buf;
  }

  /// Formats a double as Guaraní integer with period thousands separator.
  /// e.g.  5500000.0  →  "5.500.000"
  String _gs(double amount) {
    final str = amount.round().toString();
    final reversed = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) reversed.write('.');
      reversed.write(str[i]);
      count++;
    }
    return reversed.toString().split('').reversed.join();
  }

  // ── BLE helpers ─────────────────────────────────────────────────────────────

  /// Returns a usable BluetoothDevice: checks already-connected first,
  /// then does a 2-second scan.
  Future<BluetoothDevice?> _findDevice() async {
    final connected = FlutterBluePlus.connectedDevices;
    if (connected.isNotEmpty) return connected.first;

    // Scan and collect the first result found
    BluetoothDevice? found;
    final sub = FlutterBluePlus.scanResults.listen((results) {
      if (found == null && results.isNotEmpty) {
        found = results.first.device;
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 2, milliseconds: 300));
    } finally {
      await sub.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }

    return found;
  }

  /// Connects (if needed), writes [bytes] in 20-byte chunks, then disconnects.
  Future<void> _writeToDevice(BluetoothDevice device, List<int> bytes) async {
    final alreadyConnected = FlutterBluePlus.connectedDevices.contains(device);

    if (!alreadyConnected) {
      await device.connect(timeout: const Duration(seconds: 4));
    }

    try {
      final services = await device.discoverServices();

      BluetoothCharacteristic? writable;
      outer:
      for (final svc in services) {
        for (final char in svc.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            writable = char;
            break outer;
          }
        }
      }

      if (writable == null) {
        debugPrint('PrintService: no writable characteristic found');
        return;
      }

      final withoutResponse = writable.properties.writeWithoutResponse &&
          !writable.properties.write;

      // Write in 20-byte chunks (classic BLE MTU minimum)
      const chunkSize = 20;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, bytes.length);
        await writable.write(
          bytes.sublist(i, end),
          withoutResponse: withoutResponse,
        );
      }
    } finally {
      if (!alreadyConnected) {
        try {
          await device.disconnect();
        } catch (_) {}
      }
    }
  }
}
