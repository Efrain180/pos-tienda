import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/configuracion.dart';
import '../../providers/configuracion_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();
  final stockMinimoController = TextEditingController();
  final margenController = TextEditingController();

  bool usaFifo = true;
  bool usaFiados = true;
  bool firebaseActivo = false;

  bool cargado = false;

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    stockMinimoController.dispose();
    margenController.dispose();
    super.dispose();
  }

  void cargarDatos(Configuracion config) {
    if (cargado) return;

    nombreController.text = config.nombreNegocio ?? '';
    telefonoController.text = config.telefono ?? '';
    direccionController.text = config.direccion ?? '';
    stockMinimoController.text = config.stockMinimoGlobal.toString();
    margenController.text = config.margenGananciaDefault.toString();

    usaFifo = config.usaFifo;
    usaFiados = config.usaFiados;
    firebaseActivo = config.firebaseActivo;

    cargado = true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConfiguracionProvider>();

    if (provider.cargando || provider.configuracion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = provider.configuracion!;
    cargarDatos(config);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Configuración',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final margen =
                      double.tryParse(margenController.text.trim()) ?? 25;

                  final stockMinimo =
                      double.tryParse(stockMinimoController.text.trim()) ?? 5;

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
                    usaFifo: usaFifo,
                    usaFiados: usaFiados,
                    stockMinimoGlobal: stockMinimo,
                    impresoraTickets: config.impresoraTickets,
                    firebaseActivo: firebaseActivo,
                    margenGananciaDefault: margen,
                  );

                  await context
                      .read<ConfiguracionProvider>()
                      .guardarConfiguracion(nuevaConfig);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Configuración guardada'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    const Text(
                      'Datos del negocio',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del negocio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Reglas del sistema',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: stockMinimoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo global',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: margenController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Margen de ganancia deseado (%)',
                        helperText:
                            'Ejemplo: 25 significa que el precio recomendado deja 25% de margen',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Usar FIFO'),
                      subtitle: const Text(
                        'Vender primero los lotes que entraron primero',
                      ),
                      value: usaFifo,
                      onChanged: (value) {
                        setState(() => usaFifo = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Permitir fiados'),
                      subtitle: const Text(
                        'Habilita ventas a crédito para clientes',
                      ),
                      value: usaFiados,
                      onChanged: (value) {
                        setState(() => usaFiados = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Firebase activo'),
                      subtitle: const Text(
                        'Sincronización futura con celular/nube',
                      ),
                      value: firebaseActivo,
                      onChanged: (value) {
                        setState(() => firebaseActivo = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}