import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/configuracion.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_provider.dart';
import '../../providers/licencia_provider.dart';
import '../../services/backup_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/importar_excel_service.dart';
import '../../services/licencia_service.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();
  final margenController = TextEditingController();

  bool usaFiados = true;
  bool cargado = false;

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    margenController.dispose();
    super.dispose();
  }

  void cargarDatos(Configuracion config) {
    if (cargado) return;

    nombreController.text = config.nombreNegocio ?? '';
    telefonoController.text = config.telefono ?? '';
    direccionController.text = config.direccion ?? '';
    margenController.text = config.margenGananciaDefault.toString();

    usaFiados = config.usaFiados;
    cargado = true;
  }

  Future<void> _guardar(BuildContext context, Configuracion config) async {
    final margen = double.tryParse(margenController.text.trim()) ?? 25;

    final nuevaConfig = Configuracion(
      id: config.id,
      nombreNegocio: nombreController.text.trim().isEmpty
          ? null
          : nombreController.text.trim(),
      telefono: telefonoController.text.trim().isEmpty
          ? null
          : telefonoController.text.trim(),
      direccion: direccionController.text.trim().isEmpty
          ? null
          : direccionController.text.trim(),
      usaFifo: true,
      usaFiados: usaFiados,
      stockMinimoGlobal: config.stockMinimoGlobal,
      impresoraTickets: config.impresoraTickets,
      firebaseActivo: config.firebaseActivo,
      margenGananciaDefault: margen,
      negocioId: config.negocioId,
      nubeActiva: config.nubeActiva,
      plan: config.plan,
      tipoLicencia: config.tipoLicencia,
    );

    await context.read<ConfiguracionProvider>().guardarConfiguracion(nuevaConfig);

    if (context.mounted) {
      setState(() => cargado = false);
      _mensaje('Configuración guardada');
    }
  }

  Future<void> _activarLicencia(BuildContext context) async {
    final controller = TextEditingController();

    final clave = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Activar licencia'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Clave de licencia',
            hintText: 'POS-PREMIUM-001',
            prefixIcon: Icon(Icons.vpn_key_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (clave == null || clave.isEmpty) return;

    try {
      final service = LicenciaService();
      final planLicencia = await service.obtenerPlanLicenciaFirebase(clave);

      if (!context.mounted) return;

      if (planLicencia == null) {
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
            title: const Text('Crear acceso para APK'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario APK',

                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña APK',
                    hintText: '1234',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
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

        if (datosApp == null) return;

        usuarioApp = datosApp['usuario'];
        passwordApp = datosApp['password'];

        if (usuarioApp == null ||
            usuarioApp.trim().isEmpty ||
            passwordApp == null ||
            passwordApp.trim().isEmpty) {
          _mensaje('Usuario y contraseña APK son obligatorios');
          return;
        }
      }

      final ok = await service.activarLicencia(
        clave: clave,
        usuarioApp: usuarioApp,
        passwordApp: passwordApp,
      );

      if (!context.mounted) return;

      if (!ok) {
        _mensaje('Clave inválida');
        return;
      }

      await context.read<ConfiguracionProvider>().cargarConfiguracion();
      await context.read<LicenciaProvider>().cargarLicencia();

      setState(() => cargado = false);

      _mensaje('Licencia activada correctamente');
    } catch (e) {
      _mensaje('Error: $e');
    }
  }

  Future<void> _cambiarAccesoApk(
    BuildContext context,
    Configuracion config,
  ) async {
    final negocioId = config.negocioId?.trim() ?? '';

    if (negocioId.isEmpty) {
      _mensaje('Este negocio no tiene ID asignado');
      return;
    }

    final usuarioController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmarController = TextEditingController();

    final datos = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar acceso APK'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usuarioController,
              decoration: const InputDecoration(
                labelText: 'Nuevo usuario APK',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmarController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_reset),
                border: OutlineInputBorder(),
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
                'confirmar': confirmarController.text.trim(),
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (datos == null) return;

    final usuario = datos['usuario'] ?? '';
    final password = datos['password'] ?? '';
    final confirmar = datos['confirmar'] ?? '';

    if (usuario.isEmpty || password.isEmpty || confirmar.isEmpty) {
      _mensaje('Completa usuario y contraseña');
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

    try {
      await LicenciaService().actualizarAccesoAppPremium(
        negocioId: negocioId,
        usuario: usuario,
        password: password,
      );

      if (!context.mounted) return;

      _mensaje('Acceso APK actualizado correctamente');
    } catch (e) {
      _mensaje('Error al actualizar acceso APK: $e');
    }
  }

  Future<void> _importarCatalogo(BuildContext context) async {
    try {
      final usuario = context.read<AuthProvider>().usuarioActual;

      if (usuario == null || usuario.id == null) {
        _mensaje('No hay usuario activo');
        return;
      }

      await ImportarExcelService().seleccionarEImportarCatalogo(
        usuarioId: usuario.id!,
      );

      if (!context.mounted) return;
      _mensaje('Catálogo importado correctamente');
    } catch (e) {
      _mensaje('Error al importar: $e');
    }
  }

  Future<void> _actualizarNube(BuildContext context) async {
    try {
      await FirebaseSyncService().sincronizarTodo();

      if (!context.mounted) return;

      await context.read<ConfiguracionProvider>().cargarConfiguracion();

      setState(() => cargado = false);

      _mensaje('Datos actualizados en la nube correctamente');
    } catch (e) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nube no disponible'),
          content: SingleChildScrollView(
            child: Text(e.toString().replaceAll('Exception: ', '')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _respaldar() async {
    try {
      await BackupService().exportarBackupManual();
      _mensaje('Respaldo creado correctamente');
    } catch (e) {
      _mensaje('Error al respaldar: $e');
    }
  }

  Future<void> _restaurarRespaldo(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
          'Esto reemplazará la base de datos actual por el respaldo seleccionado. '
          'Antes se creará una copia de emergencia. Después deberás reiniciar el sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, restaurar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final path = await BackupService().restaurarBackupDesdeArchivo();

      if (!context.mounted) return;

      if (path == null) {
        _mensaje('Restauración cancelada');
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Respaldo restaurado'),
          content: const Text(
            'La base de datos fue restaurada correctamente. '
            'Cierra y vuelve a abrir el sistema para cargar los datos restaurados.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      _mensaje('Error al restaurar: $e');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConfiguracionProvider>();

    if (provider.cargando || provider.configuracion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = provider.configuracion!;
    cargarDatos(config);

    final plan = (config.plan ?? 'PRUEBA').toUpperCase();
    final tipoLicencia = (config.tipoLicencia ?? 'PRUEBA').toUpperCase();
    final esPremium = plan == 'PREMIUM';
    final esBasico = plan == 'BASICO';

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.settings_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Configuración',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _guardar(context, config),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
children: [
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _ConfiguracionCard(
          titulo: 'Datos del negocio',
          subtitulo: 'Información para tickets y reportes',
          icono: Icons.storefront_outlined,
          color: Colors.blue,
          child: Column(
            children: [
              _CampoConfig(
                controller: nombreController,
                label: 'Nombre del negocio',
                icono: Icons.store_outlined,
              ),
              const SizedBox(height: 12),
              _CampoConfig(
                controller: telefonoController,
                label: 'Teléfono',
                icono: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              _CampoConfig(
                controller: direccionController,
                label: 'Dirección',
                icono: Icons.location_on_outlined,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _ConfiguracionCard(
          titulo: 'Licencia y plan',
          subtitulo: 'Activación y acceso móvil',
          icono: Icons.workspace_premium,
          color: Colors.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EstadoChip(
                    texto: esPremium
                        ? 'Premium'
                        : esBasico
                            ? 'Básico'
                            : 'Prueba',
                    icono: esPremium
                        ? Icons.workspace_premium
                        : esBasico
                            ? Icons.verified_outlined
                            : Icons.hourglass_top,
                    color: esPremium
                        ? Colors.amber
                        : esBasico
                            ? Colors.blue
                            : Colors.orange,
                  ),
                  _EstadoChip(
                    texto: tipoLicencia,
                    icono: Icons.vpn_key_outlined,
                    color: tipoLicencia == 'SUSCRIPCION'
                        ? Colors.green
                        : Colors.indigo,
                  ),
                  _EstadoChip(
                    texto: config.nubeActiva
                        ? 'Nube activa'
                        : 'Nube inactiva',
                    icono: Icons.cloud_outlined,
                    color: config.nubeActiva ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ID del negocio',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      config.negocioId ?? 'Sin asignar',
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => _activarLicencia(context),
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Activar licencia'),
                  ),
                  if (esPremium && config.nubeActiva)
                    OutlinedButton.icon(
                      onPressed: () => _cambiarAccesoApk(context, config),
                      icon: const Icon(Icons.phone_android),
                      label: const Text('Cambiar acceso APK'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  ),

  const SizedBox(height: 16),

  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _ConfiguracionCard(
          titulo: 'Operación',
          subtitulo: 'Parámetros generales del punto de venta',
          icono: Icons.tune_outlined,
          color: Colors.green,
          child: Column(
            children: [
              _CampoConfig(
                controller: margenController,
                label: 'Margen deseado (%)',
                icono: Icons.percent,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _OpcionConfig(
                titulo: 'Permitir ventas fiadas',
                descripcion:
                    'Habilita ventas a crédito para clientes autorizados.',
                icono: Icons.credit_score_outlined,
                color: Colors.orange,
                value: usaFiados,
                onChanged: (value) {
                  setState(() => usaFiados = value);
                },
              ),
              const SizedBox(height: 14),
              const _InfoSistemaCard(),
            ],
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _ConfiguracionCard(
          titulo: 'Respaldos locales',
          subtitulo: 'Protege la base de datos del negocio',
          icono: Icons.backup_outlined,
          color: Colors.teal,
          child: Column(
            children: [
              _SimpleAction(
                icono: Icons.save_alt,
                titulo: 'Respaldar ahora',
                descripcion: 'Crea una copia local de seguridad.',
                filled: true,
                onTap: _respaldar,
              ),
              const SizedBox(height: 10),
              _SimpleAction(
                icono: Icons.restore,
                titulo: 'Restaurar respaldo',
                descripcion: 'Recupera una copia anterior.',
                filled: false,
                onTap: () => _restaurarRespaldo(context),
              ),
            ],
          ),
        ),
      ),
    ],
  ),

  const SizedBox(height: 16),

  _ConfiguracionCard(
    titulo: 'Funciones Premium',
    subtitulo: esPremium
        ? 'Herramientas avanzadas disponibles'
        : 'Activa Premium para usar nube, APK e importación avanzada',
    icono: Icons.auto_awesome_outlined,
    color: Colors.purple,
    child: Row(
      children: [
        Expanded(
          child: _PremiumAction(
            activo: esPremium,
            icono: Icons.upload_file,
            titulo: 'Importar catálogo Excel',
            descripcion: 'Carga productos rápidamente desde un archivo Excel.',
            onTap: () => esPremium
                ? _importarCatalogo(context)
                : _mensaje(
                    'Importar Excel está disponible únicamente en Premium',
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PremiumAction(
            activo: esPremium,
            icono: Icons.cloud_sync,
            titulo: 'Actualizar datos en nube',
            descripcion: 'Sincroniza información para visualizarla en la APK.',
            onTap: () => esPremium
                ? _actualizarNube(context)
                : _mensaje(
                    'La nube está disponible únicamente en Premium',
                  ),
          ),
        ),
      ],
    ),
  ),

  const SizedBox(height: 16),

  _InfoConfigBar(
    margen: margenController.text,
    fiados: usaFiados,
    plan: plan,
    nubeActiva: config.nubeActiva,
  ),
],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfiguracionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final Widget child;

  const _ConfiguracionCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icono, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _CampoConfig extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final TextInputType? keyboardType;
  final int maxLines;

  const _CampoConfig({
    required this.controller,
    required this.label,
    required this.icono,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _OpcionConfig extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OpcionConfig({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withOpacity(0.22) : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          secondary: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icono, color: color),
          ),
          title: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(descripcion),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;

  const _EstadoChip({
    required this.texto,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icono, size: 18, color: color),
      label: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      backgroundColor: color.withOpacity(0.10),
      side: BorderSide(color: color.withOpacity(0.25)),
    );
  }
}

class _PremiumAction extends StatelessWidget {
  final bool activo;
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _PremiumAction({
    required this.activo,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? Colors.purple : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(activo ? icono : Icons.lock_outline, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activo ? titulo : '$titulo · Premium',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _SimpleAction extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool filled;
  final VoidCallback onTap;

  const _SimpleAction({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.teal : Colors.blueGrey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _InfoSistemaCard extends StatelessWidget {
  const _InfoSistemaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.withOpacity(0.12),
            child: const Icon(
              Icons.low_priority_outlined,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventario FIFO automático',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'El sistema consume primero los lotes más antiguos para mantener costos, caducidades y utilidad correcta.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoConfigBar extends StatelessWidget {
  final String margen;
  final bool fiados;
  final String plan;
  final bool nubeActiva;

  const _InfoConfigBar({
    required this.margen,
    required this.fiados,
    required this.plan,
    required this.nubeActiva,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Resumen: plan $plan · nube ${nubeActiva ? 'activa' : 'inactiva'} · margen $margen% · fiados ${fiados ? 'activos' : 'inactivos'} · FIFO automático',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}