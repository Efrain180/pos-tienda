import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/producto.dart';
import '../../../providers/categoria_provider.dart';
import '../../../providers/configuracion_provider.dart';
import '../../../providers/marca_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../services/precio_producto_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/precio_producto.dart';

class ProductosView extends StatelessWidget {
  const ProductosView({super.key});

  static const unidades = [
    'PIEZA',
    'CAJA',
    'PAQUETE',
    'BOLSA',
    'KILO',
    'GRAMO',
    'LITRO',
    'MILILITRO',
    'METRO',
    'CENTIMETRO',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Productos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormularioProducto(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre, código de barras o código interno',
              border: OutlineInputBorder(),
            ),
            onChanged: provider.buscarProductos,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: provider.productos.isEmpty
                        ? const Center(
                            child: Text('No hay productos registrados'),
                          )
                        : ListView.separated(
                            itemCount: provider.productos.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final producto = provider.productos[index];

                              return ListTile(
                                title: Text(producto.nombre),
                                subtitle: Text(
                                  'Código: ${producto.codigoBarras ?? producto.codigoInterno ?? 'Sin código'} | '
                                  'Unidad: ${producto.unidadMedida} | '
                                  'Stock: ${producto.stockActual}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(label: Text(producto.estado)),
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _mostrarFormularioProducto(
                                        context,
                                        producto: producto,
                                      ),
                                    ),
                                  ],
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

Future<void> _mostrarFormularioProducto(
  BuildContext context, {
  Producto? producto,
}) async {
  final categoriasOriginales = context.read<CategoriaProvider>().categorias;
  final marcasOriginales = context.read<MarcaProvider>().marcas;

  final categorias = {
    for (final categoria in categoriasOriginales)
      if (categoria.id != null) categoria.id!: categoria,
  }.values.toList();

  final marcas = {
    for (final marca in marcasOriginales)
      if (marca.id != null) marca.id!: marca,
  }.values.toList();

  final precioService = PrecioProductoService();

  List<PrecioProducto> precios = [];

  if (producto?.id != null) {
    precios = await precioService.obtenerPreciosProducto(producto!.id!);
  }

  double ultimoCosto = 0;

 final productoId = producto?.id;

if (productoId != null) {
  ultimoCosto = await precioService.obtenerUltimoCosto(productoId);
}

  if (!context.mounted) return;

  final margenConfigurado =
      context.read<ConfiguracionProvider>().configuracion?.margenGananciaDefault ??
          25;

  final codigoBarrasController =
      TextEditingController(text: producto?.codigoBarras ?? '');
  final codigoInternoController =
      TextEditingController(text: producto?.codigoInterno ?? '');
  final nombreController = TextEditingController(text: producto?.nombre ?? '');
  final descripcionController =
      TextEditingController(text: producto?.descripcion ?? '');
  final stockMinimoController =
      TextEditingController(text: producto?.stockMinimo.toString() ?? '0');

  final costoBaseController = TextEditingController(
    text: ultimoCosto == 0 ? '' : ultimoCosto.toStringAsFixed(2),
  );

  final precioRecomendadoController = TextEditingController();
  final gananciaUnidadController = TextEditingController();
  final margenRealController = TextEditingController();

  final tipoPrecioController = TextEditingController();
  final cantidadMinimaController = TextEditingController(text: '1');
  final precioNuevoController = TextEditingController();

  int? categoriaId = producto?.categoriaId;
  int? marcaId = producto?.marcaId;

  if (!categorias.any((c) => c.id == categoriaId)) {
    categoriaId = null;
  }

  if (!marcas.any((m) => m.id == marcaId)) {
    marcaId = null;
  }

  String unidadMedida = unidades.contains(producto?.unidadMedida)
      ? producto!.unidadMedida
      : 'PIEZA';

  String estado =
      ['ACTIVO', 'INACTIVO', 'DESCONTINUADO'].contains(producto?.estado)
          ? producto!.estado
          : 'ACTIVO';

  void recalcular() {
    final costo = double.tryParse(costoBaseController.text.trim()) ?? 0;

    if (costo > 0 && margenConfigurado < 100) {
      final recomendado = costo / (1 - (margenConfigurado / 100));
      final ganancia = recomendado - costo;
      final margenReal = (ganancia / recomendado) * 100;

      precioRecomendadoController.text = recomendado.toStringAsFixed(2);
      gananciaUnidadController.text = ganancia.toStringAsFixed(2);
      margenRealController.text = margenReal.toStringAsFixed(2);
    } else {
      precioRecomendadoController.clear();
      gananciaUnidadController.clear();
      margenRealController.clear();
    }
  }

  recalcular();

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(
              producto == null ? 'Nuevo producto' : 'Editar producto',
            ),
            content: SizedBox(
              width: 780,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codigoBarrasController,
                            decoration: const InputDecoration(
                              labelText: 'Código de barras',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: codigoInternoController,
                            decoration: const InputDecoration(
                              labelText: 'Código interno',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto',
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
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: categoriaId,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sin categoría'),
                              ),
                              ...categorias.map(
                                (c) => DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text(c.nombre),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => categoriaId = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: marcaId,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sin marca'),
                              ),
                              ...marcas.map(
                                (m) => DropdownMenuItem<int?>(
                                  value: m.id,
                                  child: Text(m.nombre),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => marcaId = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: unidadMedida,
                            decoration: const InputDecoration(
                              labelText: 'Unidad de medida',
                              border: OutlineInputBorder(),
                            ),
                            items: unidades
                                .map(
                                  (u) => DropdownMenuItem<String>(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => unidadMedida = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockMinimoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock mínimo',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: estado,
                            decoration: const InputDecoration(
                              labelText: 'Estado',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'ACTIVO',
                                child: Text('ACTIVO'),
                              ),
                              DropdownMenuItem(
                                value: 'INACTIVO',
                                child: Text('INACTIVO'),
                              ),
                              DropdownMenuItem(
                                value: 'DESCONTINUADO',
                                child: Text('DESCONTINUADO'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => estado = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recomendación de precio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costoBaseController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Costo base / último costo',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setState(() {
                                recalcular();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: precioRecomendadoController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Precio recomendado por unidad',
                              helperText:
                                  'Margen configurado: $margenConfigurado%',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: gananciaUnidadController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Ganancia por unidad recomendada',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: margenRealController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Margen recomendado (%)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Agregar precio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tipoPrecioController,
                            decoration: const InputDecoration(
                              labelText: 'Tipo precio',
                              hintText: 'MENUDEO, MAYOREO, CAJA...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: cantidadMinimaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad mínima',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: precioNuevoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio unitario',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            final tipo =
                                tipoPrecioController.text.trim().toUpperCase();
                            final cantidad = double.tryParse(
                                  cantidadMinimaController.text.trim(),
                                ) ??
                                0;
                            final precio = double.tryParse(
                                  precioNuevoController.text.trim(),
                                ) ??
                                0;

                            if (tipo.isEmpty || cantidad <= 0 || precio <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Completa tipo, cantidad y precio',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              precios.removeWhere(
                                (p) => p.tipoPrecio == tipo,
                              );

                              precios.add(
                                PrecioProducto(
                                  productoId: producto?.id ?? 0,
                                  tipoPrecio: tipo,
                                  cantidadMinima: cantidad,
                                  precio: precio,
                                ),
                              );

                              precios.sort(
                                (a, b) => a.cantidadMinima.compareTo(
                                  b.cantidadMinima,
                                ),
                              );

                              tipoPrecioController.clear();
                              cantidadMinimaController.text = '1';
                              precioNuevoController.clear();
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Precios asignados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (precios.isEmpty)
                      const Text('No hay precios agregados'),

                    ...precios.map((precio) {
                      final costoBase =
                          double.tryParse(costoBaseController.text.trim()) ??
                              0;

                      final ventaTotal =
                          precio.precio * precio.cantidadMinima;
                      final costoTotal =
                          costoBase * precio.cantidadMinima;
                      final ganancia = ventaTotal - costoTotal;
                      final margen =
                          ventaTotal > 0 ? (ganancia / ventaTotal) * 100 : 0;

                      return Card(
                        child: ListTile(
                          title: Text(precio.tipoPrecio),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desde ${precio.cantidadMinima} unidad(es)',
                              ),
                              Text(
                                'Precio unitario: \$${precio.precio.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Venta total: \$${ventaTotal.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Costo total: \$${costoTotal.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Ganancia: \$${ganancia.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Margen: ${margen.toStringAsFixed(2)}%',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                precios.remove(precio);
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nombre = nombreController.text.trim();

                  if (nombre.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'El nombre del producto es obligatorio',
                        ),
                      ),
                    );
                    return;
                  }

                  if (precios.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Agrega al menos un precio'),
                      ),
                    );
                    return;
                  }

                  if (!precios.any((p) => p.cantidadMinima <= 1)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debe existir un precio desde cantidad 1',
                        ),
                      ),
                    );
                    return;
                  }

                  final stockMinimo =
                      double.tryParse(stockMinimoController.text.trim()) ?? 0;

                  final nuevoProducto = Producto(
                    id: producto?.id,
                    codigoBarras:
                        codigoBarrasController.text.trim().isEmpty
                            ? null
                            : codigoBarrasController.text.trim(),
                    codigoInterno:
                        codigoInternoController.text.trim().isEmpty
                            ? null
                            : codigoInternoController.text.trim(),
                    nombre: nombre,
                    descripcion:
                        descripcionController.text.trim().isEmpty
                            ? null
                            : descripcionController.text.trim(),
                    categoriaId: categoriaId,
                    marcaId: marcaId,
                    stockActual: producto?.stockActual ?? 0,
                    unidadMedida: unidadMedida,
                    stockMinimo: stockMinimo,
                    estado: estado,
                    fechaCreacion: producto?.fechaCreacion ??
                        DateTime.now().toIso8601String(),
                    fechaActualizacion: DateTime.now().toIso8601String(),
                  );

                  final productoProvider = context.read<ProductoProvider>();
                  final usuarioId =
                      context.read<AuthProvider>().usuarioActual!.id!;

                  final precioBase = precios
                      .where((p) => p.cantidadMinima <= 1)
                      .reduce(
                        (a, b) =>
                            a.cantidadMinima > b.cantidadMinima ? a : b,
                      )
                      .precio;

                  int productoIdFinal;

                  if (producto == null) {
                    productoIdFinal =
                        await productoProvider.crearProductoConPrecio(
                      producto: nuevoProducto,
                      precioVenta: precioBase,
                      usuarioId: usuarioId,
                    );
                  } else {
                    await productoProvider.actualizarProductoConPrecio(
                      producto: nuevoProducto,
                      precioVenta: precioBase,
                      usuarioId: usuarioId,
                    );

                    productoIdFinal = producto.id!;
                  }

                  for (final precio in precios) {
                    if (precio.precio <= 0) continue;

                    await precioService.guardarPrecio(
                      PrecioProducto(
                        productoId: productoIdFinal,
                        tipoPrecio: precio.tipoPrecio,
                        cantidadMinima: precio.cantidadMinima,
                        precio: precio.precio,
                      ),
                      usuarioId: usuarioId,
                      nombreProducto: nombre,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}
}