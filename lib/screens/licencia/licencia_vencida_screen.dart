import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/licencia_provider.dart';
import '../../main.dart';


class LicenciaVencidaScreen extends StatefulWidget {
  const LicenciaVencidaScreen({super.key});

  @override
  State<LicenciaVencidaScreen> createState() => _LicenciaVencidaScreenState();
}

class _LicenciaVencidaScreenState extends State<LicenciaVencidaScreen> {
  final claveController = TextEditingController();
  bool cargando = false;

  @override
  void dispose() {
    claveController.dispose();
    super.dispose();
  }

Future<void> activar() async {
  final clave = claveController.text.trim();

  if (clave.isEmpty) {
    _mensaje('Escribe la clave de licencia');
    return;
  }

  setState(() => cargando = true);

  try {
    final licenciaProvider = context.read<LicenciaProvider>();

    final planLicencia =
        await licenciaProvider.obtenerPlanLicenciaFirebase(clave);

    if (!mounted) return;

    if (planLicencia == null) {
      setState(() => cargando = false);
      _mensaje('Clave inválida');
      return;
    }

    String? usuarioApp;
    String? passwordApp;

    if (planLicencia == 'PREMIUM') {
      final usuarioController = TextEditingController();
      final passwordController = TextEditingController();

      final datosApp = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Acceso para APK'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuario APK',
                  hintText: 'lupita',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña APK',
                  hintText: '1234',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'usuario': usuarioController.text.trim(),
                  'password': passwordController.text.trim(),
                });
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (datosApp == null) {
        setState(() => cargando = false);
        return;
      }

      usuarioApp = datosApp['usuario'];
      passwordApp = datosApp['password'];

      if (usuarioApp == null ||
          usuarioApp.trim().isEmpty ||
          passwordApp == null ||
          passwordApp.trim().isEmpty) {
        setState(() => cargando = false);
        _mensaje('Usuario y contraseña APK son obligatorios');
        return;
      }
    }

    final ok = await licenciaProvider.activarLicencia(
      clave: clave,
      usuarioApp: usuarioApp,
      passwordApp: passwordApp,
    );

    if (!mounted) return;

    setState(() => cargando = false);

    if (!ok) {
      _mensaje('Clave inválida');
      return;
    }

    _mensaje('Licencia activada correctamente');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AppInicio(),
      ),
      (route) => false,
    );
  } catch (e) {
    if (mounted) {
      setState(() => cargando = false);
      _mensaje('Error: $e');
    }
  }
}

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_clock,
                size: 70,
                color: Colors.red,
              ),
              const SizedBox(height: 18),
              const Text(
                'Licencia vencida',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tu periodo de prueba terminó. Escribe tu clave para activar el sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: claveController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Clave de licencia',
                  hintText: 'POS-2026-ABCD',
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => activar(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: cargando ? null : activar,
                  icon: cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    cargando ? 'Activando...' : 'Activar licencia',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ejemplo válido: POS-2026-ABCD',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}