import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/detalle_venta.dart';
import '../../models/pago_venta.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/venta_provider.dart';
import '../../services/precio_producto_service.dart';
import '../../widgets/ticket_preview_dialog.dart';
import '../../providers/auth_provider.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Nueva venta'),
              Tab(text: 'Historial'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                NuevaVentaView(),
                HistorialVentasView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NuevaVentaView extends StatefulWidget {
  const NuevaVentaView({super.key});

  @override
  State<NuevaVentaView> createState() => _NuevaVentaViewState();
}

class _NuevaVentaViewState extends State<NuevaVentaView> {
  final busquedaController = TextEditingController();
  final pagoController = TextEditingController();
  final precioService = PrecioProductoService();

  final List<_ItemCarrito> carrito = [];

  String tipoVenta = 'CONTADO';
  Cliente? clienteSeleccionado;

  double get total => carrito.fold(0, (sum, item) => sum + item.subtotal);
  double get pagoRecibido => double.tryParse(pagoController.text.trim()) ?? 0;
  double get cambio => pagoRecibido - total;

  @override
  void dispose() {
    busquedaController.dispose();
    pagoController.dispose();
    super.dispose();
  }

Future<void> agregarProducto(Producto producto) async {
  if (producto.stockActual <= 0) {
    _mensaje('Producto sin stock');
    return;
  }

  final index = carrito.indexWhere((item) => item.producto.id == producto.id);

  if (index >= 0) {
    final item = carrito[index];
    final nuevaCantidad = item.cantidad + 1;

    if (nuevaCantidad > producto.stockActual) {
      _mensaje('Stock insuficiente');
      return;
    }

    final nuevoPrecio = await precioService.obtenerPrecioPorCantidad(
      productoId: producto.id!,
      cantidad: nuevaCantidad,
    );

    if (!mounted) return;

    setState(() {
      carrito[index] = item.copyWith(
        cantidad: nuevaCantidad,
        precioUnitario: nuevoPrecio,
      );
    });
    return;
  }

  final precio = await precioService.obtenerPrecioPorCantidad(
    productoId: producto.id!,
    cantidad: 1,
  );

  if (!mounted) return;

  if (precio <= 0) {
    _mensaje('Este producto no tiene precio de venta');
    return;
  }

  setState(() {
    carrito.add(
      _ItemCarrito(
        producto: producto,
        cantidad: 1,
        precioUnitario: precio,
      ),
    );
  });
}

Future<void> aumentarCantidad(int index) async {
  final item = carrito[index];
  final nuevaCantidad = item.cantidad + 1;

  if (nuevaCantidad > item.producto.stockActual) {
    _mensaje('Stock insuficiente');
    return;
  }

  final nuevoPrecio = await precioService.obtenerPrecioPorCantidad(
    productoId: item.producto.id!,
    cantidad: nuevaCantidad,
  );

  if (!mounted) return;

  setState(() {
    carrito[index] = item.copyWith(
      cantidad: nuevaCantidad,
      precioUnitario: nuevoPrecio,
    );
  });
}

  void disminuirCantidad(int index) {
    final item = carrito[index];
    final nuevaCantidad = item.cantidad - 1;

    if (nuevaCantidad <= 0) {
      setState(() => carrito.removeAt(index));
      return;
    }

    setState(() {
      carrito[index] = item.copyWith(cantidad: nuevaCantidad);
    });
  }

Future<void> cambiarCantidadManual(int index, String value) async {
  final nuevaCantidad = double.tryParse(value.trim());

  if (nuevaCantidad == null || nuevaCantidad <= 0) {
    _mensaje('Cantidad inválida');
    return;
  }

  final item = carrito[index];

  if (nuevaCantidad > item.producto.stockActual) {
    _mensaje('Stock insuficiente');
    return;
  }

  final nuevoPrecio = await precioService.obtenerPrecioPorCantidad(
    productoId: item.producto.id!,
    cantidad: nuevaCantidad,
  );

  if (!mounted) return;

  setState(() {
    carrito[index] = item.copyWith(
      cantidad: nuevaCantidad,
      precioUnitario: nuevoPrecio,
    );
  });
}

  void cambiarPrecio(int index, String value) {
    final nuevoPrecio = double.tryParse(value.trim());

    if (nuevoPrecio == null || nuevoPrecio <= 0) {
      _mensaje('Precio inválido');
      return;
    }

    final item = carrito[index];

    setState(() {
      carrito[index] = item.copyWith(precioUnitario: nuevoPrecio);
    });
  }

  Future<void> cobrarVenta() async {
    if (carrito.isEmpty) {
      _mensaje('El carrito está vacío');
      return;
    }

    if (carrito.any((item) => item.precioUnitario <= 0)) {
      _mensaje('Todos los productos deben tener precio mayor a 0');
      return;
    }

    int clienteId = 1;
    List<PagoVenta> pagos = [];

    if (tipoVenta == 'CONTADO') {
      if (pagoRecibido < total) {
        _mensaje('El pago es menor al total');
        return;
      }

      pagos = [
        PagoVenta(
          tipoPago: 'EFECTIVO',
          monto: total,
        ),
      ];
    } else {
      final cliente = clienteSeleccionado;

      if (cliente == null) {
        _mensaje('Selecciona un cliente para fiado');
        return;
      }

      if (!cliente.permiteFiado || cliente.bloqueadoCredito) {
        _mensaje('Este cliente no tiene crédito disponible');
        return;
      }

      final saldoActual = await context
          .read<ClienteProvider>()
          .obtenerSaldoPendiente(cliente.id!);

      if (!mounted) return;

      final disponible = cliente.limiteCredito - saldoActual;

      if (total > disponible) {
        _mensaje(
          'Crédito insuficiente. Disponible: \$${disponible.toStringAsFixed(2)}',
        );
        return;
      }

      clienteId = cliente.id!;
    }

final usuarioActual = context.read<AuthProvider>().usuarioActual;

if (usuarioActual == null || usuarioActual.id == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No hay usuario activo'),
    ),
  );
  return;
}

final venta = Venta(
  clienteId: clienteId,
  usuarioId: usuarioActual.id!,
  tipoVenta: tipoVenta == 'CONTADO' ? 'CONTADO' : 'CREDITO',
  subtotal: total,
  descuento: 0,
  total: total,
  estado: 'COMPLETADA',
  fecha: DateTime.now().toIso8601String(),
);
    final detalles = carrito.map((item) {
      return DetalleVenta(
        productoId: item.producto.id!,
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        descuento: 0,
        subtotal: item.subtotal,
      );
    }).toList();

try {
  final ventaId =
      await context.read<VentaProvider>().registrarVenta(
            venta: venta,
            detalles: detalles,
            pagos: pagos,
          );

  if (!mounted) return;

  await context.read<ProductoProvider>().cargarProductos();
  await context.read<ClienteProvider>().cargarClientes();

  final cambioFinal = cambio;

  setState(() {
    carrito.clear();
    pagoController.clear();
    busquedaController.clear();
    clienteSeleccionado = null;
    tipoVenta = 'CONTADO';
  });

  await showDialog(
    context: context,
    builder: (_) => TicketPreviewDialog(
      ventaId: ventaId,
    ),
  );

  _mensaje(
    venta.tipoVenta == 'CREDITO'
        ? 'Venta fiada registrada correctamente'
        : 'Venta registrada correctamente. Cambio: \$${cambioFinal.toStringAsFixed(2)}',
  );
} catch (e) {
      if (mounted) {
        _mensaje('Error al vender: $e');
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
    final productoProvider = context.watch<ProductoProvider>();
    final productos = productoProvider.productos;
    final clientes = context.watch<ClienteProvider>().clientes.where((c) {
      return c.id != null &&
          c.nombre != 'PUBLICO GENERAL' &&
          c.permiteFiado &&
          !c.bloqueadoCredito;
    }).toList();

    final textoBusqueda = busquedaController.text.trim().toLowerCase();

    final productosFiltrados = textoBusqueda.isEmpty
        ? productos
        : productos.where((producto) {
            return producto.nombre.toLowerCase().contains(textoBusqueda) ||
                (producto.codigoBarras ?? '')
                    .toLowerCase()
                    .contains(textoBusqueda) ||
                (producto.codigoInterno ?? '')
                    .toLowerCase()
                    .contains(textoBusqueda);
          }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nueva venta',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar productos',
                      onPressed: () {
                        context.read<ProductoProvider>().cargarProductos();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: busquedaController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar o escanear producto',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (value) async {
                    final codigo = value.trim();

                    if (codigo.isEmpty) return;

                    final encontrados = productos.where((p) {
                      return p.codigoBarras == codigo ||
                          p.codigoInterno == codigo;
                    }).toList();

                    if (encontrados.isNotEmpty) {
                      await agregarProducto(encontrados.first);
                      busquedaController.clear();
                    } else {
                      _mensaje('Producto no encontrado');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: productosFiltrados.isEmpty
                        ? const Center(child: Text('No hay productos'))
                        : ListView.separated(
                            itemCount: productosFiltrados.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final producto = productosFiltrados[index];

                              return ListTile(
                                title: Text(producto.nombre),
                                subtitle: Text(
                                  'Stock: ${producto.stockActual} | '
                                  'Unidad: ${producto.unidadMedida} | '
                                  'Código: ${producto.codigoBarras ?? producto.codigoInterno ?? 'Sin código'}',
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: producto.stockActual <= 0
                                      ? null
                                      : () => agregarProducto(producto),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar'),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Carrito',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: carrito.isEmpty
                          ? const Center(child: Text('Carrito vacío'))
                          : ListView.separated(
                              itemCount: carrito.length,
                              separatorBuilder: (_, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = carrito[index];

                                return _CarritoTile(
                                  item: item,
                                  onAumentar: () => aumentarCantidad(index),
                                  onDisminuir: () => disminuirCantidad(index),
                                  onCantidadManual: (value) =>
                                      cambiarCantidadManual(index, value),
                                  onPrecioManual: (value) =>
                                      cambiarPrecio(index, value),
                                  onEliminar: () {
                                    setState(() => carrito.removeAt(index));
                                  },
                                );
                              },
                            ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: tipoVenta,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de venta',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'CONTADO',
                                child: Text('Contado / efectivo'),
                              ),
                              DropdownMenuItem(
                                value: 'CREDITO',
                                child: Text('Fiado / crédito'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                tipoVenta = value;
                                pagoController.clear();
                                clienteSeleccionado = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (tipoVenta == 'CREDITO') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Cliente?>(
                        initialValue: clienteSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Cliente',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<Cliente?>(
                            value: null,
                            child: Text('Seleccionar cliente'),
                          ),
                          ...clientes.map(
                            (c) => DropdownMenuItem<Cliente?>(
                              value: c,
                              child: Text(
                                '${c.nombre} | Límite: \$${c.limiteCredito.toStringAsFixed(2)}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => clienteSeleccionado = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: \$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (tipoVenta == 'CONTADO') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: pagoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pago recibido',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          cambio >= 0
                              ? 'Cambio: \$${cambio.toStringAsFixed(2)}'
                              : 'Faltan: \$${(cambio * -1).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cambio >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: cobrarVenta,
                        icon: const Icon(Icons.point_of_sale),
                        label: Text(
                          tipoVenta == 'CREDITO'
                              ? 'Guardar fiado'
                              : 'Cobrar venta',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
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

class HistorialVentasView extends StatelessWidget {
  const HistorialVentasView({super.key});

  @override
  Widget build(BuildContext context) {
    final ventaProvider = context.watch<VentaProvider>();
    final productos = context.watch<ProductoProvider>().productos;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historial de ventas',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () {
                  context.read<VentaProvider>().cargarVentas();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ventaProvider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: ventaProvider.ventas.isEmpty
                        ? const Center(child: Text('No hay ventas registradas'))
                        : ListView.separated(
                            itemCount: ventaProvider.ventas.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final venta = ventaProvider.ventas[index];

                              return ListTile(
                                leading: const Icon(Icons.receipt_long),
                                title: Text('Venta #${venta.id}'),
                                subtitle: Text(
                                  'Fecha: ${venta.fecha.substring(0, 10)} | '
                                  'Tipo: ${venta.tipoVenta} | '
                                  'Estado: ${venta.estado}',
                                ),
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      '\$${venta.total.toStringAsFixed(2)}',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    const SizedBox(width: 8),
    IconButton(
      tooltip: 'Ver ticket',
      icon: const Icon(Icons.receipt),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => TicketPreviewDialog(
            ventaId: venta.id!,
          ),
        );
      },
    ),
  ],
),
                                onTap: () => _mostrarDetalleVenta(
                                  context,
                                  venta,
                                  productos,
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleVenta(
    BuildContext context,
    Venta venta,
    List<Producto> productos,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Detalle venta #${venta.id}'),
          content: SizedBox(
            width: 700,
            child: FutureBuilder<List<DetalleVenta>>(
              future: context.read<VentaProvider>().obtenerDetallesVenta(
                    venta.id!,
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
                  return const Text('Esta venta no tiene detalles.');
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...detalles.map((detalle) {
                      final encontrados = productos
                          .where((p) => p.id == detalle.productoId)
                          .toList();

                      final nombreProducto = encontrados.isEmpty
                          ? 'Producto #${detalle.productoId}'
                          : encontrados.first.nombre;

                      return ListTile(
                        title: Text(nombreProducto),
                        subtitle: Text(
                          'Cantidad: ${detalle.cantidad} | '
                          'Precio: \$${detalle.precioUnitario.toStringAsFixed(2)}',
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
                        'Total: \$${venta.total.toStringAsFixed(2)}',
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

class _CarritoTile extends StatefulWidget {
  final _ItemCarrito item;
  final VoidCallback onAumentar;
  final VoidCallback onDisminuir;
  final ValueChanged<String> onCantidadManual;
  final ValueChanged<String> onPrecioManual;
  final VoidCallback onEliminar;

  const _CarritoTile({
    required this.item,
    required this.onAumentar,
    required this.onDisminuir,
    required this.onCantidadManual,
    required this.onPrecioManual,
    required this.onEliminar,
  });

  @override
  State<_CarritoTile> createState() => _CarritoTileState();
}

class _CarritoTileState extends State<_CarritoTile> {
  late TextEditingController cantidadController;
  late TextEditingController precioController;

  @override
  void initState() {
    super.initState();
    cantidadController = TextEditingController(
      text: widget.item.cantidad.toString(),
    );
    precioController = TextEditingController(
      text: widget.item.precioUnitario.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant _CarritoTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.cantidad != widget.item.cantidad) {
      cantidadController.text = widget.item.cantidad.toString();
    }

    if (oldWidget.item.precioUnitario != widget.item.precioUnitario) {
      precioController.text = widget.item.precioUnitario.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    cantidadController.dispose();
    precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.item.producto.nombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock disponible: ${widget.item.producto.stockActual} | '
            'Unidad: ${widget.item.producto.unidadMedida}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                onPressed: widget.onDisminuir,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cant.',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: widget.onCantidadManual,
                ),
              ),
              IconButton(
                onPressed: widget.onAumentar,
                icon: const Icon(Icons.add_circle_outline),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: precioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: widget.onPrecioManual,
                ),
              ),
              Text(
                'Subtotal: \$${widget.item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: widget.onEliminar,
      ),
    );
  }
}

class _ItemCarrito {
  final Producto producto;
  final double cantidad;
  final double precioUnitario;

  _ItemCarrito({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  _ItemCarrito copyWith({
    Producto? producto,
    double? cantidad,
    double? precioUnitario,
  }) {
    return _ItemCarrito(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }
}