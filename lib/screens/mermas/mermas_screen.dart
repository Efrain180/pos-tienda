import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/merma.dart';
import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merma_provider.dart';
import '../../providers/producto_provider.dart';

class MermasScreen extends StatelessWidget {
  const MermasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mermaProvider = context.watch<MermaProvider>();
    final productos = context.watch<ProductoProvider>().productos;
    final mermas = mermaProvider.mermas;

    final totalCantidad = mermas.fold<double>(
      0,
      (sum, merma) => sum + merma.cantidad,
    );

    final conStock = mermas.where((m) => m.descuentaStock).length;
    final sinStock = mermas.where((m) => !m.descuentaStock).length;

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Mermas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _MermaResumenCard(
                  label: 'Registros',
                  value: mermas.length.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                _MermaResumenCard(
                  label: 'Cantidad',
                  value: totalCantidad.toStringAsFixed(0),
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                _MermaResumenCard(
                  label: 'Desc. stock',
                  value: conStock.toString(),
                  color: Colors.red,
                ),
                const SizedBox(width: 10),
                _MermaResumenCard(
                  label: 'Sin stock',
                  value: sinStock.toString(),
                  color: Colors.grey,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _mostrarFormularioMerma(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar merma'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: mermaProvider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : mermas.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay mermas registradas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF2F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Producto',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Cantidad',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Motivo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Stock',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Fecha',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Expanded(
                                  child: ListView.separated(
                                    itemCount: mermas.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final merma = mermas[index];

                                      final producto = productos
                                          .where(
                                            (p) => p.id == merma.productoId,
                                          )
                                          .toList();

                                      final productoNombre = producto.isEmpty
                                          ? 'Producto #${merma.productoId}'
                                          : producto.first.nombre;

                                      return Container(
                                        height: 56,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: index.isEven
                                              ? Colors.white
                                              : const Color(0xFFFAFBFC),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: merma.descuentaStock
                                                ? Colors.red.withOpacity(0.18)
                                                : Colors.grey.withOpacity(0.12),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                productoNombre,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                merma.cantidad.toStringAsFixed(
                                                  merma.cantidad % 1 == 0
                                                      ? 0
                                                      : 2,
                                                ),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                merma.motivo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: _MermaChip(
                                                  texto: merma.descuentaStock
                                                      ? 'Descontado'
                                                      : 'No descuenta',
                                                  color: merma.descuentaStock
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatearFecha(merma.fecha),
                                                textAlign: TextAlign.right,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioMerma(BuildContext context) {
    final productos = context.read<ProductoProvider>().productos;

    Producto? productoSeleccionado;
    final cantidadController = TextEditingController();
    final motivoController = TextEditingController();

    String motivoSeleccionado = 'PRODUCTO_ROTO';
    bool descuentaStock = true;

    final motivos = [
      'PRODUCTO_ROTO',
      'PRODUCTO_CADUCADO',
      'PRODUCTO_PERDIDO',
      'DEVOLUCION_DANADA',
      'CONSUMO_INTERNO',
      'ROBO',
      'OTRO',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.12),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Registrar merma',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<Producto?>(
                        initialValue: productoSeleccionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Producto',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<Producto?>(
                            value: null,
                            child: Text('Seleccionar producto'),
                          ),
                          ...productos.map(
                            (p) => DropdownMenuItem<Producto?>(
                              value: p,
                              child: Text(
                                '${p.nombre}  |  Stock: ${p.stockActual}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => productoSeleccionado = value);
                        },
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cantidadController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Cantidad',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: motivoSeleccionado,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Motivo',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              items: motivos
                                  .map(
                                    (motivo) => DropdownMenuItem<String>(
                                      value: motivo,
                                      child: Text(_motivoLegible(motivo)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    motivoSeleccionado = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (motivoSeleccionado == 'OTRO')
                        TextField(
                          controller: motivoController,
                          decoration: InputDecoration(
                            labelText: 'Especificar motivo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                      if (motivoSeleccionado == 'OTRO')
                        const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.14),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: SwitchListTile(
                            title: const Text(
                              'Descontar del stock',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              descuentaStock
                                  ? 'Sí bajará el inventario del producto.'
                                  : 'Solo registrará la merma para reportes.',
                            ),
                            value: descuentaStock,
                            onChanged: (value) {
                              setState(() => descuentaStock = value);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: descuentaStock
                              ? Colors.red.withOpacity(0.08)
                              : Colors.blueGrey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: descuentaStock
                                ? Colors.red.withOpacity(0.18)
                                : Colors.blueGrey.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              descuentaStock
                                  ? Icons.inventory_2_outlined
                                  : Icons.info_outline,
                              color: descuentaStock
                                  ? Colors.red
                                  : Colors.blueGrey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                descuentaStock
                                    ? 'Usa esta opción para producto roto, caducado, perdido o robado.'
                                    : 'Usa esta opción si ya no quieres mover stock, pero sí registrar la pérdida.',
                                style: const TextStyle(
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (productoSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona un producto'),
                        ),
                      );
                      return;
                    }

                    final cantidad =
                        double.tryParse(cantidadController.text.trim()) ?? 0;

                    if (cantidad <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cantidad inválida'),
                        ),
                      );
                      return;
                    }

                    final motivo = motivoSeleccionado == 'OTRO'
                        ? motivoController.text.trim()
                        : motivoSeleccionado;

                    if (motivo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Escribe el motivo'),
                        ),
                      );
                      return;
                    }

                    final usuarioId =
                        context.read<AuthProvider>().usuarioActual!.id!;

                    final merma = Merma(
                      productoId: productoSeleccionado!.id!,
                      cantidad: cantidad,
                      motivo: motivo,
                      descuentaStock: descuentaStock,
                      usuarioId: usuarioId,
                      fecha: DateTime.now().toIso8601String(),
                    );

                    try {
                      await context.read<MermaProvider>().registrarMerma(
                            merma,
                          );

                      await context.read<ProductoProvider>().cargarProductos();

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Merma registrada correctamente'),
                          ),
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
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final anio = date.year.toString();
      final hora = date.hour.toString().padLeft(2, '0');
      final minuto = date.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$anio $hora:$minuto';
    } catch (_) {
      return fecha;
    }
  }

  static String _motivoLegible(String motivo) {
    switch (motivo) {
      case 'PRODUCTO_ROTO':
        return 'Producto roto';
      case 'PRODUCTO_CADUCADO':
        return 'Producto caducado';
      case 'PRODUCTO_PERDIDO':
        return 'Producto perdido';
      case 'DEVOLUCION_DANADA':
        return 'Devolución dañada';
      case 'CONSUMO_INTERNO':
        return 'Consumo interno';
      case 'ROBO':
        return 'Robo';
      case 'OTRO':
        return 'Otro';
      default:
        return motivo;
    }
  }
}

class _MermaResumenCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MermaResumenCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MermaChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _MermaChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}