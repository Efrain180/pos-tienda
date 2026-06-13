import '../database/database_service.dart';
import '../models/auditoria.dart';

class AuditoriaService {
  final _dbService = DatabaseService.instance;

  Future<void> registrar({
    int? usuarioId,
    required String accion,
    required String tablaAfectada,
    int? registroId,
    String? detalle,
  }) async {
    final db = await _dbService.database;

    await db.insert('auditoria', {
      'usuario_id': usuarioId,
      'accion': accion,
      'tabla_afectada': tablaAfectada,
      'registro_id': registroId,
      'detalle': detalle,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

Future<List<Auditoria>> obtenerAuditoria({
  int limit = 200,
  int offset = 0,
  String? accion,
  String? tabla,
  String? buscar,
  DateTime? inicio,
  DateTime? fin,
}) async {
  final db = await _dbService.database;

  final where = <String>[];
  final args = <dynamic>[];

  if (accion != null && accion.isNotEmpty) {
    where.add('a.accion = ?');
    args.add(accion);
  }

  if (tabla != null && tabla.isNotEmpty) {
    where.add('a.tabla_afectada = ?');
    args.add(tabla);
  }

  if (buscar != null && buscar.trim().isNotEmpty) {
    where.add('(a.detalle LIKE ? OR u.nombre LIKE ? OR a.accion LIKE ?)');
    final q = '%${buscar.trim()}%';
    args.addAll([q, q, q]);
  }

  if (inicio != null) {
    where.add('a.fecha >= ?');
    args.add(inicio.toIso8601String());
  }

  if (fin != null) {
    where.add('a.fecha < ?');
    args.add(fin.toIso8601String());
  }

  final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

  final result = await db.rawQuery('''
    SELECT 
      a.*,
      u.nombre AS usuario_nombre
    FROM auditoria a
    LEFT JOIN usuarios u ON u.id = a.usuario_id
    $whereSql
    ORDER BY a.fecha DESC
    LIMIT ? OFFSET ?
  ''', [
    ...args,
    limit,
    offset,
  ]);

  return result.map((map) => Auditoria.fromMap(map)).toList();
}
}