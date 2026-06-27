import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/venta.dart';
import '../providers/turno_provider.dart';
import '../services/db_service.dart';
import '../widgets/numpad_widget.dart';

class TurnoScreen extends StatefulWidget {
  final bool hayTurnoActivo;

  const TurnoScreen({super.key, required this.hayTurnoActivo});

  @override
  State<TurnoScreen> createState() => _TurnoScreenState();
}

class _TurnoScreenState extends State<TurnoScreen> {
  final _efectivoCtrl = TextEditingController();
  final _contadoCtrl = TextEditingController();
  bool _loading = false;
  bool _cargandoVentas = false;
  List<Venta> _ventas = [];
  double _totalVentas = 0;

  @override
  void initState() {
    super.initState();
    if (widget.hayTurnoActivo) _cargarVentas();
  }

  @override
  void dispose() {
    _efectivoCtrl.dispose();
    _contadoCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> _cargarVentas() async {
    setState(() => _cargandoVentas = true);
    try {
      final turno = context.read<TurnoProvider>().turnoActivo;
      if (turno?.id != null) {
        final ventas = await DbService.instance.getVentasTurno(turno!.id!);
        final total = ventas.fold<double>(0.0, (acc, v) => acc + v.total);
        if (mounted) {
          setState(() {
            _ventas = ventas;
            _totalVentas = total;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _cargandoVentas = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Numpad for efectivo initial
  // ---------------------------------------------------------------------------

  void _onNumpadKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_efectivoCtrl.text.isNotEmpty) {
          _efectivoCtrl.text =
              _efectivoCtrl.text.substring(0, _efectivoCtrl.text.length - 1);
        }
      } else if (key == 'C') {
        _efectivoCtrl.clear();
      } else {
        _efectivoCtrl.text += key;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _abrirTurno() async {
    final efectivo = double.tryParse(
            _efectivoCtrl.text.replaceAll('.', '').replaceAll(',', '')) ??
        0.0;

    setState(() => _loading = true);
    try {
      final ok =
          await context.read<TurnoProvider>().abrirTurno(efectivo);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir el turno'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cerrarTurno() async {
    final totalContado = double.tryParse(
            _contadoCtrl.text.replaceAll('.', '').replaceAll(',', '')) ??
        0.0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kColorSuperficie,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cerrar turno',
            style: TextStyle(color: kColorTexto)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Confirmás el cierre del turno?',
              style: TextStyle(color: kColorTextoSecundario),
            ),
            const SizedBox(height: 16),
            _resumenRow('Ventas en turno', '${_ventas.length}'),
            const SizedBox(height: 6),
            _resumenRow('Total recaudado', formatGs(_totalVentas)),
            const Divider(color: Colors.white24, height: 20),
            _resumenRow('Efectivo contado', formatGs(totalContado)),
            const SizedBox(height: 6),
            _resumenRow(
              'Diferencia',
              formatGs(totalContado - _totalVentas),
              valueColor: (totalContado - _totalVentas) < 0
                  ? Colors.red.shade300
                  : kColorPrimario,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            child: const Text('CERRAR TURNO'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final ok =
          await context.read<TurnoProvider>().cerrarTurno(totalContado);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar el turno'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: Text(widget.hayTurnoActivo ? 'Turno Activo' : 'Abrir Turno'),
        actions: widget.hayTurnoActivo
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                  onPressed: _cargandoVentas ? null : _cargarVentas,
                ),
              ]
            : null,
      ),
      body: widget.hayTurnoActivo
          ? _buildTurnoActivo()
          : _buildAbrirTurno(),
    );
  }

  // ---------------------------------------------------------------------------
  // Abrir turno view
  // ---------------------------------------------------------------------------

  Widget _buildAbrirTurno() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kColorSuperficie,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: kColorPrimario, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Nuevo Turno',
                      style: TextStyle(
                        color: kColorTexto,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ingresá el efectivo inicial en caja para comenzar.',
                  style: TextStyle(
                      color: kColorTextoSecundario, fontSize: 12),
                ),
                const SizedBox(height: 20),
                // Amount display
                const Text(
                  'EFECTIVO INICIAL',
                  style: TextStyle(
                    color: kColorTextoSecundario,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: kColorCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _efectivoCtrl.text.isNotEmpty
                          ? kColorPrimario.withOpacity(0.5)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    _efectivoCtrl.text.isEmpty
                        ? '₲ 0'
                        : '₲ ${_efectivoCtrl.text}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _efectivoCtrl.text.isNotEmpty
                          ? kColorPrimario
                          : kColorTextoSecundario,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(height: 14),
                NumpadWidget(
                  onKey: _onNumpadKey,
                  showDecimal: false,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _abrirTurno,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kColorPrimario,
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                            'ABRIR TURNO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Turno activo view
  // ---------------------------------------------------------------------------

  Widget _buildTurnoActivo() {
    final turno = context.read<TurnoProvider>().turnoActivo;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Turno info card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: kColorPrimario, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Turno en Curso',
                    style: TextStyle(
                      color: kColorTexto,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  _badge('ABIERTO', kColorPrimario),
                ],
              ),
              const Divider(color: Colors.white12, height: 18),
              _infoRow('Terminal', turno?.terminal ?? '—'),
              const SizedBox(height: 6),
              _infoRow('Apertura', _formatFecha(turno?.fechaApertura ?? '')),
              const SizedBox(height: 6),
              _infoRow(
                  'Efectivo inicial', formatGs(turno?.efectivoInicial ?? 0)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Totales card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RESUMEN DEL TURNO',
                style: TextStyle(
                  color: kColorTextoSecundario,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _statBlock(
                      label: 'Ventas',
                      value: '${_ventas.length}',
                    ),
                  ),
                  const VerticalDivider(color: Colors.white12, width: 20),
                  Expanded(
                    child: _statBlock(
                      label: 'Recaudado',
                      value: formatGs(_totalVentas),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ventas list
        if (_cargandoVentas)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kColorPrimario),
              ),
            ),
          )
        else if (_ventas.isEmpty)
          _card(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay ventas en este turno',
                  style: TextStyle(color: kColorTextoSecundario),
                ),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'VENTAS DEL TURNO (${_ventas.length})',
              style: const TextStyle(
                color: kColorTextoSecundario,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          ..._ventas.map(
            (v) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: kColorSuperficie,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: kColorCard,
                  child: Icon(
                    _iconMetodoPago(v.metodoPago),
                    color: kColorPrimario,
                    size: 16,
                  ),
                ),
                title: Text(
                  formatGs(v.total),
                  style: const TextStyle(
                    color: kColorTexto,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _formatFecha(v.fecha),
                  style: const TextStyle(
                      color: kColorTextoSecundario, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _badge(v.metodoPago, kColorTextoSecundario),
                    if (!v.sincronizado) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.cloud_off,
                          size: 14, color: kColorAcento),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Cierre section
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CIERRE DE TURNO',
                style: TextStyle(
                  color: kColorTextoSecundario,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _contadoCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: kColorTexto),
                decoration: const InputDecoration(
                  labelText: 'Efectivo contado en caja (₲)',
                  prefixIcon: Icon(Icons.attach_money,
                      color: kColorTextoSecundario, size: 20),
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _cerrarTurno,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    disabledBackgroundColor:
                        Colors.red.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.lock_outline, size: 18),
                  label: Text(
                    _loading ? 'Cerrando...' : 'CERRAR TURNO',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorSuperficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: kColorTextoSecundario, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: kColorTexto,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _resumenRow(String label, String value,
      {Color valueColor = kColorTexto}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: kColorTextoSecundario, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statBlock({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: kColorPrimario,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              color: kColorTextoSecundario, fontSize: 11),
        ),
      ],
    );
  }

  IconData _iconMetodoPago(String metodo) {
    switch (metodo) {
      case 'TARJETA':
        return Icons.credit_card;
      case 'TRANSFERENCIA':
        return Icons.account_balance;
      default:
        return Icons.attach_money;
    }
  }

  String _formatFecha(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year} $h:$mi';
    } catch (_) {
      return isoDate;
    }
  }
}
