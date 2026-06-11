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

  Future<List<Auditoria>> obtenerAuditoria() async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT 
        a.*,
        u.nombre AS usuario_nombre
      FROM auditoria a
      LEFT JOIN usuarios u ON u.id = a.usuario_id
      ORDER BY a.fecha DESC
      LIMIT 200
    ''');

    return result.map((map) => Auditoria.fromMap(map)).toList();
  }
}