import 'package:flutter/foundation.dart';
import '../models/item_carrito.dart';
import '../models/producto.dart';

class CarritoProvider extends ChangeNotifier {
  final List<ItemCarrito> _items = [];

  /// Unmodifiable view of the current cart items.
  List<ItemCarrito> get items => List.unmodifiable(_items);

  /// Sum of all item totals.
  double get total =>
      _items.fold(0.0, (sum, item) => sum + item.totalItem);

  /// Total number of individual units across all cart lines.
  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.cantidad);

  /// Adds [p] to the cart.
  /// If the product is already present its quantity is incremented by one.
  void agregar(Producto p) {
    final idx = _items.indexWhere((item) => item.producto.id == p.id);
    if (idx >= 0) {
      _items[idx] =
          _items[idx].copyWith(cantidad: _items[idx].cantidad + 1);
    } else {
      _items.add(
        ItemCarrito(
          producto: p,
          cantidad: 1,
          precioUnitario: p.precio,
        ),
      );
    }
    notifyListeners();
  }

  /// Removes the cart line at [index] entirely.
  void quitar(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  /// Increments the quantity of the cart line at [index] by one.
  void incrementar(int index) {
    _items[index] =
        _items[index].copyWith(cantidad: _items[index].cantidad + 1);
    notifyListeners();
  }

  /// Decrements the quantity of the cart line at [index] by one.
  /// If quantity would reach zero the line is removed instead.
  void decrementar(int index) {
    if (_items[index].cantidad > 1) {
      _items[index] =
          _items[index].copyWith(cantidad: _items[index].cantidad - 1);
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  /// Empties the cart.
  void limpiar() {
    _items.clear();
    notifyListeners();
  }
}
