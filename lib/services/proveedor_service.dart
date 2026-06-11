import '../database/database_service.dart';
import '../models/proveedor.dart';
import 'auditoria_service.dart';

class ProveedorService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> crearProveedor(
    Proveedor proveedor, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final id = await db.insert(
      'proveedores',
      proveedor.toMap(),
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CREAR_PROVEEDOR',
      tablaAfectada: 'proveedores',
      registroId: id,
      detalle: 'Proveedor creado: ${proveedor.nombre}',
    );

    return id;
  }

  Future<List<Proveedor>> obtenerProveedores() async {
    final db = await _dbService.database;

    final result = await db.query(
      'proveedores',
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );

    return result.map((map) => Proveedor.fromMap(map)).toList();
  }

  Future<int> actualizarProveedor(
    Proveedor proveedor, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'proveedores',
      proveedor.toMap(),
      where: 'id = ?',
      whereArgs: [proveedor.id],
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'EDITAR_PROVEEDOR',
      tablaAfectada: 'proveedores',
      registroId: proveedor.id,
      detalle: 'Proveedor actualizado: ${proveedor.nombre}',
    );

    return result;
  }

  Future<int> desactivarProveedor(
    int id, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    String nombreProveedor = 'Proveedor #$id';

    final proveedor = await db.query(
      'proveedores',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (proveedor.isNotEmpty) {
      nombreProveedor = proveedor.first['nombre'].toString();
    }

    final result = await db.update(
      'proveedores',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      await _auditoriaService.registrar(
        usuarioId: usuarioId,
        accion: 'DESACTIVAR_PROVEEDOR',
        tablaAfectada: 'proveedores',
        registroId: id,
        detalle: 'Proveedor desactivado: $nombreProveedor',
      );
    }

    return result;
  }
}