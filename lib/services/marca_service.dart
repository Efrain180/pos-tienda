import '../database/database_service.dart';
import '../models/marca.dart';
import 'auditoria_service.dart';

class MarcaService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> crearMarca(
    Marca marca, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final id = await db.insert(
      'marcas',
      marca.toMap(),
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CREAR_MARCA',
      tablaAfectada: 'marcas',
      registroId: id,
      detalle: 'Marca creada: ${marca.nombre}',
    );

    return id;
  }

  Future<List<Marca>> obtenerMarcas() async {
    final db = await _dbService.database;

    final result = await db.query(
      'marcas',
      orderBy: 'nombre ASC',
    );

    return result.map((map) => Marca.fromMap(map)).toList();
  }

  Future<int> actualizarMarca(
    Marca marca, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'marcas',
      marca.toMap(),
      where: 'id = ?',
      whereArgs: [marca.id],
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'EDITAR_MARCA',
      tablaAfectada: 'marcas',
      registroId: marca.id,
      detalle: 'Marca actualizada: ${marca.nombre}',
    );

    return result;
  }

  Future<int> eliminarMarca(
    int id, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    String nombreMarca = 'Desconocida';

    final marca = await db.query(
      'marcas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (marca.isNotEmpty) {
      nombreMarca = marca.first['nombre'].toString();
    }

    final result = await db.delete(
      'marcas',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      await _auditoriaService.registrar(
        usuarioId: usuarioId,
        accion: 'ELIMINAR_MARCA',
        tablaAfectada: 'marcas',
        registroId: id,
        detalle: 'Marca eliminada: $nombreMarca',
      );
    }

    return result;
  }
}