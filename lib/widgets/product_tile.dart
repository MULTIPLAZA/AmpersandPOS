import 'package:flutter/material.dart';
import '../config.dart';
import '../models/producto.dart';

/// Grid tile that displays a single product card.
///
/// Shows a colored accent border at the top (derived from [producto.color]),
/// the product name (2-line max), price in green, and a compact IVA badge.
/// Tapping triggers [onTap] with a ripple splash effect.
class ProductTile extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.producto,
    required this.onTap,
  });

  /// Parses a CSS-style hex color string (e.g. "#4caf50") into a [Color].
  /// Falls back to [kColorPrimario] on any parsing error.
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return kColorPrimario;
    try {
      final clean = hex.replaceFirst('#', '');
      // Prepend FF alpha channel when only RGB digits are present.
      final padded = clean.length == 6 ? 'ff$clean' : clean;
      return Color(int.parse(padded, radix: 16));
    } catch (_) {
      return kColorPrimario;
    }
  }

  String _ivaBadgeLabel() {
    if (producto.iva == 0) return 'Exento';
    return 'IVA ${producto.iva}%';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(producto.color);

    return Card(
      color: kColorCard,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withOpacity(0.30),
        highlightColor: accentColor.withOpacity(0.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored top accent bar.
            Container(height: 4, color: accentColor),

            // Content area.
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Product name – 2 lines max with ellipsis overflow.
                    Text(
                      producto.nombre,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kColorTexto,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price in large bold green text.
                    Text(
                      formatGs(producto.precio),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kColorPrimario,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // IVA badge.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kColorSuperficie,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _ivaBadgeLabel(),
                        style: const TextStyle(
                          color: kColorTextoSecundario,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
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
