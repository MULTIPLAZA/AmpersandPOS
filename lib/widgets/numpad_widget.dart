import 'package:flutter/material.dart';
import '../config.dart';

/// A numeric keypad widget.
///
/// Emits key values as strings via [onKey]:
///   '0'–'9'  → digit
///   '.'      → decimal point (only sent when [showDecimal] is true)
///   'C'      → clear all
///   '<'      → backspace
///
/// Layout (4 rows × 3 columns):
///   [7][8][9]
///   [4][5][6]
///   [1][2][3]
///   [C][0][<]  (when showDecimal=false)
///   [.][0][<]  + full-width [C] row below (when showDecimal=true)
class NumpadWidget extends StatelessWidget {
  /// Called with the string value of the key that was pressed.
  final Function(String) onKey;

  /// When true the bottom-left key becomes '.' and an extra [C] button
  /// is added below the grid as a full-width clear button.
  final bool showDecimal;

  const NumpadWidget({
    super.key,
    required this.onKey,
    this.showDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['7', '8', '9']),
        _buildRow(['4', '5', '6']),
        _buildRow(['1', '2', '3']),
        _buildRow(showDecimal ? ['.', '0', '<'] : ['C', '0', '<']),
        if (showDecimal)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _NumpadButton(
              label: 'C',
              onTap: () => onKey('C'),
              foregroundColor: Colors.redAccent,
            ),
          ),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: SizedBox(
            height: 56,
            child: _NumpadButton(
              label: key,
              onTap: () => onKey(key),
              foregroundColor: _keyColor(key),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _keyColor(String key) {
    switch (key) {
      case 'C':
        return Colors.redAccent;
      case '<':
        return kColorAcento;
      default:
        return kColorTexto;
    }
  }
}

// ---------------------------------------------------------------------------
// Internal button widget
// ---------------------------------------------------------------------------

class _NumpadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color foregroundColor;

  const _NumpadButton({
    required this.label,
    required this.onTap,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2e2e2e),
      child: InkWell(
        onTap: onTap,
        splashColor: kColorPrimario.withOpacity(0.20),
        highlightColor: kColorPrimario.withOpacity(0.08),
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: Color(0xFF1a1a1a), width: 1),
              bottom: BorderSide(color: Color(0xFF1a1a1a), width: 1),
            ),
          ),
          child: label == '<'
              ? Icon(
                  Icons.backspace_outlined,
                  color: foregroundColor,
                  size: 22,
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
