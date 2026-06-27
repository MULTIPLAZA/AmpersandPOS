import 'package:flutter/material.dart';

// API
const String kApiUrl = 'https://nodoapi.ddns.net/sql';
const String kApiBearer =
    '73933b2b2901d24b20ee8de4542cfe7c072829e49921ad0795a3f16acbb2159e';

// SharedPreferences keys
const String kLicTokenKey = 'lic_token';
const String kEmailKey = 'lic_email';
const String kDeviceIdKey = 'device_id';
const String kTerminalKey = 'terminal_nombre';

// Colors
const Color kColorFondo = Color(0xFF1a1a1a);
const Color kColorSuperficie = Color(0xFF2a2a2a);
const Color kColorCard = Color(0xFF333333);
const Color kColorPrimario = Color(0xFF4caf50);
const Color kColorAcento = Color(0xFFff9800);
const Color kColorTexto = Colors.white;
const Color kColorTextoSecundario = Color(0xFFb0b0b0);

/// Formats a numeric value as Guaraníes with dot thousands separator.
/// Example: 150000 → "₲ 150.000"
String formatGs(num value) {
  final int intVal = value.round();
  final String str = intVal.toString();
  final String formatted = str.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (Match m) => '${m[1]}.',
  );
  return '₲ $formatted';
}
