import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/compra.dart';
import '../../models/detalle_compra.dart';
import '../../models/producto.dart';
import '../../models/proveedor.dart';
import '../../providers/compra_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/proveedor_provider.dart';
import '../../providers/auth_provider.dart';

class ComprasScreen extends StatelessWidget {
  const ComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Registrar compra'),
              Tab(text: 'Historial'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                RegistrarCompraView(),
                HistorialComprasView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrarCompraView extends StatefulWidget {
  const RegistrarCompraView({super.key});

  @override
  State<RegistrarCompraView> createState() => _RegistrarCompraViewState();
}

class _RegistrarCompraViewState extends State<RegistrarCompraView> {
  Proveedor? proveedorSeleccionado;
  Producto? productoSeleccionado;

  final cantidadController = TextEditingController();
  final costoController = TextEditingController();
  final fechaCaducidadController = TextEditingController();

  final List<DetalleCompra> detalles = [];

  double get total {
    return detalles.fold(0, (sum, item) => sum + item.subtotal);
  }

  @override
  void dispose() {
    cantidadController.dispose();
    costoController.dispose();
    fechaCaducidadController.dispose();
    super.dispose();
  }

  void agregarProducto() {
    if (productoSeleccionado == null) return;

    final cantidad = double.tryParse(cantidadController.text.trim()) ?? 0;
    final costo = double.tryParse(costoController.text.trim()) ?? 0;

    if (cantidad <= 0 || costo <= 0) return;

    setState(() {
      detalles.add(
        DetalleCompra(
          productoId: productoSeleccionado!.id!,
          cantidad: cantidad,
          costoUnitario: costo,
          subtotal: cantidad * costo,
          fechaCaducidad: fechaCaducidadController.text.trim().isEmpty
              ? null
              : fechaCaducidadController.text.trim(),
        ),
      );

      productoSeleccionado = null;
      cantidadController.clear();
      costoController.clear();
      fechaCaducidadController.clear();
    });
  }

  Future<void> guardarCompra() async {
    if (detalles.isEmpty) return;

final usuarioActual = context.read<AuthProvider>().usuarioActual;

if (usuarioActual == null || usuarioActual.id == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('No hay usuario activo')),
  );
  return;
}

final compra = Compra(
  proveedorId: proveedorSeleccionado?.id,
  usuarioId: usuarioActual.id!,
  fecha: DateTime.now().toIso8601String(),
  subtotal: total,
  descuento: 0,
  total: total,
  estado: 'COMPLETADA',
);

    await context.read<CompraProvider>().registrarCompra(
          compra: compra,
          detalles: detalles,
        );

    await context.read<ProductoProvider>().cargarProductos();

    setState(() {
      detalles.clear();
      proveedorSeleccionado = null;
      productoSeleccionado = null;
      cantidadController.clear();
      costoController.clear();
      fechaCaducidadController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra registrada correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedores = context.watch<ProveedorProvider>().proveedores;
    final productos = context.watch<ProductoProvider>().productos;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Registrar compra',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: guardarCompra,
                icon: const Icon(Icons.save),
                label: const Text('Guardar compra'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<Proveedor?>(
            initialValue: proveedorSeleccionado,
            decoration: const InputDecoration(
              labelText: 'Proveedor',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<Proveedor?>(
                value: null,
                child: Text('Sin proveedor'),
              ),
              ...proveedores.map(
                (p) => DropdownMenuItem<Proveedor?>(
                  value: p,
                  child: Text(p.nombre),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => proveedorSeleccionado = value);
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<Producto?>(
                      initialValue: productoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<Producto?>(
                          value: null,
                          child: Text('Seleccionar producto'),
                        ),
                        ...productos.map(
                          (p) => DropdownMenuItem<Producto?>(
                            value: p,
                            child: Text(p.nombre),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => productoSeleccionado = value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: costoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Costo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: fechaCaducidadController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Caducidad opcional',
                        border: const OutlineInputBorder(),
                        suffixIcon: fechaCaducidadController.text.isEmpty
                            ? const Icon(Icons.calendar_month)
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    fechaCaducidadController.clear();
                                  });
                                },
                              ),
                      ),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );

                        if (fecha != null) {
                          setState(() {
                            fechaCaducidadController.text =
                                fecha.toIso8601String();
                          });
                        }
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: agregarProducto,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: detalles.isEmpty
                  ? const Center(child: Text('No hay productos agregados'))
                  : ListView.separated(
                      itemCount: detalles.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final detalle = detalles[index];

                        final producto = productos.firstWhere(
                          (p) => p.id == detalle.productoId,
                        );

                        return ListTile(
                          title: Text(producto.nombre),
                          subtitle: Text(
                            'Cantidad: ${detalle.cantidad} | '
                            'Costo: \$${detalle.costoUnitario.toStringAsFixed(2)}'
                            '${detalle.fechaCaducidad != null ? '\nCaduca: ${detalle.fechaCaducidad!.substring(0, 10)}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${detalle.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() => detalles.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class HistorialComprasView extends StatelessWidget {
  const HistorialComprasView({super.key});

  @override
  Widget build(BuildContext context) {
    final compraProvider = context.watch<CompraProvider>();
    final proveedores = context.watch<ProveedorProvider>().proveedores;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historial de compras',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () {
                  context.read<CompraProvider>().cargarCompras();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: compraProvider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: compraProvider.compras.isEmpty
                        ? const Center(
                            child: Text('No hay compras registradas'),
                          )
                        : ListView.separated(
                            itemCount: compraProvider.compras.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final compra = compraProvider.compras[index];

                              final proveedor = proveedores
                                  .where((p) => p.id == compra.proveedorId)
                                  .toList();

                              final proveedorNombre = proveedor.isEmpty
                                  ? 'Sin proveedor'
                                  : proveedor.first.nombre;

return ListTile(
  leading: const Icon(Icons.receipt_long),
  title: Text(
    'Compra #${compra.id} - $proveedorNombre',
  ),
  subtitle: Text(
    'Fecha: ${compra.fecha.substring(0, 10)} | '
    'Estado: ${compra.estado}',
  ),
  trailing: Text(
    '\$${compra.total.toStringAsFixed(2)}',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
  onTap: () => _mostrarDetalleCompra(context, compra),
);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
  void _mostrarDetalleCompra(BuildContext context, Compra compra) {
  final productos = context.read<ProductoProvider>().productos;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Detalle compra #${compra.id}'),
        content: SizedBox(
          width: 700,
          child: FutureBuilder<List<DetalleCompra>>(
            future: context.read<CompraProvider>().obtenerDetallesCompra(
                  compra.id!,
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final detalles = snapshot.data ?? [];

              if (detalles.isEmpty) {
                return const Text('Esta compra no tiene detalles.');
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...detalles.map((detalle) {
                    final producto = productos
                        .where((p) => p.id == detalle.productoId)
                        .toList();

                    final nombreProducto = producto.isEmpty
                        ? 'Producto #${detalle.productoId}'
                        : producto.first.nombre;

                    return ListTile(
                      title: Text(nombreProducto),
                      subtitle: Text(
                        'Cantidad: ${detalle.cantidad} | '
                        'Costo: \$${detalle.costoUnitario.toStringAsFixed(2)}'
                        '${detalle.fechaCaducidad != null ? '\nCaduca: ${detalle.fechaCaducidad!.substring(0, 10)}' : ''}',
                      ),
                      trailing: Text(
                        '\$${detalle.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total: \$${compra.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
}