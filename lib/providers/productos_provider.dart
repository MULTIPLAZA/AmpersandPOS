import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class ProductosProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  int? _selectedCategoriaId;
  bool _isLoading = false;

  List<Producto> get productos => List.unmodifiable(_productos);
  List<Categoria> get categorias => List.unmodifiable(_categorias);
  int? get selectedCategoriaId => _selectedCategoriaId;
  bool get isLoading => _isLoading;

  List<Producto> get productosFiltrados {
    if (_selectedCategoriaId == null) return List.unmodifiable(_productos);
    return _productos.where((p) => p.idCategoria == _selectedCategoriaId).toList();
  }

  /// Offline-first: muestra cache local inmediatamente, luego sincroniza con Supabase.
  Future<void> cargar() async {
    _isLoading = true;
    notifyListeners();

    // 1. Mostrar cache local primero
    _productos = await DbService.instance.getProductos();
    _categorias = await DbService.instance.getCategorias();
    notifyListeners();

    // 2. Intentar actualizar desde Supabase
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) return;

      final prodRes = await supabase
          .from('productos')
          .select('*, categorias(nombre, color)')
          .eq('id_licencia', userId)
          .eq('activo', true)
          .order('nombre');

      final catRes = await supabase
          .from('categorias')
          .select()
          .eq('id_licencia', userId)
          .eq('activo', true)
          .order('nombre');

      final prods = prodRes.map<Producto>((p) => Producto.fromSupabase(p)).toList();
      final cats = catRes.map<Categoria>((c) => Categoria.fromSupabase(c)).toList();

      // Guardar en SQLite como cache offline
      for (final p in prods) await DbService.instance.upsertProducto(p);
      for (final c in cats) await DbService.instance.upsertCategoria(c);

      _productos = prods;
      _categorias = cats;
    } catch (_) {
      // Sin internet — queda con la cache local
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Producto? buscarPorCodigoLocal(String codigo) {
    final q = codigo.toLowerCase().trim();
    try {
      return _productos.firstWhere((p) =>
          (p.codigo?.toLowerCase() == q) ||
          (p.codigosExtra?.toLowerCase().contains(q) ?? false));
    } catch (_) {
      return null;
    }
  }

  void selectCategoria(int? id) {
    _selectedCategoriaId = id;
    notifyListeners();
  }

  Future<void> guardarProducto(Map<String, dynamic> datos) async {
    final userId = AuthService.instance.userId;
    if (userId == null) return;

    final int id = (datos['id'] as int?) ?? 0;

    if (id == 0) {
      await supabase.from('productos').insert({
        'id_licencia': userId,
        'nombre': datos['nombre'],
        'precio': datos['precio'] ?? 0,
        'costo': datos['costo'] ?? 0,
        'iva': datos['iva'] ?? '10',
        'id_categoria': datos['idCategoria'],
        'codigo': datos['codigo'],
        'color': datos['color'],
        'activo': true,
        'precio_variable': datos['precioVariable'] ?? false,
      });
    } else {
      await supabase.from('productos').update({
        'nombre': datos['nombre'],
        'precio': datos['precio'] ?? 0,
        'costo': datos['costo'] ?? 0,
        'iva': datos['iva'] ?? '10',
        'id_categoria': datos['idCategoria'],
        'codigo': datos['codigo'],
        'color': datos['color'],
        'activo': datos['activo'] ?? true,
        'precio_variable': datos['precioVariable'] ?? false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_licencia', userId).eq('id_producto', id);
    }
    await cargar();
  }

  Future<void> eliminarProducto(int id) async {
    final userId = AuthService.instance.userId;
    if (userId == null) return;
    await supabase.from('productos')
        .update({'activo': false})
        .eq('id_licencia', userId)
        .eq('id_producto', id);
    await cargar();
  }
}
