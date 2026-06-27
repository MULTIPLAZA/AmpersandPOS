import 'package:flutter/material.dart';
import '../config.dart';
import '../models/categoria.dart';

/// Horizontal scrollable row of category filter chips.
///
/// The first chip is always "Todos" (null selection). Selecting a chip calls
/// [onSelect] with the category id, or null for "all". The active chip is
/// filled with the category colour (or [kColorPrimario] when none is set);
/// inactive chips show an outlined style.
class CategoryBar extends StatelessWidget {
  final List<Categoria> categorias;
  final int? selectedId;
  final Function(int?) onSelect;

  const CategoryBar({
    super.key,
    required this.categorias,
    required this.selectedId,
    required this.onSelect,
  });

  /// Parses a CSS hex color string (e.g. "#4caf50") into a [Color].
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return kColorPrimario;
    try {
      final clean = hex.replaceFirst('#', '');
      final padded = clean.length == 6 ? 'ff$clean' : clean;
      return Color(int.parse(padded, radix: 16));
    } catch (_) {
      return kColorPrimario;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          // "Todos" chip – always first.
          _CategoryChip(
            label: 'Todos',
            isSelected: selectedId == null,
            chipColor: kColorPrimario,
            onTap: () => onSelect(null),
          ),
          ...categorias.map(
            (cat) => _CategoryChip(
              label: cat.nombre,
              isSelected: selectedId == cat.id,
              chipColor: _parseColor(cat.color),
              onTap: () => onSelect(cat.id),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal chip widget
// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color chipColor;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.chipColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : kColorCard,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : kColorTextoSecundario,
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
