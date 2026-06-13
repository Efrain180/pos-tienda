import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usuarioController = TextEditingController();
  final passwordController = TextEditingController();

  bool mostrarPassword = false;

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    final usuario = usuarioController.text.trim();
    final password = passwordController.text.trim();

    if (usuario.isEmpty || password.isEmpty) {
      _mensaje('Escribe usuario y contraseña');
      return;
    }

    final ok = await context.read<AuthProvider>().login(
          usuario: usuario,
          password: password,
        );

    if (!mounted) return;

    if (!ok) {
      _mensaje('Usuario o contraseña incorrectos');
      return;
    }

    usuarioController.clear();
    passwordController.clear();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorPrincipal = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF4F6F8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 980,
              maxHeight: 600,
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.all(34),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorPrincipal,
                            colorPrincipal.withOpacity(0.78),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.storefront_outlined,
                              size: 34,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'POS Tienda',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Control de ventas, inventario, caja y reportes en un solo lugar.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 16,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _LoginFeature(
                            icono: Icons.point_of_sale_outlined,
                            texto: 'Ventas rápidas',
                          ),
                          const SizedBox(height: 12),
                          _LoginFeature(
                            icono: Icons.inventory_2_outlined,
                            texto: 'Inventario controlado',
                          ),
                          const SizedBox(height: 12),
                          _LoginFeature(
                            icono: Icons.analytics_outlined,
                            texto: 'Información para tomar decisiones',
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(38),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor:
                                    colorPrincipal.withOpacity(0.10),
                                child: Icon(
                                  Icons.lock_outline,
                                  color: colorPrincipal,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Bienvenido',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Inicia sesión para continuar',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 30),

                              TextField(
                                controller: usuarioController,
                                autofocus: true,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Usuario',
                                  prefixIcon:
                                      const Icon(Icons.person_outline),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F8FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (_) {
                                  FocusScope.of(context).nextFocus();
                                },
                              ),

                              const SizedBox(height: 14),

                              TextField(
                                controller: passwordController,
                                obscureText: !mostrarPassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F8FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      mostrarPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        mostrarPassword = !mostrarPassword;
                                      });
                                    },
                                  ),
                                ),
                                onSubmitted: (_) => iniciarSesion(),
                              ),

                              const SizedBox(height: 22),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed:
                                      auth.cargando ? null : iniciarSesion,
                                  icon: auth.cargando
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.login),
                                  label: Text(
                                    auth.cargando
                                        ? 'Entrando...'
                                        : 'Entrar al sistema',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.16),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Usa las credenciales asignadas por el administrador.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _LoginFeature extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _LoginFeature({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          color: Colors.white.withOpacity(0.92),
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}