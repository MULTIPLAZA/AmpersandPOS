import 'package:flutter/material.dart';
import '../config.dart';
import '../models/item_carrito.dart';

/// A single row in the cart list.
///
/// Shows product name, quantity controls (−/+), unit price, total price and
/// a delete button, separated from the next item by a subtle divider.
class CartItemWidget extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kColorCard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product name – takes remaining space.
              Expanded(
                child: Text(
                  item.producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kColorTexto,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Quantity controls: [−] qty [+]
              _QtyControls(
                cantidad: item.cantidad,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
              const SizedBox(width: 10),

              // Unit price (grey, small).
              SizedBox(
                width: 80,
                child: Text(
                  formatGs(item.precioUnitario),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kColorTextoSecundario,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Line total (green, bold).
              SizedBox(
                width: 92,
                child: Text(
                  formatGs(item.totalItem),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kColorPrimario,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Delete button.
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _QtyControls extends StatelessWidget {
  final int cantidad;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QtyControls({
    required this.cantidad,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallButton(icon: Icons.remove, onTap: onDecrement),
        Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: kColorSuperficie,
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFF555555)),
            ),
          ),
          child: Text(
            '$cantidad',
            style: const TextStyle(
              color: kColorTexto,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _SmallButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFF444444)),
        child: Icon(icon, size: 16, color: kColorTexto),
      ),
    );
  }
}
