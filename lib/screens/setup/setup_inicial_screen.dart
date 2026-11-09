import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/setup_service.dart';

class SetupInicialScreen extends StatefulWidget {
  const SetupInicialScreen({super.key});

  @override
  State<SetupInicialScreen> createState() => _SetupInicialScreenState();
}

class _SetupInicialScreenState extends State<SetupInicialScreen> {
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();

  final usuarioController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarController = TextEditingController();

  bool cargando = false;
  bool mostrarPassword = false;

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    usuarioController.dispose();
    passwordController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final nombre = nombreController.text.trim();
    final telefono = telefonoController.text.trim();
    final direccion = direccionController.text.trim();
    final usuario = usuarioController.text.trim();
    final password = passwordController.text.trim();
    final confirmar = confirmarController.text.trim();

    if (nombre.isEmpty) {
      _mensaje('Escribe el nombre del negocio');
      return;
    }

    if (usuario.isEmpty) {
      _mensaje('Escribe el usuario administrador');
      return;
    }

    if (password.length < 4) {
      _mensaje('La contraseña debe tener al menos 4 caracteres');
      return;
    }

    if (password != confirmar) {
      _mensaje('Las contraseñas no coinciden');
      return;
    }

    setState(() => cargando = true);

    try {
      await SetupService().configurarSistemaInicial(
        nombreNegocio: nombre,
        telefono: telefono,
        direccion: direccion,
        usuarioAdmin: usuario,
        passwordAdmin: password,
      );

      if (!mounted) return;

      _mensaje('Sistema configurado correctamente');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppInicio()),
        (route) => false,
      );
    } catch (e) {
      _mensaje('Error al configurar: $e');
    } finally {
      if (mounted) {
        setState(() => cargando = false);
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
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(34),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF1E293B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.point_of_sale,
                              color: Color(0xFF0F172A),
                              size: 36,
                            ),
                          ),
                          SizedBox(height: 28),
                          Text(
                            'Bienvenido a tu punto de venta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Configura tu negocio y crea el usuario administrador. '
                            'Después podrás activar tu licencia Básica o Premium.',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: 30),
                          _FeatureItem(
                            icono: Icons.storefront,
                            texto: 'Datos del negocio para tickets y reportes',
                          ),
                          SizedBox(height: 14),
                          _FeatureItem(
                            icono: Icons.admin_panel_settings,
                            texto: 'Administrador creado por el cliente',
                          ),
                          SizedBox(height: 14),
                          _FeatureItem(
                            icono: Icons.workspace_premium,
                            texto: 'Licencia y plan se activan después',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuración inicial',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Completa estos datos para iniciar el sistema.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            icono: Icons.storefront_outlined,
                            titulo: 'Datos del negocio',
                          ),
                          const SizedBox(height: 12),
                          _SetupField(
                            controller: nombreController,
                            label: 'Nombre del negocio',
                            icono: Icons.store_outlined,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SetupField(
                                  controller: telefonoController,
                                  label: 'Teléfono',
                                  icono: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SetupField(
                                  controller: direccionController,
                                  label: 'Dirección',
                                  icono: Icons.location_on_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            icono: Icons.admin_panel_settings_outlined,
                            titulo: 'Usuario administrador',
                          ),
                          const SizedBox(height: 12),
                          _SetupField(
                            controller: usuarioController,
                            label: 'Usuario administrador',
                            icono: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _PasswordField(
                                  controller: passwordController,
                                  label: 'Contraseña',
                                  mostrar: mostrarPassword,
                                  onToggle: () {
                                    setState(() {
                                      mostrarPassword = !mostrarPassword;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PasswordField(
                                  controller: confirmarController,
                                  label: 'Confirmar contraseña',
                                  mostrar: mostrarPassword,
                                  onToggle: () {
                                    setState(() {
                                      mostrarPassword = !mostrarPassword;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.amber.withOpacity(0.14),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'El sistema iniciará en modo prueba. '
                                    'La licencia se puede activar después desde Configuración.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: cargando ? null : guardar,
                              icon: cargando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                cargando
                                    ? 'Configurando...'
                                    : 'Finalizar configuración',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
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
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _FeatureItem({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white.withOpacity(0.12),
          child: Icon(icono, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icono;
  final String titulo;

  const _SectionTitle({
    required this.icono,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 22, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SetupField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final TextInputType? keyboardType;

  const _SetupField({
    required this.controller,
    required this.label,
    required this.icono,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool mostrar;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.mostrar,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !mostrar,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            mostrar ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}