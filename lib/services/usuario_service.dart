import '../database/database_service.dart';
import '../models/usuario.dart';
import '../utils/password_helper.dart';
import 'auditoria_service.dart';

class UsuarioService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<List<Usuario>> obtenerUsuarios() async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT u.*, r.nombre AS rol_nombre
      FROM usuarios u
      INNER JOIN roles r ON r.id = u.rol_id
      ORDER BY u.nombre ASC
    ''');

    return result.map((map) => Usuario.fromMap(map)).toList();
  }

  Future<void> crearUsuario({
    required String nombre,
    required String usuario,
    required String password,
    required int rolId,
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final userId = await db.insert('usuarios', {
      'nombre': nombre,
      'usuario': usuario,
      'password_hash': PasswordHelper.generarHash(password),
      'rol_id': rolId,
      'activo': 1,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CREAR_USUARIO',
      tablaAfectada: 'usuarios',
      registroId: userId,
      detalle: 'Usuario creado: $nombre (Usuario: $usuario)',
    );
  }

  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String usuario,
    String? password,
    required int rolId,
    required bool activo,
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final data = {
      'nombre': nombre,
      'usuario': usuario,
      'rol_id': rolId,
      'activo': activo ? 1 : 0,
    };

    final cambioPassword = password != null && password.trim().isNotEmpty;

    if (cambioPassword) {
      data['password_hash'] = PasswordHelper.generarHash(password.trim());
    }

    await db.update(
      'usuarios',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: cambioPassword ? 'EDITAR_USUARIO_PASSWORD' : 'EDITAR_USUARIO',
      tablaAfectada: 'usuarios',
      registroId: id,
      detalle: cambioPassword
          ? 'Usuario actualizado: $nombre (Usuario: $usuario) - Rol ID: $rolId - Activo: $activo - Contraseña cambiada'
          : 'Usuario actualizado: $nombre (Usuario: $usuario) - Rol ID: $rolId - Activo: $activo',
    );
  }

  Future<List<Map<String, dynamic>>> obtenerRoles() async {
    final db = await _dbService.database;

    return db.query(
      'roles',
      orderBy: 'id ASC',
    );
  }
}