import '../database/database_service.dart';
import '../models/presentacion_producto.dart';
import 'auditoria_service.dart';

class PresentacionProductoService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> guardarPresentacion(
    PresentacionProducto presentacion, {
    int? usuarioId,
    String? nombreProducto,
  }) async {
    final db = await _dbService.database;

    final data = presentacion.toMap();

    if (presentacion.id == null) {
      final id = await db.insert('presentaciones_producto', data);

      if (usuarioId != null) {
        await _auditoriaService.registrar(
          usuarioId: usuarioId,
          accion: 'CREAR_PRESENTACION_PRODUCTO',
          tablaAfectada: 'presentaciones_producto',
          registroId: id,
          detalle:
              'Presentación creada para ${nombreProducto ?? 'producto ID ${presentacion.productoId}'}: ${presentacion.nombre}, factor ${presentacion.factorConversion}, precio \$${presentacion.precio.toStringAsFixed(2)}',
        );
      }

      return id;
    }

    final result = await db.update(
      'presentaciones_producto',
      data,
      where: 'id = ?',
      whereArgs: [presentacion.id],
    );

    if (usuarioId != null) {
      await _auditoriaService.registrar(
        usuarioId: usuarioId,
        accion: 'EDITAR_PRESENTACION_PRODUCTO',
        tablaAfectada: 'presentaciones_producto',
        registroId: presentacion.id,
        detalle:
            'Presentación actualizada para ${nombreProducto ?? 'producto ID ${presentacion.productoId}'}: ${presentacion.nombre}, factor ${presentacion.factorConversion}, precio \$${presentacion.precio.toStringAsFixed(2)}',
      );
    }

    return result;
  }

  Future<List<PresentacionProducto>> obtenerPresentacionesProducto(
    int productoId,
  ) async {
    final db = await _dbService.database;

    final result = await db.query(
      'presentaciones_producto',
      where: 'producto_id = ? AND activo = ?',
      whereArgs: [productoId, 1],
      orderBy: 'factor_conversion ASC',
    );

    return result.map((map) => PresentacionProducto.fromMap(map)).toList();
  }

  Future<PresentacionProducto?> obtenerPorCodigo(String codigo) async {
    final db = await _dbService.database;

    final result = await db.query(
      'presentaciones_producto',
      where: 'codigo_barras = ? AND activo = ?',
      whereArgs: [codigo, 1],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return PresentacionProducto.fromMap(result.first);
  }

  Future<int> desactivarPresentacion(
    int id, {
    required int usuarioId,
    String? nombreProducto,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'presentaciones_producto',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      await _auditoriaService.registrar(
        usuarioId: usuarioId,
        accion: 'DESACTIVAR_PRESENTACION_PRODUCTO',
        tablaAfectada: 'presentaciones_producto',
        registroId: id,
        detalle:
            'Presentación desactivada${nombreProducto != null ? ' de $nombreProducto' : ''}',
      );
    }

    return result;
  }
}