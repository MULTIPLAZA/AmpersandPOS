import 'package:flutter/foundation.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';

class ProductosProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  int? _selectedCategoriaId;
  bool _isLoading = false;

  /// Last product found via barcode search.
  Producto? _productoEncontrado;

  List<Producto> get productos => List.unmodifiable(_productos);
  List<Categoria> get categorias => List.unmodifiable(_categorias);
  int? get selectedCategoriaId => _selectedCategoriaId;
  bool get isLoading => _isLoading;
  Producto? get productoEncontrado => _productoEncontrado;

  /// Products filtered by the currently selected category.
  /// Returns all products when [_selectedCategoriaId] is null.
  List<Producto> get productosFiltrados {
    if (_selectedCategoriaId == null) return List.unmodifiable(_productos);
    return _productos
        .where((p) => p.idCategoria == _selectedCategoriaId)
        .toList();
  }

  /// Offline-first load: reads from local DB first, then tries to sync with
  /// the server and reloads. Sync errors are swallowed so the UI always shows
  /// locally cached data.
  Future<void> cargar() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Step 1 – show cached data immediately.
      _productos = await DbService.instance.getProductos();
      _categorias = await DbService.instance.getCategorias();
      notifyListeners();

      // Step 2 – refresh from server (silently ignore connectivity errors).
      try {
        await SyncService.instance.descargarCatalogo();
        _productos = await DbService.instance.getProductos();
        _categorias = await DbService.instance.getCategorias();
      } catch (_) {
        // Network unavailable – continue with already-loaded local data.
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Looks up a product by barcode [codigo] via the server.
  /// Returns the matching [Producto] or null if not found / on error.
  Future<Producto?> buscarPorCodigo(String codigo) async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return null;

      final rows = await ApiService.instance.post(
        "Exec SPBuscarProductoCodigo @Token='$token', @Codigo='$codigo'",
      );
      if (rows.isEmpty || (rows[0] as List).isEmpty) return null;

      _productoEncontrado =
          Producto.fromJson((rows[0] as List).first as Map<String, dynamic>);
      notifyListeners();
      return _productoEncontrado;
    } catch (_) {
      return null;
    }
  }

  /// Selects a category filter. Pass null to show all products.
  void selectCategoria(int? id) {
    _selectedCategoriaId = id;
    notifyListeners();
  }

  /// Upserts a product via [SPGuardarProducto] and reloads the catalogue.
  ///
  /// Expected keys in [datos]:
  ///   id (int, 0 for new), nombre, precio, costo, iva,
  ///   idCategoria (int?), codigo, color, activo (bool), precioVariable (bool)
  Future<void> guardarProducto(Map<String, dynamic> datos) async {
    final token = await AuthService.instance.getToken();
    if (token == null) return;

    final int id = (datos['id'] as int?) ?? 0;
    final String nombre = (datos['nombre'] as String?) ?? '';
    final num precio = (datos['precio'] as num?) ?? 0;
    final num costo = (datos['costo'] as num?) ?? 0;
    final int iva = (datos['iva'] as int?) ?? 0;
    final int? idCategoria = datos['idCategoria'] as int?;
    final String codigo = (datos['codigo'] as String?) ?? '';
    final String color = (datos['color'] as String?) ?? '';
    final int activo = ((datos['activo'] as bool?) ?? true) ? 1 : 0;
    final int precioVariable =
        ((datos['precioVariable'] as bool?) ?? false) ? 1 : 0;

    final String catSegment =
        idCategoria != null ? "@IDCategoria=$idCategoria, " : '';

    await ApiService.instance.post(
      "Exec SPGuardarProducto @Token='$token', @IDProducto=$id, "
      "@Nombre='$nombre', @Precio=$precio, @Costo=$costo, @IVA=$iva, "
      "$catSegment@Codigo='$codigo', @Color='$color', "
      "@Activo=$activo, @PrecioVariable=$precioVariable",
    );
    await cargar();
  }

  /// Deletes a product by [id] via [SPEliminarProducto] and reloads.
  Future<void> eliminarProducto(int id) async {
    final token = await AuthService.instance.getToken();
    if (token == null) return;

    await ApiService.instance.post(
      "Exec SPEliminarProducto @Token='$token', @IDProducto=$id",
    );
    await cargar();
  }
}
