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
          Material(
            color: Colors.white,
            child: TabBar(
              tabs: [
                Tab(text: 'Registrar compra'),
                Tab(text: 'Historial'),
              ],
            ),
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

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Registrar compra',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompraResumenCard(
                  label: 'Productos',
                  value: detalles.length.toString(),
                ),
                const SizedBox(width: 10),
                _CompraResumenCard(
                  label: 'Total',
                  value: '\$${total.toStringAsFixed(2)}',
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: detalles.isEmpty ? null : guardarCompra,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar compra'),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
child: Padding(
  padding: const EdgeInsets.all(16),
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_box_outlined),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Agregar producto',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

Autocomplete<Proveedor>(
  optionsBuilder: (TextEditingValue value) {
    final texto = value.text.toLowerCase().trim();

    if (texto.isEmpty) {
      return proveedores.take(10);
    }

    return proveedores.where((p) {
      return p.nombre.toLowerCase().contains(texto);
    }).take(10);
  },
  displayStringForOption: (p) => p.nombre,
  onSelected: (p) {
    setState(() => proveedorSeleccionado = p);
  },
  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
    if (proveedorSeleccionado != null &&
        controller.text != proveedorSeleccionado!.nombre) {
      controller.text = proveedorSeleccionado!.nombre;
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Buscar proveedor',
        hintText: 'Escribe el nombre del proveedor',
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        suffixIcon: proveedorSeleccionado == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => proveedorSeleccionado = null);
                  controller.clear();
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  },
),  

              const SizedBox(height: 14),

RawAutocomplete<Producto>(
  displayStringForOption: (p) => p.nombre,
  optionsBuilder: (TextEditingValue value) async {
    final texto = value.text.trim();

    if (texto.isEmpty) {
      return const Iterable<Producto>.empty();
    }

    return await context
        .read<ProductoProvider>()
        .buscarProductosParaSeleccion(texto, limit: 20);
  },
  onSelected: (p) {
    setState(() => productoSeleccionado = p);
  },
  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Buscar producto',
        hintText: 'Nombre, código de barras o código interno',
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        suffixIcon: productoSeleccionado == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => productoSeleccionado = null);
                  controller.clear();
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  },
  optionsViewBuilder: (context, onSelected, options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 420,
          height: 260,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final producto = options.elementAt(index);

              return ListTile(
                title: Text(producto.nombre),
                subtitle: Text(
                  [
                    producto.codigoBarras,
                    producto.codigoInterno,
                  ].where((e) => e != null && e!.isNotEmpty).join(' · '),
                ),
                onTap: () => onSelected(producto),
              );
            },
          ),
        ),
      ),
    );
  },
),            const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: costoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Costo unitario',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: fechaCaducidadController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Caducidad opcional',
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
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
                      fechaCaducidadController.text = fecha.toIso8601String();
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: agregarProducto,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Agregar a la compra',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL COMPRA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
),
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    flex: 7,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Productos de la compra (${detalles.length})',
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Container(
                              height: 40,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF2F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Producto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Cant.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Costo',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Subtotal',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Caducidad',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 44),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            Expanded(
                              child: detalles.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No hay productos agregados',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: detalles.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (context, index) {
                                        final detalle = detalles[index];

Producto? producto;

try {
  producto = productos.firstWhere(
    (p) => p.id == detalle.productoId,
  );
} catch (_) {
  producto = null;
}

final nombreProducto = producto?.nombre ?? 'Producto #${detalle.productoId}';

                                        return Container(
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: index.isEven
                                                ? Colors.white
                                                : const Color(0xFFFAFBFC),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.10),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: Text(
                                                  producto?.nombre ?? 'Producto eliminado',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '${detalle.cantidad}',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '\$${detalle.costoUnitario.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '\$${detalle.subtotal.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  detalle.fechaCaducidad == null
                                                      ? 'Sin caducidad'
                                                      : detalle.fechaCaducidad!
                                                          .substring(0, 10),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: detalle
                                                                .fechaCaducidad ==
                                                            null
                                                        ? Colors.grey
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 44,
                                                child: IconButton(
                                                  tooltip: 'Quitar',
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  color: Colors.red,
                                                  onPressed: () {
                                                    setState(
                                                      () => detalles
                                                          .removeAt(index),
                                                    );
                                                  },
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
          ],
        ),
      ),
    );
  }
}

class _CompraResumenCard extends StatelessWidget {
  final String label;
  final String value;

  const _CompraResumenCard({
    required this.label,
    required this.value,
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
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
    final compras = compraProvider.compras;

    final totalComprado = compras.fold<double>(
      0,
      (sum, compra) => sum + compra.total,
    );

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Historial de compras',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompraResumenCard(
                  label: 'Compras',
                  value: compras.length.toString(),
                ),
                const SizedBox(width: 10),
                _CompraResumenCard(
                  label: 'Total',
                  value: '\$${totalComprado.toStringAsFixed(2)}',
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Actualizar',
                  onPressed: () {
                    context.read<CompraProvider>().cargarCompras();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Expanded(
              child: compraProvider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : compras.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay compras registradas',
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
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          'Compra',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Proveedor',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Fecha',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Estado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Total',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 52),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Expanded(
                                  child: ListView.separated(
                                    itemCount: compras.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final compra = compras[index];

                                      final proveedor = proveedores
                                          .where(
                                            (p) => p.id == compra.proveedorId,
                                          )
                                          .toList();

                                      final proveedorNombre = proveedor.isEmpty
                                          ? 'Sin proveedor'
                                          : proveedor.first.nombre;

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => _mostrarDetalleCompra(
                                          context,
                                          compra,
                                        ),
                                        child: Container(
                                          height: 54,
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
                                              color:
                                                  Colors.grey.withOpacity(0.10),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  '#${compra.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  proveedorNombre,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  _formatearFecha(compra.fecha),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: _CompraChip(
                                                    texto: compra.estado,
                                                    color: compra.estado ==
                                                            'COMPLETADA'
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '\$${compra.total.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 52,
                                                child: IconButton(
                                                  tooltip: 'Detalle',
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                  ),
                                                  onPressed: () =>
                                                      _mostrarDetalleCompra(
                                                    context,
                                                    compra,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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

  String _formatearFecha(String fecha) {
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

  void _mostrarDetalleCompra(BuildContext context, Compra compra) {
    final productos = context.read<ProductoProvider>().productos;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.receipt_long_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Detalle compra #${compra.id}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '\$${compra.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 800,
            child: FutureBuilder<List<DetalleCompra>>(
              future: context.read<CompraProvider>().obtenerDetallesCompra(
                    compra.id!,
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final detalles = snapshot.data ?? [];

                if (detalles.isEmpty) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text('Esta compra no tiene detalles.'),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF2F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Producto',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Cant.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Costo',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Subtotal',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Caducidad',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: detalles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final detalle = detalles[index];

                          final producto = productos
                              .where((p) => p.id == detalle.productoId)
                              .toList();

                          final nombreProducto = producto.isEmpty
                              ? 'Producto #${detalle.productoId}'
                              : producto.first.nombre;

                          return Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.white
                                  : const Color(0xFFFAFBFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    nombreProducto,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${detalle.cantidad}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '\$${detalle.costoUnitario.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '\$${detalle.subtotal.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    detalle.fechaCaducidad == null
                                        ? 'Sin caducidad'
                                        : detalle.fechaCaducidad!
                                            .substring(0, 10),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: detalle.fechaCaducidad == null
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: \$${compra.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _CompraChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _CompraChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
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