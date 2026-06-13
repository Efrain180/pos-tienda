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
import '../../models/presentacion_producto.dart';
import '../../services/presentacion_producto_service.dart';
import '../../providers/configuracion_provider.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        color: const Color(0xFFF4F6F8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  TabBar(
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.point_of_sale),
                        text: 'Nueva venta',
                      ),
                      Tab(
                        icon: Icon(Icons.receipt_long),
                        text: 'Historial',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  NuevaVentaView(),
                  HistorialVentasView(),
                ],
              ),
            ),
          ],
        ),
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
  final presentacionService = PresentacionProductoService();

  final List<_ItemCarrito> carrito = [];
  List<Producto> productosBusqueda = [];
bool buscandoProductos = false;

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
  cantidadReal: nuevaCantidad,
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
    presentacion: null,
    cantidad: 1,
    cantidadReal: 1,
    precioUnitario: precio,
  ),
);
  });
}

Future<void> buscarProductosVenta() async {
  final texto = busquedaController.text.trim();

  if (texto.isEmpty) {
    setState(() => productosBusqueda = []);
    return;
  }

  setState(() => buscandoProductos = true);

  final encontrados = await context
      .read<ProductoProvider>()
      .buscarProductosParaVenta(texto, limit: 30);

  if (!mounted) return;

  setState(() {
    productosBusqueda = encontrados;
    buscandoProductos = false;
  });
}
Future<void> _seleccionarPresentacionOAgregar(
  BuildContext context,
  Producto producto,
) async {
  final presentaciones =
      await presentacionService.obtenerPresentacionesProducto(producto.id!);

  if (!mounted) return;

  if (presentaciones.isEmpty) {
    await agregarProducto(producto);
    return;
  }

  final seleccion = await showDialog<PresentacionProducto>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Presentación - ${producto.nombre}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: presentaciones.map((presentacion) {
              return ListTile(
                title: Text(presentacion.nombre),
                subtitle: Text(
                  'Factor: ${presentacion.factorConversion} | '
                  'Precio: \$${presentacion.precio.toStringAsFixed(2)}',
                ),
                onTap: () {
                  Navigator.pop(dialogContext, presentacion);
                },
              );
            }).toList(),
          ),
        ),
      );
    },
  );

  if (seleccion == null) return;

  await agregarPresentacion(producto, seleccion);
}

Future<void> agregarPresentacion(
  Producto producto,
  PresentacionProducto presentacion,
) async {
  if (producto.stockActual < presentacion.factorConversion) {
    _mensaje('Stock insuficiente');
    return;
  }

  final index = carrito.indexWhere(
    (item) =>
        item.producto.id == producto.id &&
        item.presentacion?.id == presentacion.id,
  );

  if (index >= 0) {
    final item = carrito[index];
    final nuevaCantidad = item.cantidad + 1;
    final nuevaCantidadReal =
        nuevaCantidad * presentacion.factorConversion;

    if (nuevaCantidadReal > producto.stockActual) {
      _mensaje('Stock insuficiente');
      return;
    }

    setState(() {
      carrito[index] = item.copyWith(
        cantidad: nuevaCantidad,
        cantidadReal: nuevaCantidadReal,
        precioUnitario: presentacion.precio,
      );
    });

    return;
  }

  setState(() {
    carrito.add(
      _ItemCarrito(
        producto: producto,
        presentacion: presentacion,
        cantidad: 1,
        cantidadReal: presentacion.factorConversion,
        precioUnitario: presentacion.precio,
      ),
    );
  });
}

Future<void> aumentarCantidad(int index) async {
  final item = carrito[index];

  final nuevaCantidad = item.cantidad + 1;

  if (item.presentacion != null) {
    final nuevaCantidadReal =
        nuevaCantidad * item.presentacion!.factorConversion;

    if (nuevaCantidadReal > item.producto.stockActual) {
      _mensaje('Stock insuficiente');
      return;
    }

    setState(() {
      carrito[index] = item.copyWith(
        cantidad: nuevaCantidad,
        cantidadReal: nuevaCantidadReal,
        precioUnitario: item.presentacion!.precio,
      );
    });

    return;
  }

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
  cantidadReal: nuevaCantidad,
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
      carrito[index] = item.copyWith(
  cantidad: nuevaCantidad,
  cantidadReal: item.presentacion == null
      ? nuevaCantidad
      : nuevaCantidad * item.presentacion!.factorConversion,
);
    });
  }

Future<void> cambiarCantidadManual(int index, String value) async {
  final nuevaCantidad = double.tryParse(value.trim());

  if (nuevaCantidad == null || nuevaCantidad <= 0) {
    _mensaje('Cantidad inválida');
    return;
  }

  final item = carrito[index];

  if (item.presentacion != null) {
    final nuevaCantidadReal =
        nuevaCantidad * item.presentacion!.factorConversion;

    if (nuevaCantidadReal > item.producto.stockActual) {
      _mensaje('Stock insuficiente');
      return;
    }

    setState(() {
      carrito[index] = item.copyWith(
        cantidad: nuevaCantidad,
        cantidadReal: nuevaCantidadReal,
        precioUnitario: item.presentacion!.precio,
      );
    });

    return;
  }

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
      if (!context.read<ConfiguracionProvider>().configuracion!.usaFiados) {
  _mensaje('Las ventas fiadas están desactivadas en configuración');
  return;
}

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

    // Para inventario/FIFO.
    cantidad: item.cantidadReal,

    // Para ticket/detalle.
    cantidadMostrada: item.cantidad,
    nombrePresentacion: item.presentacion?.nombre,
    factorConversion: item.presentacion?.factorConversion,

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

  final config = context.watch<ConfiguracionProvider>().configuracion;
final fiadosActivos = config?.usaFiados ?? true;

  final clientes = context.watch<ClienteProvider>().clientes.where((c) {
    return c.id != null &&
        c.nombre != 'PUBLICO GENERAL' &&
        c.permiteFiado &&
        !c.bloqueadoCredito;
  }).toList();

final productosFiltrados = productosBusqueda;

  return Padding(
    padding: const EdgeInsets.all(24),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 900;

        final contenido = [
          Expanded(
            flex: 4,
            child: _PanelProductos(
              busquedaController: busquedaController,
              productosFiltrados: productosFiltrados,
              onBuscarCambio: buscarProductosVenta,
              onActualizar: () {
                context.read<ProductoProvider>().cargarProductos();
              },
              onAgregar: (producto) {
                _seleccionarPresentacionOAgregar(context, producto);
              },
onSubmitted: (value) async {
  final codigo = value.trim();

  if (codigo.isEmpty) return;

  final presentacion = await presentacionService.obtenerPorCodigo(codigo);

  if (!mounted) return;

  if (presentacion != null) {
    final producto = await context
        .read<ProductoProvider>()
        .obtenerProductoPorId(presentacion.productoId);

    if (!mounted) return;

    if (producto == null) {
      _mensaje('Producto de la presentación no encontrado');
      return;
    }

    await agregarPresentacion(producto, presentacion);

    busquedaController.clear();
    setState(() => productosBusqueda = []);
    return;
  }

  final encontrados = await context
      .read<ProductoProvider>()
      .buscarProductosParaVenta(codigo, limit: 20);

  if (!mounted) return;

  final exactos = encontrados.where((p) {
    return p.codigoBarras == codigo || p.codigoInterno == codigo;
  }).toList();

  if (exactos.isNotEmpty) {
    await _seleccionarPresentacionOAgregar(context, exactos.first);

    busquedaController.clear();
    setState(() => productosBusqueda = []);
    return;
  }

  if (encontrados.length == 1) {
    await _seleccionarPresentacionOAgregar(context, encontrados.first);

    busquedaController.clear();
    setState(() => productosBusqueda = []);
    return;
  }

  _mensaje('Producto no encontrado');
},
            ),
          ),
          const SizedBox(width: 20, height: 20),
          Expanded(
            flex: 7,
            child: _PanelCarrito(
              carrito: carrito,
              total: total,
              cambio: cambio,
              tipoVenta: tipoVenta,
              pagoController: pagoController,
              clienteSeleccionado: clienteSeleccionado,
              clientes: clientes,
              fiadosActivos: fiadosActivos,
              onAumentar: aumentarCantidad,
              onDisminuir: disminuirCantidad,
              onCantidadManual: cambiarCantidadManual,
              onPrecioManual: cambiarPrecio,
              onEliminar: (index) {
                setState(() => carrito.removeAt(index));
              },
              onTipoVentaChanged: (value) {
                if (value == null) return;
                setState(() {
                  tipoVenta = value;
                  pagoController.clear();
                  clienteSeleccionado = null;
                });
              },
              onClienteChanged: (value) {
                setState(() => clienteSeleccionado = value);
              },
              onPagoChanged: () => setState(() {}),
              onCobrar: cobrarVenta,
            ),
          ),
        ];

if (compacto) {
  return SingleChildScrollView(
    child: SizedBox(
      height: constraints.maxHeight + 260,
      child: Column(
        children: [
          contenido[0],
          contenido[1],
          contenido[2],
        ],
      ),
    ),
  );
}

        return Row(children: contenido);
      },
    ),
  );
}
}
class _PanelProductos extends StatelessWidget {
  final TextEditingController busquedaController;
  final List<Producto> productosFiltrados;
  final VoidCallback onBuscarCambio;
  final VoidCallback onActualizar;
  final ValueChanged<Producto> onAgregar;
  final ValueChanged<String> onSubmitted;


  const _PanelProductos({
    required this.busquedaController,
    required this.productosFiltrados,
    required this.onBuscarCambio,
    required this.onActualizar,
    required this.onAgregar,
    required this.onSubmitted,

  });

  @override
  Widget build(BuildContext context) {
    final hayBusqueda = busquedaController.text.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Buscar producto',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar productos',
                  onPressed: onActualizar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: busquedaController,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Escanear o buscar',
                hintText: 'Código, nombre o código interno',
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => onBuscarCambio(),
              onSubmitted: onSubmitted,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !hayBusqueda
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 52,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Escanea un código o escribe para buscar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Los productos aparecerán aquí conforme busques',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : productosFiltrados.isEmpty
                      ? const Center(child: Text('No se encontraron productos'))
                      : ListView.separated(
                          itemCount: productosFiltrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final producto = productosFiltrados[index];
                            final sinStock = producto.stockActual <= 0;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: sinStock
                                    ? Colors.red.withOpacity(0.04)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sinStock
                                      ? Colors.red.withOpacity(0.25)
                                      : Colors.grey.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: sinStock
                                        ? Colors.red.withOpacity(0.12)
                                        : Colors.green.withOpacity(0.12),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color:
                                          sinStock ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          producto.nombre,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stock: ${producto.stockActual} • ${producto.unidadMedida}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          producto.codigoBarras ??
                                              producto.codigoInterno ??
                                              'Sin código',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: sinStock
                                        ? null
                                        : () => onAgregar(producto),
                                    icon: const Icon(Icons.add),
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
    );
  }
}
class _PanelCarrito extends StatefulWidget {
  final List<_ItemCarrito> carrito;
  final double total;
  final double cambio;
  final String tipoVenta;
  final TextEditingController pagoController;
  final Cliente? clienteSeleccionado;
  final List<Cliente> clientes;
  final Future<void> Function(int index) onAumentar;
  final void Function(int index) onDisminuir;
  final Future<void> Function(int index, String value) onCantidadManual;
  final void Function(int index, String value) onPrecioManual;
  final void Function(int index) onEliminar;
  final ValueChanged<String?> onTipoVentaChanged;
  final ValueChanged<Cliente?> onClienteChanged;
  final VoidCallback onPagoChanged;
  final VoidCallback onCobrar;
  final bool fiadosActivos;

  const _PanelCarrito({
    required this.carrito,
    required this.total,
    required this.cambio,
    required this.tipoVenta,
    required this.pagoController,
    required this.clienteSeleccionado,
    required this.clientes,
    required this.onAumentar,
    required this.onDisminuir,
    required this.onCantidadManual,
    required this.onPrecioManual,
    required this.onEliminar,
    required this.onTipoVentaChanged,
    required this.onClienteChanged,
    required this.onPagoChanged,
    required this.onCobrar,
    required this.fiadosActivos,
  });

  @override
  State<_PanelCarrito> createState() => _PanelCarritoState();
}

class _PanelCarritoState extends State<_PanelCarrito> {
  int? indexSeleccionado;
  final cantidadController = TextEditingController();
  final precioController = TextEditingController();

  @override
  void dispose() {
    cantidadController.dispose();
    precioController.dispose();
    super.dispose();
  }

  void _seleccionar(int index) {
    final item = widget.carrito[index];

    setState(() {
      indexSeleccionado = index;
      cantidadController.text = item.cantidad.toString();
      precioController.text = item.precioUnitario.toStringAsFixed(2);
    });
  }
  void _actualizarCamposSeleccionados() {
  if (indexSeleccionado == null) return;
  if (indexSeleccionado! >= widget.carrito.length) return;

  final item = widget.carrito[indexSeleccionado!];

  cantidadController.text = item.cantidad.toString();
  precioController.text = item.precioUnitario.toStringAsFixed(2);
}

  @override
  Widget build(BuildContext context) {
    final esCredito = widget.tipoVenta == 'CREDITO';

    if (indexSeleccionado != null &&
        indexSeleccionado! >= widget.carrito.length) {
      indexSeleccionado = null;
    }

    final itemSeleccionado = indexSeleccionado == null
        ? null
        : widget.carrito[indexSeleccionado!];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Carrito (${widget.carrito.length})',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Producto',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Cant.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Precio',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Expanded(
              child: widget.carrito.isEmpty
                  ? const Center(
                      child: Text(
                        'Carrito vacío',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: widget.carrito.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = widget.carrito[index];
                        final seleccionado = indexSeleccionado == index;

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _seleccionar(index),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.10)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: seleccionado
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.45)
                                    : Colors.grey.withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    item.nombreMostrar,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.cantidad.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${item.precioUnitario.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${item.subtotal.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
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

            if (itemSeleccionado != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemSeleccionado.nombreMostrar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
onPressed: () {
  widget.onDisminuir(indexSeleccionado!);
  _actualizarCamposSeleccionados();
},
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: cantidadController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cant.',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          widget.onCantidadManual(indexSeleccionado!, value);
                        },
                      ),
                    ),
                    IconButton(
onPressed: () async {
  await widget.onAumentar(indexSeleccionado!);
  _actualizarCamposSeleccionados();
},
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: precioController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          prefixText: '\$ ',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          widget.onPrecioManual(indexSeleccionado!, value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: () {
                        final index = indexSeleccionado!;
                        setState(() => indexSeleccionado = null);
                        widget.onEliminar(index);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.tipoVenta,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Venta',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
items: [
  const DropdownMenuItem(
    value: 'CONTADO',
    child: Text('Contado'),
  ),
  DropdownMenuItem(
    value: 'CREDITO',
    enabled: widget.fiadosActivos,
    child: Text(
      widget.fiadosActivos ? 'Fiado' : 'Fiado desactivado',
      overflow: TextOverflow.ellipsis,
    ),
  ),
],
                      onChanged: widget.onTipoVentaChanged,
                    ),
                  ),

                  if (!esCredito)
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: widget.pagoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Pago',
                          prefixText: '\$ ',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => widget.onPagoChanged(),
                      ),
                    ),

                  if (esCredito)
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<Cliente?>(
                        initialValue: widget.clienteSeleccionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Cliente',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<Cliente?>(
                            value: null,
                            child: Text('Seleccionar'),
                          ),
                          ...widget.clientes.map(
                            (c) => DropdownMenuItem<Cliente?>(
                              value: c,
                              child: Text(
                                c.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: widget.onClienteChanged,
                      ),
                    ),

                  SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CAMBIO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          esCredito
    ? '-'
    : widget.cambio < 0
        ? 'Pago insuficiente'
        : '\$${widget.cambio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
color: esCredito
    ? Colors.grey
    : widget.cambio < 0
        ? Colors.red
        : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '\$${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: widget.onCobrar,
                      icon: const Icon(Icons.point_of_sale),
                      label: Text(
                        esCredito ? 'Guardar' : 'Cobrar',
                        style: const TextStyle(fontSize: 18),
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

class _ResumenRow extends StatelessWidget {
  final String label;
  final String value;
  final bool grande;
  final Color? color;

  const _ResumenRow({
    required this.label,
    required this.value,
    this.grande = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: grande ? 18 : 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: grande ? 30 : 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class HistorialVentasView extends StatefulWidget {
  const HistorialVentasView({super.key});

  @override
  State<HistorialVentasView> createState() => _HistorialVentasViewState();
}

class _HistorialVentasViewState extends State<HistorialVentasView> {
  final busquedaController = TextEditingController();

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final ventaProvider = context.watch<VentaProvider>();
    final productos = context.watch<ProductoProvider>().productos;
    final ventas = ventaProvider.ventas;

    final totalVendido = ventas.fold<double>(
      0,
      (sum, venta) => sum + venta.total,
    );

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Historial de ventas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _HistorialResumenCard(
                label: 'Ventas',
                value: ventas.length.toString(),
              ),
              const SizedBox(width: 10),
              _HistorialResumenCard(
                label: 'Total',
                value: '\$${totalVendido.toStringAsFixed(2)}',
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Actualizar',
                onPressed: () {
                  context.read<VentaProvider>().cargarVentas();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
const SizedBox(height: 12),

Row(
  children: [
    Expanded(
      child: TextField(
        controller: busquedaController,
        decoration: InputDecoration(
          labelText: 'Buscar por # venta, cliente o tipo',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (value) {
          context.read<VentaProvider>().cargarVentas(
                busqueda: value,
              );
        },
      ),
    ),
    const SizedBox(width: 10),
    FilledButton.icon(
      onPressed: () {
        context.read<VentaProvider>().cargarVentas(
              busqueda: busquedaController.text,
            );
      },
      icon: const Icon(Icons.search),
      label: const Text('Buscar'),
    ),
    const SizedBox(width: 10),
    OutlinedButton.icon(
      onPressed: () {
        busquedaController.clear();
        context.read<VentaProvider>().cargarVentas();
      },
      icon: const Icon(Icons.clear),
      label: const Text('Limpiar'),
    ),
  ],
),
          const SizedBox(height: 14),

          Expanded(
            child: ventaProvider.cargando
                ? const Center(child: CircularProgressIndicator())
                : ventas.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay ventas registradas',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
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
                                height: 40,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF2F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'Venta',
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
                                        'Tipo',
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
                                    SizedBox(width: 96),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              Expanded(
                                child: ListView.separated(
                                  itemCount: ventas.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final venta = ventas[index];

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _mostrarDetalleVenta(
                                        context,
                                        venta,
                                        productos,
                                      ),
                                      child: Container(
                                        height: 52,
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
                                                '#${venta.id}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatearFecha(venta.fecha),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: _ChipVenta(
                                                  texto: venta.tipoVenta ==
                                                          'CREDITO'
                                                      ? 'Fiado'
                                                      : 'Contado',
                                                  color: venta.tipoVenta ==
                                                          'CREDITO'
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: _ChipVenta(
                                                  texto: venta.estado,
                                                  color: venta.estado ==
                                                          'COMPLETADA'
                                                      ? Colors.blue
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '\$${venta.total.toStringAsFixed(2)}',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              tooltip: 'Ver ticket',
                                              icon: const Icon(Icons.receipt),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      TicketPreviewDialog(
                                                    ventaId: venta.id!,
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              tooltip: 'Detalle',
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                              ),
                                              onPressed: () =>
                                                  _mostrarDetalleVenta(
                                                context,
                                                venta,
                                                productos,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                              ),
                              if (ventaProvider.hayMas) ...[
  const SizedBox(height: 10),
  SizedBox(
    width: double.infinity,
    height: 44,
    child: OutlinedButton.icon(
      onPressed: ventaProvider.cargandoMas
          ? null
          : () {
              context.read<VentaProvider>().cargarMasVentas();
            },
      icon: ventaProvider.cargandoMas
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.expand_more),
      label: Text(
        ventaProvider.cargandoMas
            ? 'Cargando...'
            : 'Cargar más ventas',
      ),
    ),
  ),
],
                            ],
                            
                          ),
                        ),
                      ),
          ),
        ],
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

  void _mostrarDetalleVenta(
    BuildContext context,
    Venta venta,
    List<Producto> productos,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              const Icon(Icons.receipt_long),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Detalle venta #${venta.id}'),
              ),
              Text(
                '\$${venta.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 780,
            child: FutureBuilder<List<DetalleVenta>>(
              future: context.read<VentaProvider>().obtenerDetallesVenta(
                    venta.id!,
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
                      child: Text('Esta venta no tiene detalles.'),
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
                            flex: 5,
                            child: Text(
                              'Producto',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Cantidad',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Precio',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Subtotal',
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final detalle = detalles[index];

                          final encontrados = productos
                              .where((p) => p.id == detalle.productoId)
                              .toList();

                          final nombreBase = encontrados.isEmpty
    ? 'Producto #${detalle.productoId}'
    : encontrados.first.nombre;

final nombreProducto =
    detalle.textoPresentacion.isEmpty
        ? nombreBase
        : '$nombreBase - ${detalle.textoPresentacion}';

                          return Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
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
                                  flex: 5,
                                  child: Text(
                                    nombreProducto,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    detalle.cantidadParaMostrar.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${detalle.precioUnitario.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${detalle.subtotal.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
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
                        'Total: \$${venta.total.toStringAsFixed(2)}',
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
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => TicketPreviewDialog(
                    ventaId: venta.id!,
                  ),
                );
              },
              icon: const Icon(Icons.receipt),
              label: const Text('Ver ticket'),
            ),
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

class _HistorialResumenCard extends StatelessWidget {
  final String label;
  final String value;

  const _HistorialResumenCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
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

class _ChipVenta extends StatelessWidget {
  final String texto;
  final Color color;

  const _ChipVenta({
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}


class _ItemCarrito {
  final Producto producto;
  final PresentacionProducto? presentacion;
  final double cantidad;
  final double cantidadReal;
  final double precioUnitario;

  _ItemCarrito({
    required this.producto,
    this.presentacion,
    required this.cantidad,
    required this.cantidadReal,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  String get nombreMostrar {
    if (presentacion == null) return producto.nombre;
    return '${producto.nombre} - ${presentacion!.nombre}';
  }

  _ItemCarrito copyWith({
    Producto? producto,
    PresentacionProducto? presentacion,
    double? cantidad,
    double? cantidadReal,
    double? precioUnitario,
  }) {
    return _ItemCarrito(
      producto: producto ?? this.producto,
      presentacion: presentacion ?? this.presentacion,
      cantidad: cantidad ?? this.cantidad,
      cantidadReal: cantidadReal ?? this.cantidadReal,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }
}