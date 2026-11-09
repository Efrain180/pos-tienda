import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database/database_service.dart';

class PremiumGuardService {
  static const String projectId = 'pos-tienda-5312b';

  final _dbService = DatabaseService.instance;

  Future<bool> premiumActivoLocal() async {
    final db = await _dbService.database;

    final result = await db.query(
      'configuracion',
      columns: [
        'plan',
        'nube_activa',
        'firebase_activo',
        'negocio_id',
      ],
      limit: 1,
    );

    if (result.isEmpty) return false;

    final config = result.first;

    final plan = config['plan']?.toString().toUpperCase() ?? 'PRUEBA';
    final nubeActiva = (config['nube_activa'] as int? ?? 0) == 1;
    final firebaseActivo = (config['firebase_activo'] as int? ?? 0) == 1;
    final negocioId = config['negocio_id']?.toString().trim() ?? '';

    return plan == 'PREMIUM' &&
        nubeActiva &&
        firebaseActivo &&
        negocioId.isNotEmpty;
  }

  Future<bool> verificarPremiumOnlineYActualizarLocal() async {
    final db = await _dbService.database;

    final result = await db.query(
      'configuracion',
      columns: ['id', 'negocio_id'],
      limit: 1,
    );

    if (result.isEmpty) return false;

    final config = result.first;
    final id = config['id'];
    final negocioId = config['negocio_id']?.toString().trim() ?? '';

    if (negocioId.isEmpty) {
      await _apagarPremiumLocal(id);
      return false;
    }

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/negocios/$negocioId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return await premiumActivoLocal();
      }

      final body = jsonDecode(response.body);
      final fields = body['fields'] as Map<String, dynamic>?;

      if (fields == null) {
        await _apagarPremiumLocal(id);
        return false;
      }

      final premiumActivo = fields['premiumActivo']?['booleanValue'] == true;
      final firebaseActivo = fields['firebaseActivo']?['booleanValue'] == true;
      final apkActiva = fields['apkActiva']?['booleanValue'] == true;

      final premiumHastaTexto =
          fields['premiumHasta']?['stringValue']?.toString();

      final premiumHasta = DateTime.tryParse(premiumHastaTexto ?? '');

      final noVencido =
          premiumHasta != null && DateTime.now().isBefore(premiumHasta);

      final activo = premiumActivo && firebaseActivo && apkActiva && noVencido;

      if (activo) {
        await db.update(
          'configuracion',
          {
            'plan': 'PREMIUM',
            'nube_activa': 1,
            'firebase_activo': 1,
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        return true;
      }

      await _apagarPremiumLocal(id);

      if (premiumHasta != null && DateTime.now().isAfter(premiumHasta)) {
        await _apagarPremiumFirebase(negocioId);
      }

      return false;
    } catch (e) {
      return await premiumActivoLocal();
    }
  }

  Future<void> _apagarPremiumLocal(dynamic id) async {
    final db = await _dbService.database;

    await db.update(
      'configuracion',
      {
        'plan': 'BASICO',
        'nube_activa': 0,
        'firebase_activo': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _apagarPremiumFirebase(String negocioId) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/negocios/$negocioId'
      '?updateMask.fieldPaths=plan'
      '&updateMask.fieldPaths=premiumActivo'
      '&updateMask.fieldPaths=apkActiva'
      '&updateMask.fieldPaths=firebaseActivo'
      '&updateMask.fieldPaths=fechaSuspensionPremium',
    );

    await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'plan': {'stringValue': 'BASICO'},
          'premiumActivo': {'booleanValue': false},
          'apkActiva': {'booleanValue': false},
          'firebaseActivo': {'booleanValue': false},
          'fechaSuspensionPremium': {
            'stringValue': DateTime.now().toIso8601String(),
          },
        },
      }),
    );
  }
}