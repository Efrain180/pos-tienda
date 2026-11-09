import '../database/database_service.dart';
import '../utils/password_helper.dart';

class SetupService {
  final _dbService = DatabaseService.instance;

  Future<bool> sistemaYaConfigurado() async {
    final db = await _dbService.database;

    final result = await db.query(
      'configuracion',
      limit: 1,
    );

    if (result.isEmpty) return false;

    final config = result.first;
    final nombre = config['nombre_negocio']?.toString().trim() ?? '';

    print('CONFIGURADO: $nombre');

    return nombre.isNotEmpty;
  }

Future<void> configurarSistemaInicial({
  required String nombreNegocio,
  required String telefono,
  required String direccion,
  required String usuarioAdmin,
  required String passwordAdmin,
}) async {
  final yaConfigurado = await sistemaYaConfigurado();

  if (yaConfigurado) {
    throw Exception('El sistema ya está configurado');
  }

  final db = await _dbService.database;

  final negocioId = _generarNegocioId(nombreNegocio);

  const String plan = 'PRUEBA';
  const int nubeActiva = 0;

  final fechaInstalacion = DateTime.now();
  final fechaVencimiento = fechaInstalacion.add(const Duration(days: 7));
  final now = fechaInstalacion.toIso8601String();

  await db.transaction((txn) async {
    final configActual = await txn.query(
      'configuracion',
      limit: 1,
    );

    final dataConfig = {
      'nombre_negocio': nombreNegocio,
      'telefono': telefono,
      'direccion': direccion,
      'usa_fifo': 1,
      'usa_fiados': 1,
      'stock_minimo_global': 5,
      'impresora_tickets': '',
      'margen_ganancia_default': 25,
      'firebase_activo': nubeActiva,
      'negocio_id': negocioId,
      'nube_activa': nubeActiva,
      'plan': plan,
      'tipo_licencia': 'PRUEBA',
      'fecha_instalacion': fechaInstalacion.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'clave_licencia': null,
    };

    if (configActual.isEmpty) {
      await txn.insert('configuracion', {
        'id': 1,
        ...dataConfig,
      });
    } else {
      final id = configActual.first['id'];

      await txn.update(
        'configuracion',
        dataConfig,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    final usuariosExistentes = await txn.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuarioAdmin],
      limit: 1,
    );

    if (usuariosExistentes.isEmpty) {
      await txn.insert('usuarios', {
        'nombre': 'Administrador',
        'usuario': usuarioAdmin,
        'password_hash': PasswordHelper.generarHash(passwordAdmin),
        'rol_id': 1,
        'activo': 1,
        'fecha_creacion': now,
      });
    } else {
      final usuarioId = usuariosExistentes.first['id'];

      await txn.update(
        'usuarios',
        {
          'nombre': 'Administrador',
          'password_hash': PasswordHelper.generarHash(passwordAdmin),
          'rol_id': 1,
          'activo': 1,
        },
        where: 'id = ?',
        whereArgs: [usuarioId],
      );
    }

    final clientes = await txn.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (clientes.isEmpty) {
      await txn.insert('clientes', {
        'id': 1,
        'nombre': 'PUBLICO GENERAL',
        'telefono': null,
        'direccion': null,
        'permite_fiado': 0,
        'limite_credito': 0,
        'bloqueado_credito': 0,
        'activo': 1,
        'fecha_registro': now,
      });
    }
  });
}
  String _generarNegocioId(String nombre) {
    final limpio = nombre
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñ\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final corto = timestamp.substring(timestamp.length - 4);

    if (limpio.isEmpty) {
      return 'negocio_$corto';
    }

    return '${limpio}_$corto';
  }
}