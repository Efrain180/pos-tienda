import '../database/database_service.dart';
import '../models/usuario.dart';
import '../utils/password_helper.dart';
import 'auditoria_service.dart';

class AuthService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<Usuario?> login({
    required String usuario,
    required String password,
  }) async {
    final db = await _dbService.database;

    final passwordHash = PasswordHelper.generarHash(password);

    var result = await db.rawQuery('''
      SELECT 
        u.*,
        r.nombre AS rol_nombre
      FROM usuarios u
      INNER JOIN roles r ON r.id = u.rol_id
      WHERE u.usuario = ?
        AND u.password_hash = ?
        AND u.activo = 1
      LIMIT 1
    ''', [usuario, passwordHash]);

    if (result.isEmpty) {
      result = await db.rawQuery('''
        SELECT 
          u.*,
          r.nombre AS rol_nombre
        FROM usuarios u
        INNER JOIN roles r ON r.id = u.rol_id
        WHERE u.usuario = ?
          AND u.password_hash = ?
          AND u.activo = 1
        LIMIT 1
      ''', [usuario, password]);

      if (result.isNotEmpty) {
        final userId = result.first['id'] as int;

        await db.update(
          'usuarios',
          {'password_hash': passwordHash},
          where: 'id = ?',
          whereArgs: [userId],
        );
      }
    }

    if (result.isEmpty) return null;

    final user = Usuario.fromMap(result.first);

    await db.insert('sesiones_usuario', {
      'usuario_id': user.id,
      'fecha_inicio': DateTime.now().toIso8601String(),
      'fecha_fin': null,
      'equipo': 'Windows',
    });

    await _auditoriaService.registrar(
      usuarioId: user.id,
      accion: 'INICIO_SESION',
      tablaAfectada: 'sesiones_usuario',
      registroId: user.id,
      detalle: 'Inicio de sesión: ${user.nombre} (${user.usuario})',
    );

    return user;
  }

  Future<List<String>> obtenerPermisosUsuario(int usuarioId) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT p.codigo
      FROM usuarios u
      INNER JOIN rol_permisos rp ON rp.rol_id = u.rol_id
      INNER JOIN permisos p ON p.id = rp.permiso_id
      WHERE u.id = ?
    ''', [usuarioId]);

    return result.map((row) => row['codigo'].toString()).toList();
  }
}