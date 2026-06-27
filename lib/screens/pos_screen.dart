import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/producto.dart';
import '../providers/auth_provider.dart';
import '../providers/carrito_provider.dart';
import '../providers/productos_provider.dart';
import '../providers/turno_provider.dart';
import '../widgets/category_bar.dart';
import '../widgets/cart_item.dart';
import '../widgets/product_tile.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import 'productos_screen.dart';
import 'turno_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  int _tabIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TurnoProvider>().cargarTurnoActivo();
      context.read<ProductosProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _onBuscarProducto(String valor) async {
    final query = valor.trim();
    if (query.isEmpty) return;

    final prov = context.read<ProductosProvider>();
    final carrito = context.read<CarritoProvider>();

    // Numeric input → try barcode lookup first (local cache)
    if (RegExp(r'^\d+$').hasMatch(query)) {
      final prod = prov.buscarPorCodigoLocal(query);
      if (prod != null) {
        carrito.agregar(prod);
        _searchCtrl.clear();
        setState(() => _searchQuery = '');
        if (mounted) _showAgregarSnack(prod);
        return;
      }
    }

    // Fall back to local name filter
    setState(() => _searchQuery = query);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchQuery = '');
  }

  void _showAgregarSnack(Producto p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agregado: ${p.nombre}'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: kColorPrimario,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _abrirTurnoScreen() async {
    final turno = context.read<TurnoProvider>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TurnoScreen(hayTurnoActivo: turno.hayTurnoActivo),
      ),
    );
    if (result == true && mounted) {
      context.read<TurnoProvider>().cargarTurnoActivo();
    }
  }

  void _abrirCheckout() {
    final turno = context.read<TurnoProvider>();
    final carrito = context.read<CarritoProvider>();

    if (carrito.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
      return;
    }

    if (!turno.hayTurnoActivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debés abrir un turno primero'),
          backgroundColor: kColorAcento,
        ),
      );
      _abrirTurnoScreen();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          total: carrito.total,
          idTurno: turno.turnoActivo!.id!,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kColorSuperficie,
        title: const Text('Cerrar sesión',
            style: TextStyle(color: kColorTexto)),
        content: const Text('¿Seguro que querés cerrar sesión?',
            style: TextStyle(color: kColorTextoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('SALIR'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: kColorFondo,
      appBar: _buildAppBar(),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      bottomNavigationBar:
          isWide ? null : _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kColorSuperficie,
      titleSpacing: 16,
      title: Consumer<TurnoProvider>(
        builder: (_, turno, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AMPERSAND POS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kColorTexto,
                letterSpacing: 1,
              ),
            ),
            if (turno.hayTurnoActivo)
              Text(
                'Turno abierto — ${turno.turnoActivo?.terminal ?? ""}',
                style: const TextStyle(
                    fontSize: 10, color: kColorTextoSecundario),
              )
            else
              const Text(
                'Sin turno activo',
                style: TextStyle(fontSize: 10, color: kColorAcento),
              ),
          ],
        ),
      ),
      actions: [
        Consumer<TurnoProvider>(
          builder: (_, turno, __) => TextButton.icon(
            onPressed: _abrirTurnoScreen,
            icon: Icon(
              turno.hayTurnoActivo ? Icons.timer_outlined : Icons.timer_off_outlined,
              color: turno.hayTurnoActivo ? kColorPrimario : kColorAcento,
              size: 18,
            ),
            label: Text(
              turno.hayTurnoActivo ? 'Turno' : 'Abrir turno',
              style: TextStyle(
                color: turno.hayTurnoActivo ? kColorPrimario : kColorAcento,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.inventory_2_outlined, size: 20),
          tooltip: 'Gestión de productos',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductosScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, size: 20),
          tooltip: 'Cerrar sesión',
          onPressed: _logout,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Consumer<CarritoProvider>(
      builder: (_, carrito, __) => BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: kColorSuperficie,
        selectedItemColor: kColorPrimario,
        unselectedItemColor: kColorTextoSecundario,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.receipt_long_outlined),
                if (carrito.itemCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: kColorAcento,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          carrito.itemCount > 9
                              ? '9+'
                              : '${carrito.itemCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Ticket',
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 6, child: _buildProductosPanel()),
        const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
        Expanded(flex: 4, child: _buildCarritoPanel()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return IndexedStack(
      index: _tabIndex,
      children: [
        _buildProductosPanel(),
        _buildCarritoPanel(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Productos panel
  // ---------------------------------------------------------------------------

  Widget _buildProductosPanel() {
    return Column(
      children: [
        // Search / barcode bar
        Container(
          color: kColorSuperficie,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: kColorTexto, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar producto o escanear código...',
              prefixIcon: const Icon(Icons.search,
                  color: kColorTextoSecundario, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: kColorTextoSecundario, size: 18),
                      onPressed: _clearSearch,
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onSubmitted: _onBuscarProducto,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
          ),
        ),
        // Category bar
        Consumer<ProductosProvider>(
          builder: (_, prov, __) => CategoryBar(
            categorias: prov.categorias,
            selectedId: prov.selectedCategoriaId,
            onSelect: prov.selectCategoria,
          ),
        ),
        // Product grid
        Expanded(
          child: Consumer<ProductosProvider>(
            builder: (_, prov, __) {
              if (prov.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(kColorPrimario),
                  ),
                );
              }

              // Apply local name filter on top of category filter
              final productos = _searchQuery.isEmpty
                  ? prov.productosFiltrados
                  : prov.productosFiltrados
                      .where((p) => p.nombre
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

              if (productos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off,
                          size: 56, color: kColorTextoSecundario),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Sin resultados para "$_searchQuery"'
                            : 'Sin productos disponibles',
                        style: const TextStyle(color: kColorTextoSecundario),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _clearSearch,
                          child: const Text('Limpiar búsqueda'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 155,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.82,
                ),
                itemCount: productos.length,
                itemBuilder: (ctx, i) {
                  final p = productos[i];
                  return ProductTile(
                    producto: p,
                    onTap: () {
                      context.read<CarritoProvider>().agregar(p);
                      _showAgregarSnack(p);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Carrito panel
  // ---------------------------------------------------------------------------

  Widget _buildCarritoPanel() {
    return Consumer<CarritoProvider>(
      builder: (_, carrito, __) => Column(
        children: [
          // Header
          Container(
            color: kColorSuperficie,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: kColorPrimario, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'TICKET',
                  style: TextStyle(
                    color: kColorTexto,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (carrito.itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kColorAcento.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: kColorAcento.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${carrito.itemCount} ítem${carrito.itemCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: kColorAcento,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white12),

          // Items
          Expanded(
            child: carrito.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 56, color: kColorTextoSecundario),
                        SizedBox(height: 10),
                        Text(
                          'Carrito vacío',
                          style: TextStyle(
                              color: kColorTextoSecundario, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tocá un producto para agregarlo',
                          style: TextStyle(
                              color: kColorTextoSecundario, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: carrito.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (ctx, i) => CartItemWidget(
                      item: carrito.items[i],
                      onIncrement: () => carrito.incrementar(i),
                      onDecrement: () => carrito.decrementar(i),
                      onDelete: () => carrito.quitar(i),
                    ),
                  ),
          ),

          const Divider(height: 1, thickness: 1, color: Colors.white24),

          // Footer: total + buttons
          Container(
            color: kColorSuperficie,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: kColorTextoSecundario,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      formatGs(carrito.total),
                      style: const TextStyle(
                        color: kColorPrimario,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Limpiar
                    OutlinedButton(
                      onPressed: carrito.items.isEmpty
                          ? null
                          : () => _confirmarLimpiar(carrito),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade300,
                        side: BorderSide(color: Colors.red.shade800),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.delete_outline, size: 20),
                    ),
                    const SizedBox(width: 8),
                    // Cobrar
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: carrito.items.isEmpty ? null : _abrirCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kColorAcento,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              kColorAcento.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.payment, size: 20),
                        label: const Text(
                          'COBRAR',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarLimpiar(CarritoProvider carrito) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kColorSuperficie,
        title: const Text('Limpiar carrito',
            style: TextStyle(color: kColorTexto)),
        content: const Text(
          '¿Eliminás todos los ítems del ticket?',
          style: TextStyle(color: kColorTextoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              carrito.limpiar();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            child: const Text('LIMPIAR'),
          ),
        ],
      ),
    );
  }
}
