import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/producto.dart';
import '../providers/productos_provider.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirFormulario([Producto? producto]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kColorSuperficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ProductosProvider>(),
        child: _FormularioProducto(producto: producto),
      ),
    );
  }

  Future<void> _eliminarProducto(Producto p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kColorSuperficie,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Eliminar producto',
            style: TextStyle(color: kColorTexto)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: kColorTextoSecundario, fontSize: 14),
            children: [
              const TextSpan(text: '¿Eliminás '),
              TextSpan(
                text: '"${p.nombre}"',
                style: const TextStyle(
                    color: kColorTexto, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Esta acción no se puede deshacer.'),
            ],
          ),
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
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<ProductosProvider>().eliminarProducto(p.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${p.nombre}" eliminado'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final clean = hex.startsWith('#') ? hex.substring(1) : hex;
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorFondo,
      appBar: AppBar(
        backgroundColor: kColorSuperficie,
        title: const Text('Productos'),
        actions: [
          Consumer<ProductosProvider>(
            builder: (_, prov, __) => prov.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(kColorPrimario),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Recargar',
                    onPressed: () =>
                        context.read<ProductosProvider>().cargar(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: kColorPrimario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: kColorSuperficie,
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: kColorTexto, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search,
                    color: kColorTextoSecundario, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: kColorTextoSecundario, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          // List
          Expanded(
            child: Consumer<ProductosProvider>(
              builder: (_, prov, __) {
                if (prov.isLoading && prov.productosFiltrados.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(kColorPrimario),
                    ),
                  );
                }

                // Local name/code filter on top of provider filter
                final filtered = prov.productosFiltrados.where((p) {
                  if (_query.isEmpty) return true;
                  final q = _query.toLowerCase();
                  return p.nombre.toLowerCase().contains(q) ||
                      (p.codigo?.toLowerCase().contains(q) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 60, color: kColorTextoSecundario),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'Sin resultados para "$_query"'
                              : 'No hay productos cargados',
                          style: const TextStyle(
                              color: kColorTextoSecundario),
                        ),
                        const SizedBox(height: 20),
                        if (_query.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _abrirFormulario(),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar primer producto'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (ctx, i) {
                    final p = filtered[i];
                    final avatarColor =
                        _parseColor(p.color) ?? kColorCard;
                    return ListTile(
                      tileColor: kColorSuperficie,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: avatarColor,
                        child: Text(
                          p.nombre.isNotEmpty
                              ? p.nombre[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.nombre,
                              style: TextStyle(
                                color: p.activo
                                    ? kColorTexto
                                    : kColorTextoSecundario,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _ivaBadge(p.iva),
                          if (!p.activo) ...[
                            const SizedBox(width: 4),
                            _statusBadge('INACT.', Colors.red.shade300),
                          ],
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            formatGs(p.precio),
                            style: const TextStyle(
                              color: kColorPrimario,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (p.codigo != null && p.codigo!.isNotEmpty) ...[
                            const Text(
                              ' · ',
                              style: TextStyle(
                                  color: kColorTextoSecundario,
                                  fontSize: 12),
                            ),
                            Text(
                              p.codigo!,
                              style: const TextStyle(
                                color: kColorTextoSecundario,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (p.precioVariable) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.edit,
                                size: 12, color: kColorAcento),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 19, color: kColorTextoSecundario),
                            tooltip: 'Editar',
                            onPressed: () => _abrirFormulario(p),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 19, color: Colors.red.shade300),
                            tooltip: 'Eliminar',
                            onPressed: () => _eliminarProducto(p),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ivaBadge(int iva) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'IVA $iva%',
        style: const TextStyle(
          color: kColorTextoSecundario,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// =============================================================================
// Formulario de producto (bottom sheet)
// =============================================================================

class _FormularioProducto extends StatefulWidget {
  final Producto? producto;

  const _FormularioProducto({this.producto});

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();

  int _iva = 10;
  int? _idCategoria;
  bool _activo = true;
  bool _precioVariable = false;
  bool _loading = false;

  bool get _isEdit => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _nombreCtrl.text = p.nombre;
      _precioCtrl.text =
          p.precio > 0 ? p.precio.toStringAsFixed(0) : '';
      _costoCtrl.text = p.costo > 0 ? p.costo.toStringAsFixed(0) : '';
      _codigoCtrl.text = p.codigo ?? '';
      _iva = p.iva;
      _idCategoria = p.idCategoria;
      _activo = p.activo;
      _precioVariable = p.precioVariable;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _costoCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del producto es requerido')),
      );
      return;
    }

    final precio =
        double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final costo =
        double.tryParse(_costoCtrl.text.replaceAll(',', '.')) ?? 0.0;

    setState(() => _loading = true);

    try {
      final datos = <String, dynamic>{
        if (_isEdit) 'id': widget.producto!.id,
        'nombre': nombre,
        'precio': precio,
        'costo': costo,
        'codigo': _codigoCtrl.text.trim(),
        'iva': _iva,
        'idCategoria': _idCategoria,
        'activo': _activo,
        'precioVariable': _precioVariable,
      };

      await context.read<ProductosProvider>().guardarProducto(datos);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Producto actualizado correctamente'
                  : 'Producto agregado correctamente',
            ),
            backgroundColor: kColorPrimario,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<ProductosProvider>().categorias;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Editar Producto' : 'Nuevo Producto',
                    style: const TextStyle(
                      color: kColorTexto,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: kColorTextoSecundario),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nombre
                    TextField(
                      controller: _nombreCtrl,
                      style: const TextStyle(color: kColorTexto),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                      ),
                      autofocus: !_isEdit,
                    ),
                    const SizedBox(height: 12),
                    // Precio y Costo
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _precioCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: kColorTexto),
                            decoration: const InputDecoration(
                              labelText: 'Precio venta (₲)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _costoCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: kColorTexto),
                            decoration: const InputDecoration(
                              labelText: 'Costo (₲)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Código de barras
                    TextField(
                      controller: _codigoCtrl,
                      style: const TextStyle(color: kColorTexto),
                      decoration: const InputDecoration(
                        labelText: 'Código de barras',
                        prefixIcon: Icon(Icons.qr_code,
                            color: kColorTextoSecundario, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // IVA
                    DropdownButtonFormField<int>(
                      value: _iva,
                      dropdownColor: kColorCard,
                      style: const TextStyle(color: kColorTexto),
                      decoration: const InputDecoration(
                        labelText: 'IVA',
                        prefixIcon: Icon(Icons.receipt_outlined,
                            color: kColorTextoSecundario, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Exento (0%)'),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text('Gravado 5%'),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text('Gravado 10%'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _iva = v ?? 10),
                    ),
                    const SizedBox(height: 12),
                    // Categoría
                    DropdownButtonFormField<int?>(
                      value: _idCategoria,
                      dropdownColor: kColorCard,
                      style: const TextStyle(color: kColorTexto),
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category_outlined,
                            color: kColorTextoSecundario, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'Sin categoría',
                            style:
                                TextStyle(color: kColorTextoSecundario),
                          ),
                        ),
                        ...categorias.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _idCategoria = v),
                    ),
                    const SizedBox(height: 14),
                    // Switches
                    Container(
                      decoration: BoxDecoration(
                        color: kColorCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _activo,
                            onChanged: (v) =>
                                setState(() => _activo = v),
                            title: const Text(
                              'Producto activo',
                              style: TextStyle(
                                  color: kColorTexto, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Visible en el punto de venta',
                              style: TextStyle(
                                  color: kColorTextoSecundario,
                                  fontSize: 11),
                            ),
                            activeColor: kColorPrimario,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          const Divider(
                              height: 1, color: Colors.white12),
                          SwitchListTile(
                            value: _precioVariable,
                            onChanged: (v) =>
                                setState(() => _precioVariable = v),
                            title: const Text(
                              'Precio variable',
                              style: TextStyle(
                                  color: kColorTexto, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Permite modificar el precio al agregar al carrito',
                              style: TextStyle(
                                  color: kColorTextoSecundario,
                                  fontSize: 11),
                            ),
                            activeColor: kColorAcento,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Guardar button
                    ElevatedButton(
                      onPressed: _loading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kColorPrimario,
                        disabledBackgroundColor:
                            kColorPrimario.withOpacity(0.3),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isEdit
                                  ? 'GUARDAR CAMBIOS'
                                  : 'AGREGAR PRODUCTO',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
