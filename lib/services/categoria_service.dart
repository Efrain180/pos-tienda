import '../database/database_service.dart';
import '../models/categoria.dart';
import 'auditoria_service.dart';

class CategoriaService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> crearCategoria(
    Categoria categoria, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final id = await db.insert(
      'categorias',
      categoria.toMap(),
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CREAR_CATEGORIA',
      tablaAfectada: 'categorias',
      registroId: id,
      detalle: 'Categoría creada: ${categoria.nombre}',
    );

    return id;
  }

  Future<List<Categoria>> obtenerCategorias() async {
    final db = await _dbService.database;

    final result = await db.query(
      'categorias',
      orderBy: 'nombre ASC',
    );

    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<int> actualizarCategoria(
    Categoria categoria, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'EDITAR_CATEGORIA',
      tablaAfectada: 'categorias',
      registroId: categoria.id,
      detalle: 'Categoría actualizada: ${categoria.nombre}',
    );

    return result;
  }

  Future<int> eliminarCategoria(
    int id, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    String nombreCategoria = 'Desconocida';

    final categoria = await db.query(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (categoria.isNotEmpty) {
      nombreCategoria = categoria.first['nombre'].toString();
    }

    final result = await db.delete(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      await _auditoriaService.registrar(
        usuarioId: usuarioId,
        accion: 'ELIMINAR_CATEGORIA',
        tablaAfectada: 'categorias',
        registroId: id,
        detalle: 'Categoría eliminada: $nombreCategoria',
      );
    }

    return result;
  }
}