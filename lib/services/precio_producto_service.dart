import '../database/database_service.dart';
import '../models/precio_producto.dart';
import 'auditoria_service.dart';

class PrecioProductoService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> guardarPrecio(
    PrecioProducto precio, {
    int? usuarioId,
    String? nombreProducto,
  }) async {
    final db = await _dbService.database;

    final existentes = await db.query(
      'precios_producto',
      where: 'producto_id = ? AND tipo_precio = ?',
      whereArgs: [precio.productoId, precio.tipoPrecio],
      limit: 1,
    );

    final data = {
      'producto_id': precio.productoId,
      'tipo_precio': precio.tipoPrecio,
      'cantidad_minima': precio.cantidadMinima,
      'precio': precio.precio,
    };

    if (existentes.isEmpty) {
      final id = await db.insert('precios_producto', data);

      if (usuarioId != null) {
        await _auditoriaService.registrar(
          usuarioId: usuarioId,
          accion: 'CREAR_PRECIO_PRODUCTO',
          tablaAfectada: 'precios_producto',
          registroId: id,
          detalle:
              'Precio creado para ${nombreProducto ?? 'producto ID ${precio.productoId}'}: ${precio.tipoPrecio} \$${precio.precio.toStringAsFixed(2)} desde ${precio.cantidadMinima}',
        );
      }

      return id;
    }

    final result = await db.update(
      'precios_producto',
      data,
      where: 'producto_id = ? AND tipo_precio = ?',
      whereArgs: [precio.productoId, precio.tipoPrecio],
    );

    if (usuarioId != null) {
      await _auditoriaService.registrar(
        usuarioId: usuarioId,
        accion: 'EDITAR_PRECIO_PRODUCTO',
        tablaAfectada: 'precios_producto',
        registroId: precio.productoId,
        detalle:
            'Precio actualizado para ${nombreProducto ?? 'producto ID ${precio.productoId}'}: ${precio.tipoPrecio} \$${precio.precio.toStringAsFixed(2)} desde ${precio.cantidadMinima}',
      );
    }

    return result;
  }

  Future<List<PrecioProducto>> obtenerPreciosProducto(int productoId) async {
    final db = await _dbService.database;

    final result = await db.query(
      'precios_producto',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'cantidad_minima ASC',
    );

    return result.map((map) => PrecioProducto.fromMap(map)).toList();
  }

  Future<PrecioProducto?> obtenerPrecioMenudeo(int productoId) async {
    final db = await _dbService.database;

    final result = await db.query(
      'precios_producto',
      where: 'producto_id = ? AND tipo_precio = ?',
      whereArgs: [productoId, 'MENUDEO'],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return PrecioProducto.fromMap(result.first);
  }

  Future<double> obtenerPrecioVenta(int productoId) async {
    final precio = await obtenerPrecioMenudeo(productoId);
    return precio?.precio ?? 0;
  }

  Future<double> obtenerPrecioPorCantidad({
    required int productoId,
    required double cantidad,
  }) async {
    final db = await _dbService.database;

    final result = await db.query(
      'precios_producto',
      where: 'producto_id = ? AND cantidad_minima <= ?',
      whereArgs: [productoId, cantidad],
      orderBy: 'cantidad_minima DESC',
      limit: 1,
    );

    if (result.isEmpty) return 0;

    return PrecioProducto.fromMap(result.first).precio;
  }

  Future<double> obtenerUltimoCosto(int productoId) async {
    final db = await _dbService.database;

    final result = await db.query(
      'lotes_inventario',
      columns: ['costo_unitario'],
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha_entrada DESC, id DESC',
      limit: 1,
    );

    if (result.isEmpty) return 0;

    return (result.first['costo_unitario'] as num).toDouble();
  }
}