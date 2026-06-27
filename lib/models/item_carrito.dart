import 'producto.dart';

class ItemCarrito {
  final Producto producto;
  final int cantidad;
  final double precioUnitario;

  const ItemCarrito({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get totalItem => cantidad * precioUnitario;

  ItemCarrito copyWith({
    Producto? producto,
    int? cantidad,
    double? precioUnitario,
  }) {
    return ItemCarrito(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': producto.id,
      'nombre': producto.nombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total_item': totalItem,
      'iva': producto.iva,
    };
  }
}
