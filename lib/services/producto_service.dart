import '../database/database_service.dart';
import '../models/producto.dart';
import '../models/precio_producto.dart';
import 'auditoria_service.dart';
import 'precio_producto_service.dart';

class ProductoService {
  final _dbService = DatabaseService.instance;
  final _precioService = PrecioProductoService();
  final _auditoriaService = AuditoriaService();

  Future<int> crearProducto(
    Producto producto, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final id = await db.insert('productos', producto.toMap());

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CREAR_PRODUCTO',
      tablaAfectada: 'productos',
      registroId: id,
      detalle:
          'Producto creado: ${producto.nombre} (Código: ${producto.codigoInterno ?? producto.codigoBarras ?? 'Sin código'})',
    );

    return id;
  }

Future<List<Producto>> obtenerProductos({
  int limit = 50,
  int offset = 0,
  String estado = 'TODOS',
}) async {
  final db = await _dbService.database;

  final where = estado == 'TODOS' ? null : 'estado = ?';
  final whereArgs = estado == 'TODOS' ? null : [estado];

  final result = await db.query(
    'productos',
    where: where,
    whereArgs: whereArgs,
    orderBy: 'nombre ASC',
    limit: limit,
    offset: offset,
  );

  return result.map((map) => Producto.fromMap(map)).toList();
}

Future<List<Producto>> buscarProductos(
  String texto, {
  int limit = 50,
  int offset = 0,
  String estado = 'TODOS',
}) async {
  final db = await _dbService.database;

  final filtros = <String>[
    '''
    (
      nombre LIKE ?
      OR codigo_barras LIKE ?
      OR codigo_interno LIKE ?
    )
    '''
  ];

  final args = <Object?>[
    '%$texto%',
    '%$texto%',
    '%$texto%',
  ];

  if (estado != 'TODOS') {
    filtros.add('estado = ?');
    args.add(estado);
  }

  final result = await db.query(
    'productos',
    where: filtros.join(' AND '),
    whereArgs: args,
    orderBy: 'nombre ASC',
    limit: limit,
    offset: offset,
  );

  return result.map((map) => Producto.fromMap(map)).toList();
}
  Future<Producto?> obtenerProductoPorId(int id) async {
    final db = await _dbService.database;

    final result = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Producto.fromMap(result.first);
  }

  Future<Producto?> obtenerProductoPorCodigo(String codigo) async {
    final db = await _dbService.database;

    final result = await db.query(
      'productos',
      where: 'codigo_barras = ? OR codigo_interno = ?',
      whereArgs: [codigo, codigo],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Producto.fromMap(result.first);
  }

  Future<int> actualizarProducto(
    Producto producto, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'EDITAR_PRODUCTO',
      tablaAfectada: 'productos',
      registroId: producto.id,
      detalle: 'Producto actualizado: ${producto.nombre}',
    );

    return result;
  }

  Future<int> cambiarEstadoProducto({
    required int productoId,
    required String estado,
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'productos',
      {
        'estado': estado,
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productoId],
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CAMBIAR_ESTADO_PRODUCTO',
      tablaAfectada: 'productos',
      registroId: productoId,
      detalle: 'Estado cambiado a $estado',
    );

    return result;
  }

  Future<int> crearProductoConPrecio({
    required Producto producto,
    required double precioVenta,
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final productoId = await db.insert('productos', producto.toMap());

    await _precioService.guardarPrecio(
      PrecioProducto(
        productoId: productoId,
        tipoPrecio: 'MENUDEO',
        cantidadMinima: 1,
        precio: precioVenta,
      ),
      usuarioId: usuarioId,
      nombreProducto: producto.nombre,
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CREAR_PRODUCTO',
      tablaAfectada: 'productos',
      registroId: productoId,
      detalle:
          'Producto creado: ${producto.nombre} (Precio: \$${precioVenta.toStringAsFixed(2)})',
    );

    return productoId;
  }

  Future<int> actualizarProductoConPrecio({
    required Producto producto,
    required double precioVenta,
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );

    await _precioService.guardarPrecio(
      PrecioProducto(
        productoId: producto.id!,
        tipoPrecio: 'MENUDEO',
        cantidadMinima: 1,
        precio: precioVenta,
      ),
      usuarioId: usuarioId,
      nombreProducto: producto.nombre,
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'EDITAR_PRODUCTO',
      tablaAfectada: 'productos',
      registroId: producto.id,
      detalle:
          'Producto actualizado: ${producto.nombre} (Precio: \$${precioVenta.toStringAsFixed(2)})',
    );

    return result;
  }
}