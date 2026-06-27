import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'providers/auth_provider.dart';
import 'providers/carrito_provider.dart';
import 'providers/productos_provider.dart';
import 'providers/turno_provider.dart';
import 'screens/splash_screen.dart';
import 'services/db_service.dart';

// Acceso global al cliente Supabase
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  await DbService.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductosProvider()),
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => TurnoProvider()),
      ],
      child: const AmpersandApp(),
    ),
  );
}

class AmpersandApp extends StatelessWidget {
  const AmpersandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ampersand POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kColorFondo,
        cardColor: kColorCard,
        primaryColor: kColorPrimario,
        colorScheme: const ColorScheme.dark(
          primary: kColorPrimario,
          secondary: kColorAcento,
          surface: kColorSuperficie,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kColorSuperficie,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: kColorTexto,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: kColorTexto),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kColorPrimario,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kColorCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kColorPrimario),
          ),
          labelStyle: const TextStyle(color: kColorTextoSecundario),
          hintStyle: const TextStyle(color: kColorTextoSecundario),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
