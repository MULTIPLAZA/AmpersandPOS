import 'package:flutter/material.dart';

// Supabase — reemplazar con valores de tu proyecto
// Dashboard: supabase.com → proyecto → Settings → API
const String kSupabaseUrl     = 'https://TU_PROYECTO.supabase.co';
const String kSupabaseAnonKey = 'TU_ANON_KEY';

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
