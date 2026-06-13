import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/configuracion.dart';
import '../../providers/configuracion_provider.dart';
import '../../services/firebase_sync_service.dart';
import '../../database/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/importar_excel_service.dart';

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

      // Se conservan internamente para no romper base/modelo.
      usaFifo: true,
      usaFiados: usaFiados,
      stockMinimoGlobal: config.stockMinimoGlobal,
      impresoraTickets: config.impresoraTickets,
      firebaseActivo: false,

      margenGananciaDefault: margen,
    );

    await context.read<ConfiguracionProvider>().guardarConfiguracion(
          nuevaConfig,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConfiguracionProvider>();

    if (provider.cargando || provider.configuracion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = provider.configuracion!;
    cargarDatos(config);

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
                const SizedBox(width: 10),


              ],
            ),
ElevatedButton.icon(
  onPressed: () async {
    try {
      FirebaseSyncService().sincronizarTodo().catchError((_) {});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase sincronizado correctamente'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error Firebase'),
            content: SingleChildScrollView(
              child: Text(e.toString()),
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
  },
  icon: const Icon(Icons.cloud_upload),
  label: const Text('Probar Firebase'),
),
OutlinedButton.icon(
  onPressed: () async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reiniciar datos de prueba'),
        content: const Text(
          'Esto borrará ventas, compras, productos, clientes, caja, créditos, gastos, mermas y auditoría. '
          'Se conservarán usuarios, roles, permisos y configuración. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await DatabaseService.instance.limpiarDatosPrueba();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos de prueba eliminados'),
        ),
      );
    }
  },
  icon: const Icon(Icons.delete_forever),
  label: const Text('Limpiar datos de prueba'),
),
OutlinedButton.icon(
  onPressed: () async {
    final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

    await ImportarExcelService().seleccionarEImportarCatalogo(
      usuarioId: usuarioId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catálogo importado correctamente'),
        ),
      );
    }
  },
  icon: const Icon(Icons.upload_file),
  label: const Text('Importar catálogo Excel'),
),
            const SizedBox(height: 16),


            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _ConfiguracionCard(
                      titulo: 'Datos del negocio',
                      subtitulo:
                          'Información que aparecerá en tickets y reportes',
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
                    flex: 5,
                    child: _ConfiguracionCard(
                      titulo: 'Reglas del sistema',
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            _InfoConfigBar(
              margen: margenController.text,
              fiados: usaFiados,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
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

  const _InfoConfigBar({
    required this.margen,
    required this.fiados,
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
              'Resumen: margen deseado $margen% · fiados ${fiados ? 'activos' : 'inactivos'} · FIFO automático',
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