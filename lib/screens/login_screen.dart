import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import 'pos_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _terminalCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureClave = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _claveCtrl.dispose();
    _terminalCtrl.dispose();
    super.dispose();
  }

  Future<void> _activar() async {
    final email = _emailCtrl.text.trim();
    final clave = _claveCtrl.text;
    final terminal = _terminalCtrl.text.trim();

    if (email.isEmpty || clave.isEmpty || terminal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá todos los campos')),
      );
      return;
    }

    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email, clave, terminal);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PosScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al activar licencia'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorFondo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: kColorCard,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kColorPrimario.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '&',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: kColorPrimario,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'AMPERSAND POS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kColorTexto,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistema de Punto de Venta',
                  style: TextStyle(
                    fontSize: 13,
                    color: kColorTextoSecundario,
                  ),
                ),
                const SizedBox(height: 40),
                // Form card
                Container(
                  decoration: BoxDecoration(
                    color: kColorSuperficie,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Activar licencia',
                        style: TextStyle(
                          color: kColorTexto,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ingresá tus credenciales para vincular este terminal.',
                        style: TextStyle(
                          color: kColorTextoSecundario,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Email
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(color: kColorTexto),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: kColorTextoSecundario,
                            size: 20,
                          ),
                        ),
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 14),
                      // Contraseña
                      TextField(
                        controller: _claveCtrl,
                        obscureText: _obscureClave,
                        style: const TextStyle(color: kColorTexto),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: kColorTextoSecundario,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureClave
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: kColorTextoSecundario,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscureClave = !_obscureClave),
                          ),
                        ),
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 14),
                      // Terminal
                      TextField(
                        controller: _terminalCtrl,
                        style: const TextStyle(color: kColorTexto),
                        decoration: const InputDecoration(
                          labelText: 'Nombre de terminal',
                          prefixIcon: Icon(
                            Icons.computer,
                            color: kColorTextoSecundario,
                            size: 20,
                          ),
                          hintText: 'Ej: Caja 1',
                        ),
                        onSubmitted: (_) => _activar(),
                      ),
                      const SizedBox(height: 28),
                      // Loading indicator or button
                      if (_loading)
                        Column(
                          children: [
                            const LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  kColorPrimario),
                              backgroundColor: kColorCard,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Verificando licencia...',
                              style: TextStyle(
                                  color: kColorTextoSecundario, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: _activar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kColorPrimario,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'ACTIVAR LICENCIA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: kColorTextoSecundario,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
