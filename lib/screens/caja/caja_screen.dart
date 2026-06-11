import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/caja.dart';
import '../../models/movimiento_caja.dart';
import '../../providers/caja_provider.dart';
import '../../providers/auth_provider.dart';

class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CajaProvider>();

    if (provider.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Corte de caja',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              context.read<CajaProvider>().cargarCaja();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      const SizedBox(height: 20),

      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (provider.cajaAbierta == null)
                _CajaCerradaView()
              else
                _CajaAbiertaView(caja: provider.cajaAbierta!),

              const SizedBox(height: 20),

              SizedBox(
                height: 250,
                child: _HistorialCajasView(
                  cajas: provider.historial,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }
}

class _CajaCerradaView extends StatelessWidget {
  _CajaCerradaView();

  final montoInicialController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'No hay caja abierta',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: montoInicialController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto inicial',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final monto =
                    double.tryParse(montoInicialController.text.trim()) ?? 0;

                try {
final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

await context.read<CajaProvider>().abrirCaja(
  montoInicial: monto,
  usuarioId: usuarioId,
);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caja abierta')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.lock_open),
              label: const Text('Abrir caja'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CajaAbiertaView extends StatelessWidget {
  final Caja caja;

  const _CajaAbiertaView({
    required this.caja,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _ResumenCajaCard(
              titulo: 'Monto inicial',
              valor: '\$${caja.montoInicial.toStringAsFixed(2)}',
            ),
            _ResumenCajaCard(
              titulo: 'Esperado',
              valor: '\$${caja.montoEsperado.toStringAsFixed(2)}',
            ),
            _ResumenCajaCard(
              titulo: 'Estado',
              valor: caja.estado,
            ),
            _ResumenCajaCard(
              titulo: 'Apertura',
              valor: caja.fechaApertura.substring(0, 10),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _registrarGasto(context),
              icon: const Icon(Icons.money_off),
              label: const Text('Registrar gasto'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _cerrarCaja(context, caja),
              icon: const Icon(Icons.lock),
              label: const Text('Cerrar caja'),
            ),
          ],
        ),
        const SizedBox(height: 16),
SizedBox(
  height: 360,
  child: Row(
    children: [
      Expanded(
        child: _ReporteCajaView(caja: caja),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _MovimientosCajaView(cajaId: caja.id!),
      ),
    ],
  ),
),
      ],
    );
  }

  void _registrarGasto(BuildContext context) {
    final categoriaController = TextEditingController();
    final descripcionController = TextEditingController();
    final montoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Registrar gasto'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    hintText: 'Luz, renta, gasolina, papelería...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final categoria = categoriaController.text.trim();
                final descripcion = descripcionController.text.trim();
                final monto = double.tryParse(montoController.text.trim()) ?? 0;

                if (categoria.isEmpty || monto <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos inválidos')),
                  );
                  return;
                }

                try {
await context.read<CajaProvider>().registrarGasto(
  categoria: categoria,
  descripcion: descripcion.isEmpty ? null : descripcion,
  monto: monto,
  usuarioId: 1,
);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _cerrarCaja(BuildContext context, Caja caja) {
    final montoContadoController = TextEditingController(
      text: caja.montoEsperado.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar caja'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Monto esperado'),
                  trailing: Text(
                    '\$${caja.montoEsperado.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoContadoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto contado físicamente',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final contado =
                    double.tryParse(montoContadoController.text.trim()) ?? 0;

                try {
final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

await context.read<CajaProvider>().cerrarCaja(
  montoContado: contado,
  usuarioId: usuarioId,
);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caja cerrada')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Cerrar caja'),
            ),
          ],
        );
      },
    );
  }
}

class _MovimientosCajaView extends StatelessWidget {
  final int cajaId;

  const _MovimientosCajaView({
    required this.cajaId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<List<MovimientoCaja>>(
        future: context.read<CajaProvider>().obtenerMovimientosCaja(cajaId),
        builder: (context, snapshot) {
          final movimientos = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (movimientos.isEmpty) {
            return const Center(child: Text('Sin movimientos de caja'));
          }

          return ListView.separated(
            itemCount: movimientos.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final mov = movimientos[index];

              return ListTile(
                leading: Icon(
                  mov.monto >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                  color: mov.monto >= 0 ? Colors.green : Colors.red,
                ),
                title: Text(mov.tipo),
                subtitle: Text(
                  '${mov.referencia ?? 'Sin referencia'} | ${mov.fecha.substring(0, 10)}',
                ),
                trailing: Text(
                  '\$${mov.monto.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistorialCajasView extends StatelessWidget {
  final List<Caja> cajas;

  const _HistorialCajasView({
    required this.cajas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: cajas.isEmpty
          ? const Center(child: Text('No hay cortes registrados'))
          : ListView.separated(
              itemCount: cajas.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final caja = cajas[index];

                return ListTile(
                  leading: Icon(
                    caja.estado == 'ABIERTA'
                        ? Icons.lock_open
                        : Icons.lock_outline,
                  ),
                  title: Text('Caja #${caja.id} - ${caja.estado}'),
                  subtitle: Text(
                    'Apertura: ${caja.fechaApertura.substring(0, 10)}'
                    '${caja.fechaCierre != null ? ' | Cierre: ${caja.fechaCierre!.substring(0, 10)}' : ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Esperado: \$${caja.montoEsperado.toStringAsFixed(2)}'),
                      if (caja.montoContado != null)
                        Text(
                          'Contado: \$${caja.montoContado!.toStringAsFixed(2)}',
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
class _ReporteCajaView extends StatelessWidget {
  final Caja caja;

  const _ReporteCajaView({
    required this.caja,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<Map<String, double>>(
        future: context.read<CajaProvider>().obtenerResumenCaja(caja.id!),
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (data == null) {
            return const Center(child: Text('No se pudo cargar el reporte'));
          }

          final gastos = data['gastos'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reporte de caja',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _LineaReporte(
                  titulo: 'Monto inicial',
                  valor: data['apertura'] ?? 0,
                ),
                _LineaReporte(
                  titulo: 'Ventas efectivo',
                  valor: data['ventas_efectivo'] ?? 0,
                ),
                _LineaReporte(
                  titulo: 'Abonos crédito',
                  valor: data['abonos_credito'] ?? 0,
                ),
                _LineaReporte(
                  titulo: 'Gastos',
                  valor: gastos,
                ),
                const Divider(),
                _LineaReporte(
                  titulo: 'Total esperado',
                  valor: data['esperado'] ?? 0,
                  destacado: true,
                ),
                if (caja.montoContado != null) ...[
                  const SizedBox(height: 12),
                  _LineaReporte(
                    titulo: 'Monto contado',
                    valor: caja.montoContado!,
                    destacado: true,
                  ),
                  _LineaReporte(
                    titulo: 'Faltante',
                    valor: caja.faltante,
                  ),
                  _LineaReporte(
                    titulo: 'Sobrante',
                    valor: caja.sobrante,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LineaReporte extends StatelessWidget {
  final String titulo;
  final double valor;
  final bool destacado;

  const _LineaReporte({
    required this.titulo,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final esNegativo = valor < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
                fontSize: destacado ? 18 : 15,
              ),
            ),
          ),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              fontSize: destacado ? 18 : 15,
              color: esNegativo ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenCajaCard extends StatelessWidget {
  final String titulo;
  final String valor;

  const _ResumenCajaCard({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(titulo),
              const SizedBox(height: 6),
              Text(
                valor,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}