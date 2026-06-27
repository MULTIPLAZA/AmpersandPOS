import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/venta.dart';
import '../providers/carrito_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/print_service.dart';
import '../widgets/numpad_widget.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  final int idTurno;

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.idTurno,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _metodoPago = 'EFECTIVO';
  final _recibidoCtrl = TextEditingController();
  bool _loading = false;

  double get _recibido {
    final text = _recibidoCtrl.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(text) ?? 0;
  }

  double get _vuelto => _recibido - widget.total;

  @override
  void dispose() {
    _recibidoCtrl.dispose();
    super.dispose();
  }

  void _onNumpadKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_recibidoCtrl.text.isNotEmpty) {
          _recibidoCtrl.text =
              _recibidoCtrl.text.substring(0, _recibidoCtrl.text.length - 1);
        }
      } else if (key == 'C') {
        _recibidoCtrl.clear();
      } else {
        _recibidoCtrl.text += key;
      }
    });
  }

  Future<void> _confirmar() async {
    // Validate received amount for cash payments
    if (_metodoPago == 'EFECTIVO' && _recibido < widget.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto recibido es insuficiente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final carrito = context.read<CarritoProvider>();
      final itemsJson =
          jsonEncode(carrito.items.map((i) => i.toJson()).toList());
      final token = (await AuthService.instance.getToken()) ?? '';
      final terminal = (await AuthService.instance.getTerminal()) ?? '';
      final fecha = DateTime.now().toIso8601String();

      final venta = Venta(
        idTurno: widget.idTurno,
        total: widget.total,
        metodoPago: _metodoPago,
        itemsJson: itemsJson,
        estado: 'COMPLETADA',
        fecha: fecha,
        sincronizado: false,
      );

      // 1. Save locally first (always succeeds if DB is available)
      final localId = await DbService.instance.insertVenta(venta);

      // 2. Attempt immediate server sync
      bool synced = false;
      try {
        final escapedItems = itemsJson.replaceAll("'", "''");
        final sp = "EXEC SPGuardarVenta "
            "@Token='$token', "
            "@IDTurno=${widget.idTurno}, "
            "@Total=${widget.total.toStringAsFixed(0)}, "
            "@MetodoPago='$_metodoPago', "
            "@Items='$escapedItems', "
            "@Terminal='$terminal'";
        await ApiService.instance.post(sp);
        await DbService.instance.marcarVentaSincronizada(localId);
        synced = true;
      } catch (_) {
        // Will be picked up by background sync later
        synced = false;
      }

      // 3. Print receipt (non-fatal)
      try {
        await PrintService.instance.imprimirRecibo(
          empresa: 'AMPERSAND POS',
          fecha: fecha,
          items: carrito.items,
          total: widget.total,
          metodoPago: _metodoPago,
          recibido: _recibido,
          vuelto: _vuelto > 0 ? _vuelto : 0,
        );
      } catch (_) {
        // Printer not connected — skip silently
      }

      // 4. Clear cart
      carrito.limpiar();

      if (!mounted) return;

      // 5. Show success dialog
      final efectivo = _metodoPago == 'EFECTIVO';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: kColorSuperficie,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: kColorPrimario, size: 68),
              const SizedBox(height: 14),
              const Text(
                'Venta registrada',
                style: TextStyle(
                  color: kColorTexto,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatGs(widget.total),
                style: const TextStyle(
                  color: kColorPrimario,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (efectivo && _vuelto > 0) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                _dialogRow('Recibido', formatGs(_recibido),
                    valueColor: kColorTexto),
                const SizedBox(height: 4),
                _dialogRow('Vuelto', formatGs(_vuelto),
                    valueColor: kColorAcento, bold: true),
              ],
              if (!synced) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kColorAcento.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: kColorAcento.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 14, color: kColorAcento),
                      SizedBox(width: 6),
                      Text(
                        'Sin conexión — guardado localmente',
                        style: TextStyle(
                            color: kColorAcento, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorPrimario,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'NUEVA VENTA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar venta: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Row _dialogRow(String label, String value,
      {Color valueColor = kColorTexto, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: kColorTextoSecundario, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildTotal() {
    return Container(
      color: kColorSuperficie,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL A COBRAR',
                style: TextStyle(
                  color: kColorTextoSecundario,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            formatGs(widget.total),
            style: const TextStyle(
              color: kColorTexto,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoPago() {
    const metodos = ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA'];
    final icons = [
      Icons.attach_money,
      Icons.credit_card,
      Icons.account_balance,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MÉTODO DE PAGO',
            style: TextStyle(
              color: kColorTextoSecundario,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(metodos.length, (idx) {
              final m = metodos[idx];
              final selected = _metodoPago == m;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: idx == 0 ? 0 : 5,
                    right: idx == metodos.length - 1 ? 0 : 5,
                  ),
                  child: InkWell(
                    onTap: () => setState(() {
                      _metodoPago = m;
                      _recibidoCtrl.clear();
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? kColorPrimario.withOpacity(0.2)
                            : kColorCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? kColorPrimario
                              : Colors.white24,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[idx],
                            color: selected
                                ? kColorPrimario
                                : kColorTextoSecundario,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m,
                            style: TextStyle(
                              color: selected
                                  ? kColorPrimario
                                  : kColorTextoSecundario,
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoRecibido() {
    if (_metodoPago != 'EFECTIVO') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTO RECIBIDO',
            style: TextStyle(
              color: kColorTextoSecundario,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          // Amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kColorCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _recibido >= widget.total
                    ? kColorPrimario.withOpacity(0.5)
                    : Colors.white24,
              ),
            ),
            child: Text(
              _recibidoCtrl.text.isEmpty
                  ? '₲ 0'
                  : '₲ ${_recibidoCtrl.text}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _recibido >= widget.total
                    ? kColorPrimario
                    : kColorTexto,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 12),
          NumpadWidget(
            onKey: _onNumpadKey,
            showDecimal: false,
          ),
        ],
      ),
    );
  }

  Widget _buildVuelto() {
    if (_metodoPago != 'EFECTIVO') return const SizedBox.shrink();
    if (_recibido < widget.total) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kColorAcento.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kColorAcento.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'VUELTO',
            style: TextStyle(
              color: kColorTextoSecundario,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          Text(
            formatGs(_vuelto),
            style: const TextStyle(
              color: kColorAcento,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorFondo,
      appBar: AppBar(
        backgroundColor: kColorSuperficie,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('COBRAR'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTotal(),
            const Divider(height: 1, thickness: 1, color: Colors.white12),
            _buildMetodoPago(),
            _buildCampoRecibido(),
            _buildVuelto(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: kColorSuperficie,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kColorPrimario,
                  disabledBackgroundColor: kColorPrimario.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'CONFIRMAR VENTA',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kColorTextoSecundario,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('CANCELAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
