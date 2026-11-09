import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database/database_service.dart';
import '../utils/password_helper.dart';

class LicenciaInfo {
  final String tipoLicencia;
  final String? claveLicencia;
  final DateTime? fechaInstalacion;
  final DateTime? fechaVencimiento;
  final bool vencida;
  final int diasRestantes;

  LicenciaInfo({
    required this.tipoLicencia,
    required this.claveLicencia,
    required this.fechaInstalacion,
    required this.fechaVencimiento,
    required this.vencida,
    required this.diasRestantes,
  });
}

class LicenciaService {
  static const String projectId = 'pos-tienda-5312b';

  final _dbService = DatabaseService.instance;

  Future<LicenciaInfo> obtenerLicencia() async {
    final db = await _dbService.database;

    final result = await db.query(
      'configuracion',
      limit: 1,
    );

    if (result.isEmpty) {
      return LicenciaInfo(
        tipoLicencia: 'PRUEBA',
        claveLicencia: null,
        fechaInstalacion: null,
        fechaVencimiento: null,
        vencida: true,
        diasRestantes: 0,
      );
    }

    final config = result.first;

    final tipo = config['tipo_licencia']?.toString() ?? 'PRUEBA';
    final clave = config['clave_licencia']?.toString();

    final fechaInstalacion = DateTime.tryParse(
      config['fecha_instalacion']?.toString() ?? '',
    );

    final fechaVencimiento = DateTime.tryParse(
      config['fecha_vencimiento']?.toString() ?? '',
    );

    final ahora = DateTime.now();

    final vencida =
        fechaVencimiento != null && ahora.isAfter(fechaVencimiento);

    final diasRestantes = fechaVencimiento == null
        ? 0
        : fechaVencimiento.difference(ahora).inDays.clamp(0, 9999);

    return LicenciaInfo(
      tipoLicencia: tipo,
      claveLicencia: clave,
      fechaInstalacion: fechaInstalacion,
      fechaVencimiento: fechaVencimiento,
      vencida: vencida,
      diasRestantes: diasRestantes,
    );
  }

  Future<bool> licenciaVencida() async {
    final licencia = await obtenerLicencia();
    return licencia.vencida;
  }

  Future<String?> obtenerPlanLicenciaFirebase(String clave) async {
    final claveLimpia = clave.trim().toUpperCase();

    if (claveLimpia.isEmpty) return null;

    final fields = await _obtenerFieldsLicencia(claveLimpia);

    if (fields == null) return null;

    final activa = fields['activa']?['booleanValue'] == true;
    final usada = fields['usada']?['booleanValue'] == true;

    if (!activa || usada) return null;

    return fields['plan']?['stringValue']?.toString().toUpperCase() ??
        'BASICO';
  }

  Future<bool> activarLicencia({
    required String clave,
    String? usuarioApp,
    String? passwordApp,
  }) async {
    final claveLimpia = clave.trim().toUpperCase();

    if (claveLimpia.isEmpty) return false;

    final fields = await _obtenerFieldsLicencia(claveLimpia);

    if (fields == null) return false;

    final activa = fields['activa']?['booleanValue'] == true;
    final usada = fields['usada']?['booleanValue'] == true;

    final plan =
        fields['plan']?['stringValue']?.toString().toUpperCase() ?? 'BASICO';

    final mesesText = fields['meses']?['integerValue']?.toString() ?? '1';
    final meses = int.tryParse(mesesText) ?? 1;

    if (!activa) return false;
    if (usada) return false;

    final esPremium = plan == 'PREMIUM';

    final db = await _dbService.database;

    final configResult = await db.query(
      'configuracion',
      columns: ['id', 'negocio_id', 'nombre_negocio'],
      limit: 1,
    );

    if (configResult.isEmpty) return false;

    final config = configResult.first;

    final configId = config['id'];
    final negocioId = config['negocio_id']?.toString().trim() ?? '';
    final nombreNegocio =
        config['nombre_negocio']?.toString().trim() ?? 'Negocio';

    if (negocioId.isEmpty) {
      print('No hay negocio_id local');
      return false;
    }

    if (esPremium) {
      if (usuarioApp == null ||
          usuarioApp.trim().isEmpty ||
          passwordApp == null ||
          passwordApp.trim().isEmpty) {
        print('Premium requiere usuario y contraseña para APK');
        return false;
      }
    }

    final ahora = DateTime.now();
    final premiumHasta = ahora.add(Duration(days: 30 * meses));

    await db.update(
      'configuracion',
      {
        'tipo_licencia': esPremium ? 'SUSCRIPCION' : 'ACTIVA',
        'clave_licencia': claveLimpia,
        'fecha_vencimiento': null,
        'plan': plan,
        'nube_activa': esPremium ? 1 : 0,
        'firebase_activo': esPremium ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [configId],
    );

    if (esPremium) {
      await _actualizarNegocioPremiumFirebase(
        negocioId: negocioId,
        nombreNegocio: nombreNegocio,
        plan: plan,
        premiumActivo: true,
        premiumHasta: premiumHasta,
      );

      await _crearUsuarioAppFirebase(
        usuario: usuarioApp!,
        password: passwordApp!,
        negocioId: negocioId,
      );
    }

    await _marcarLicenciaUsada(
      clave: claveLimpia,
      negocioId: negocioId,
      plan: plan,
    );

    return true;
  }

  Future<Map<String, dynamic>?> _obtenerFieldsLicencia(String clave) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/licencias/$clave',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      print('Licencia no encontrada o sin permiso: ${response.body}');
      return null;
    }

    final body = jsonDecode(response.body);
    return body['fields'] as Map<String, dynamic>?;
  }

  Future<void> _marcarLicenciaUsada({
    required String clave,
    required String negocioId,
    required String plan,
  }) async {
    final patchUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/licencias/$clave'
      '?updateMask.fieldPaths=usada'
      '&updateMask.fieldPaths=fechaActivacion'
      '&updateMask.fieldPaths=negocioId'
      '&updateMask.fieldPaths=planActivado',
    );

    await http.patch(
      patchUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'usada': {'booleanValue': true},
          'fechaActivacion': {
            'stringValue': DateTime.now().toIso8601String(),
          },
          'negocioId': {'stringValue': negocioId},
          'planActivado': {'stringValue': plan},
        },
      }),
    );
  }
  Future<void> actualizarAccesoAppPremium({
  required String negocioId,
  required String usuario,
  required String password,
}) async {
  final usuarioLimpio = usuario.trim();
  final documentoId = '${negocioId}_${usuarioLimpio.replaceAll('/', '_')}';

  await _desactivarUsuariosAppDelNegocio(negocioId);

  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/usuarios_app/$documentoId',
  );

  await http.patch(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fields': {
        'usuario': {'stringValue': usuarioLimpio},
        'password_hash': {
          'stringValue': PasswordHelper.generarHash(password),
        },
        'negocioId': {'stringValue': negocioId},
        'activo': {'booleanValue': true},
        'fechaActualizacion': {
          'stringValue': DateTime.now().toIso8601String(),
        },
      },
    }),
  );
}

Future<void> _desactivarUsuariosAppDelNegocio(String negocioId) async {
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery',
  );

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': 'usuarios_app'}
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'negocioId'},
            'op': 'EQUAL',
            'value': {'stringValue': negocioId},
          }
        }
      }
    }),
  );

  if (response.statusCode != 200) return;

  final data = jsonDecode(response.body);

  if (data is! List) return;

  for (final item in data) {
    final doc = item['document'];
    if (doc == null) continue;

    final name = doc['name'];
    if (name == null) continue;

    final patchUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/$name'
      '?updateMask.fieldPaths=activo',
    );

    await http.patch(
      patchUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'activo': {'booleanValue': false},
        },
      }),
    );
  }
}

  Future<void> _crearUsuarioAppFirebase({
    required String usuario,
    required String password,
    required String negocioId,
  }) async {
    final usuarioLimpio = usuario.trim();
final documentoId = '${negocioId}_${usuarioLimpio}';

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/usuarios_app/$documentoId',
    );

    await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'usuario': {'stringValue': usuarioLimpio},
          'password_hash': {
  'stringValue': PasswordHelper.generarHash(password),
},
          'negocioId': {'stringValue': negocioId},
          'activo': {'booleanValue': true},
        },
      }),
    );
  }

  Future<void> _actualizarNegocioPremiumFirebase({
    required String negocioId,
    required String nombreNegocio,
    required String plan,
    required bool premiumActivo,
    required DateTime premiumHasta,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/negocios/$negocioId'
      '?updateMask.fieldPaths=nombreNegocio'
      '&updateMask.fieldPaths=plan'
      '&updateMask.fieldPaths=premiumActivo'
      '&updateMask.fieldPaths=premiumHasta'
      '&updateMask.fieldPaths=apkActiva'
      '&updateMask.fieldPaths=firebaseActivo'
      '&updateMask.fieldPaths=ultimaActivacionPremium',
    );

    await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'nombreNegocio': {'stringValue': nombreNegocio},
          'plan': {'stringValue': plan},
          'premiumActivo': {'booleanValue': premiumActivo},
          'premiumHasta': {'stringValue': premiumHasta.toIso8601String()},
          'apkActiva': {'booleanValue': premiumActivo},
          'firebaseActivo': {'booleanValue': premiumActivo},
          'ultimaActivacionPremium': {
            'stringValue': DateTime.now().toIso8601String(),
          },
        },
      }),
    );
  }
}