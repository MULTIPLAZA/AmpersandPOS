import 'package:flutter/material.dart';

const String kSupabaseUrl     = 'https://kmreiniqgcvqgdtzvmel.supabase.co';
const String kSupabaseAnonKey = 'sb_publishable_j6btNHo1o3tSprmYUJITPw_8AsYgcvJ';

// SharedPreferences keys
const String kDeviceIdKey  = 'device_id';
const String kTerminalKey  = 'terminal_nombre';

// Colors
const Color kColorFondo             = Color(0xFF1a1a1a);
const Color kColorSuperficie        = Color(0xFF2a2a2a);
const Color kColorCard              = Color(0xFF333333);
const Color kColorPrimario          = Color(0xFF4caf50);
const Color kColorAcento            = Color(0xFFff9800);
const Color kColorTexto             = Colors.white;
const Color kColorTextoSecundario   = Color(0xFFb0b0b0);

String formatGs(num value) {
  final int intVal = value.round();
  final String str = intVal.toString();
  final String formatted = str.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (Match m) => '${m[1]}.',
  );
  return '₲ $formatted';
}
