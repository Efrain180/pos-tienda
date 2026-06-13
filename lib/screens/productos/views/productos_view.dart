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
import '../../../models/presentacion_producto.dart';
import '../../../services/presentacion_producto_service.dart';

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
  final productos = provider.productos;

  final activos = productos.where((p) => p.estado == 'ACTIVO').length;
  final inactivos = productos.where((p) => p.estado != 'ACTIVO').length;
  final stockBajo = productos.where((p) {
    return p.stockActual <= p.stockMinimo;
  }).length;

  return Container(
    color: const Color(0xFFF4F6F8),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _mostrarFormularioProducto(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _ProductoResumenCard(
                label: 'Productos',
                value: productos.length.toString(),
                icon: Icons.inventory_2,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _ProductoResumenCard(
                label: 'Activos',
                value: activos.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _ProductoResumenCard(
                label: 'Stock bajo',
                value: stockBajo.toString(),
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _ProductoResumenCard(
                label: 'Inactivos',
                value: inactivos.toString(),
                icon: Icons.block,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 14),

          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar por nombre, código de barras o código interno',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: provider.buscarProductos,
          ),
          const SizedBox(height: 12),

Row(
  children: [
    FilledButton(
      onPressed: () {
        context.read<ProductoProvider>()
            .filtrarPorEstado('TODOS');
      },
      child: const Text('Todos'),
    ),

    const SizedBox(width: 8),

    FilledButton(
      onPressed: () {
        context.read<ProductoProvider>()
            .filtrarPorEstado('ACTIVO');
      },
      child: const Text('Activos'),
    ),

    const SizedBox(width: 8),

    FilledButton(
      onPressed: () {
        context.read<ProductoProvider>()
            .filtrarPorEstado('INACTIVO');
      },
      child: const Text('Inactivos'),
    ),

    const SizedBox(width: 8),

    FilledButton(
      onPressed: () {
        context.read<ProductoProvider>()
            .filtrarPorEstado('DESCONTINUADO');
      },
      child: const Text('Descontinuados'),
    ),
  ],
),

          const SizedBox(height: 14),

          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : productos.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay productos registrados',
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
                                height: 42,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
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
                                      flex: 2,
                                      child: Text(
                                        'Código',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Unidad',
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
                                        'Estado',
                                        textAlign: TextAlign.center,
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
                                  itemCount: productos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final producto = productos[index];
                                    final codigo =
                                        producto.codigoBarras ??
                                            producto.codigoInterno ??
                                            'Sin código';

                                    final bajoStock = producto.stockActual <=
                                        producto.stockMinimo;

                                    return Container(
                                      height: 56,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: index.isEven
                                            ? Colors.white
                                            : const Color(0xFFFAFBFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: bajoStock
                                              ? Colors.orange.withOpacity(0.35)
                                              : Colors.grey.withOpacity(0.10),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  producto.nombre,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w900,
                                                  ),
                                                ),
                                                if ((producto.descripcion ?? '')
                                                    .isNotEmpty)
                                                  Text(
                                                    producto.descripcion!,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              codigo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              producto.unidadMedida,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: _ProductoChip(
                                                texto:
                                                    '${producto.stockActual}',
                                                color: bajoStock
                                                    ? Colors.orange
                                                    : Colors.green,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: _ProductoChip(
                                                texto: producto.estado,
                                                color: producto.estado ==
                                                        'ACTIVO'
                                                    ? Colors.green
                                                    : producto.estado ==
                                                            'INACTIVO'
                                                        ? Colors.red
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 52,
                                            child: IconButton(
                                              tooltip: 'Editar',
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              onPressed: () =>
                                                  _mostrarFormularioProducto(
                                                context,
                                                producto: producto,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (provider.hayMas) ...[
  const SizedBox(height: 10),

  SizedBox(
    width: double.infinity,
    height: 44,
    child: OutlinedButton.icon(
      onPressed: provider.cargandoMas
          ? null
          : () {
              context
                  .read<ProductoProvider>()
                  .cargarMasProductos();
            },
      icon: provider.cargandoMas
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.expand_more),
      label: Text(
        provider.cargandoMas
            ? 'Cargando...'
            : 'Cargar más productos',
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
  final presentacionService = PresentacionProductoService();

  List<PrecioProducto> precios = [];

  if (producto?.id != null) {
    precios = await precioService.obtenerPreciosProducto(producto!.id!);
  }
  List<PresentacionProducto> presentaciones = [];


final productoIdPresentaciones = producto?.id;

if (productoIdPresentaciones != null) {
  presentaciones = await presentacionService
      .obtenerPresentacionesProducto(productoIdPresentaciones);
} 
  final usarPresentaciones = presentaciones.isNotEmpty;

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
  final nombrePresentacionController = TextEditingController();
final factorPresentacionController =
    TextEditingController(text: '1');
final precioPresentacionController =
    TextEditingController();
final codigoPresentacionController =
    TextEditingController();

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
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(22),
  ),
  titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
  contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
  actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
  title: Row(
    children: [
      CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
        child: Icon(
          producto == null ? Icons.add_box_outlined : Icons.edit_outlined,
          color: Theme.of(context).primaryColor,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          producto == null ? 'Nuevo producto' : 'Editar producto',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  ),
  content: SizedBox(
    width: 920,
    height: 680,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormularioSeccion(
            titulo: 'Datos básicos',
            icono: Icons.inventory_2_outlined,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
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
                const SizedBox(height: 12),
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
                        isExpanded: true,
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
                              child: Text(
                                c.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        isExpanded: true,
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
                              child: Text(
                                m.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => marcaId = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unidadMedida,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
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
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _FormularioSeccion(
            titulo: 'Recomendación de precio',
            icono: Icons.trending_up,
            child: Column(
              children: [
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
                          labelText: 'Precio recomendado',
                          helperText: 'Margen configurado: $margenConfigurado%',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: gananciaUnidadController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Ganancia',
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
                          labelText: 'Margen %',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _FormularioSeccion(
            titulo: 'Presentaciones',
            icono: Icons.view_module_outlined,
            trailing: precios.isNotEmpty
                ? const _FormularioAviso(
                    texto: 'Desactivado porque ya hay precios por cantidad',
                    color: Colors.orange,
                  )
                : null,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nombrePresentacionController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'SUELTO, CAJETILLA, CAJA...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: factorPresentacionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Factor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: precioPresentacionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: codigoPresentacionController,
                        decoration: const InputDecoration(
                          labelText: 'Código opcional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: precios.isNotEmpty
                            ? null
                            : () {
                                final nombre = nombrePresentacionController.text
                                    .trim()
                                    .toUpperCase();

                                final factor = double.tryParse(
                                      factorPresentacionController.text.trim(),
                                    ) ??
                                    0;

                                final precio = double.tryParse(
                                      precioPresentacionController.text.trim(),
                                    ) ??
                                    0;

                                final codigo =
                                    codigoPresentacionController.text.trim();

                                if (nombre.isEmpty ||
                                    factor <= 0 ||
                                    precio <= 0) {
                                  return;
                                }

                                setState(() {
                                  presentaciones.removeWhere(
                                    (p) => p.nombre == nombre,
                                  );

                                  presentaciones.add(
                                    PresentacionProducto(
                                      productoId: producto?.id ?? 0,
                                      nombre: nombre,
                                      factorConversion: factor,
                                      precio: precio,
                                      codigoBarras:
                                          codigo.isEmpty ? null : codigo,
                                    ),
                                  );

                                  presentaciones.sort(
                                    (a, b) => a.factorConversion.compareTo(
                                      b.factorConversion,
                                    ),
                                  );

                                  nombrePresentacionController.clear();
                                  factorPresentacionController.text = '1';
                                  precioPresentacionController.clear();
                                  codigoPresentacionController.clear();
                                });
                              },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (presentaciones.isEmpty)
                  const _FormularioEmpty(
                    texto: 'No hay presentaciones agregadas',
                  )
                else
                  Column(
                    children: [
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF2F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Nombre',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Factor',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Precio',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Código',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            SizedBox(width: 46),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...presentaciones.map((presentacion) {
                        return Container(
                          height: 44,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  presentacion.nombre,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${presentacion.factorConversion}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '\$${presentacion.precio.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  presentacion.codigoBarras ?? 'Sin código',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 46,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    setState(() {
                                      presentaciones.remove(presentacion);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),

          if (presentaciones.isEmpty) ...[
            const SizedBox(height: 14),
            _FormularioSeccion(
              titulo: 'Precios por cantidad',
              icono: Icons.sell_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
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
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (precios.isEmpty)
                    const _FormularioEmpty(
                      texto: 'No hay precios agregados',
                    )
                  else
                    Column(
                      children: precios.map((precio) {
                        final costoBase =
                            double.tryParse(costoBaseController.text.trim()) ??
                                0;

                        final ventaTotal =
                            precio.precio * precio.cantidadMinima;
                        final costoTotal =
                            costoBase * precio.cantidadMinima;
                        final ganancia = ventaTotal - costoTotal;
                        final margen = ventaTotal > 0
                            ? (ganancia / ventaTotal) * 100
                            : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  precio.tipoPrecio,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text('Desde ${precio.cantidadMinima}'),
                              ),
                              Expanded(
                                child: Text(
                                  '\$${precio.precio.toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Gan. \$${ganancia.toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${margen.toStringAsFixed(2)}%',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    precios.remove(precio);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
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

if (presentaciones.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Agrega al menos una presentación'),
    ),
  );
  return;
}

if (!presentaciones.any((p) => p.factorConversion <= 1)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Debe existir una presentación de 1 unidad',
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

final precioBase = presentaciones
    .where((p) => p.factorConversion <= 1)
    .reduce(
      (a, b) =>
          a.factorConversion > b.factorConversion ? a : b,
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
                  for (final presentacion in presentaciones) {
  if (presentacion.factorConversion <= 0) continue;
  if (presentacion.precio <= 0) continue;

  await presentacionService.guardarPresentacion(
    PresentacionProducto(
      id: presentacion.id,
      productoId: productoIdFinal,
      nombre: presentacion.nombre,
      factorConversion: presentacion.factorConversion,
      precio: presentacion.precio,
      codigoBarras: presentacion.codigoBarras,
      activo: presentacion.activo,
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
class _ProductoResumenCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProductoResumenCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
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

class _ProductoChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _ProductoChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
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
class _FormularioSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;
  final Widget? trailing;

  const _FormularioSeccion({
    required this.titulo,
    required this.icono,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icono, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FormularioEmpty extends StatelessWidget {
  final String texto;

  const _FormularioEmpty({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FormularioAviso extends StatelessWidget {
  final String texto;
  final Color color;

  const _FormularioAviso({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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