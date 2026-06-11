import '../database/database_service.dart';
import '../models/caja.dart';
import '../models/movimiento_caja.dart';
import 'auditoria_service.dart';

class CajaService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<Map<String, double>> obtenerResumenCaja(int cajaId) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN tipo = 'APERTURA' THEN monto ELSE 0 END), 0) AS apertura,
        COALESCE(SUM(CASE WHEN tipo = 'VENTA_EFECTIVO' THEN monto ELSE 0 END), 0) AS ventas_efectivo,
        COALESCE(SUM(CASE WHEN tipo = 'ABONO_CREDITO' THEN monto ELSE 0 END), 0) AS abonos_credito,
        COALESCE(SUM(CASE WHEN tipo = 'GASTO' THEN monto ELSE 0 END), 0) AS gastos,
        COALESCE(SUM(monto), 0) AS esperado
      FROM movimientos_caja
      WHERE caja_id = ?
    ''', [cajaId]);

    final row = result.first;

    return {
      'apertura': (row['apertura'] as num).toDouble(),
      'ventas_efectivo': (row['ventas_efectivo'] as num).toDouble(),
      'abonos_credito': (row['abonos_credito'] as num).toDouble(),
      'gastos': (row['gastos'] as num).toDouble(),
      'esperado': (row['esperado'] as num).toDouble(),
    };
  }

  Future<Caja?> obtenerCajaAbierta() async {
    final db = await _dbService.database;

    final result = await db.query(
      'cajas',
      where: 'estado = ?',
      whereArgs: ['ABIERTA'],
      orderBy: 'fecha_apertura DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Caja.fromMap(result.first);
  }

  Future<int> abrirCaja({
    required double montoInicial,
    int? usuarioId,
  }) async {
    final db = await _dbService.database;

    final cajaAbierta = await obtenerCajaAbierta();
    if (cajaAbierta != null) {
      throw Exception('Ya existe una caja abierta');
    }

    final cajaId = await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      final cajaId = await txn.insert('cajas', {
        'usuario_apertura': usuarioId,
        'usuario_cierre': null,
        'monto_inicial': montoInicial,
        'monto_esperado': montoInicial,
        'monto_contado': null,
        'faltante': 0,
        'sobrante': 0,
        'fecha_apertura': now,
        'fecha_cierre': null,
        'estado': 'ABIERTA',
      });

      await txn.insert('movimientos_caja', {
        'caja_id': cajaId,
        'tipo': 'APERTURA',
        'monto': montoInicial,
        'referencia': 'Apertura de caja',
        'fecha': now,
      });

      return cajaId;
    });

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'ABRIR_CAJA',
      tablaAfectada: 'cajas',
      registroId: cajaId,
      detalle: 'Caja abierta con \$${montoInicial.toStringAsFixed(2)}',
    );

    return cajaId;
  }

  Future<void> registrarMovimiento({
    required String tipo,
    required double monto,
    String? referencia,
  }) async {
    final db = await _dbService.database;

    final caja = await obtenerCajaAbierta();
    if (caja == null) {
      throw Exception('No hay caja abierta');
    }

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      await txn.insert('movimientos_caja', {
        'caja_id': caja.id,
        'tipo': tipo,
        'monto': monto,
        'referencia': referencia,
        'fecha': now,
      });

      final sumaResult = await txn.rawQuery('''
        SELECT COALESCE(SUM(monto), 0) AS total
        FROM movimientos_caja
        WHERE caja_id = ?
      ''', [caja.id]);

      final esperado = (sumaResult.first['total'] as num).toDouble();

      await txn.update(
        'cajas',
        {'monto_esperado': esperado},
        where: 'id = ?',
        whereArgs: [caja.id],
      );
    });

    await _auditoriaService.registrar(
      usuarioId: null,
      accion: 'MOVIMIENTO_CAJA',
      tablaAfectada: 'movimientos_caja',
      registroId: caja.id,
      detalle:
          '$tipo por \$${monto.toStringAsFixed(2)}${referencia == null ? '' : ' - $referencia'}',
    );
  }

  Future<void> registrarGasto({
    required String categoria,
    String? descripcion,
    required double monto,
    int? usuarioId,
  }) async {
    final db = await _dbService.database;

    final caja = await obtenerCajaAbierta();
    if (caja == null) {
      throw Exception('No hay caja abierta');
    }

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      await txn.insert('gastos', {
        'categoria': categoria,
        'descripcion': descripcion,
        'monto': monto,
        'usuario_id': usuarioId,
        'fecha': now,
      });

      await txn.insert('movimientos_caja', {
        'caja_id': caja.id,
        'tipo': 'GASTO',
        'monto': monto * -1,
        'referencia': descripcion ?? categoria,
        'fecha': now,
      });

      final sumaResult = await txn.rawQuery('''
        SELECT COALESCE(SUM(monto), 0) AS total
        FROM movimientos_caja
        WHERE caja_id = ?
      ''', [caja.id]);

      final esperado = (sumaResult.first['total'] as num).toDouble();

      await txn.update(
        'cajas',
        {'monto_esperado': esperado},
        where: 'id = ?',
        whereArgs: [caja.id],
      );
    });

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'GASTO',
      tablaAfectada: 'gastos',
      registroId: caja.id,
      detalle:
          '$categoria por \$${monto.toStringAsFixed(2)}${descripcion == null || descripcion.isEmpty ? '' : ' - $descripcion'}',
    );
  }

  Future<void> cerrarCaja({
    required double montoContado,
    int? usuarioId,
  }) async {
    final db = await _dbService.database;

    final caja = await obtenerCajaAbierta();
    if (caja == null) {
      throw Exception('No hay caja abierta');
    }

    final esperado = caja.montoEsperado;
    final diferencia = montoContado - esperado;

    final sobrante = diferencia > 0 ? diferencia : 0;
    final faltante = diferencia < 0 ? diferencia.abs() : 0;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      await txn.insert('movimientos_caja', {
        'caja_id': caja.id,
        'tipo': 'CIERRE',
        'monto': 0,
        'referencia': 'Cierre de caja',
        'fecha': now,
      });

      await txn.update(
        'cajas',
        {
          'usuario_cierre': usuarioId,
          'monto_contado': montoContado,
          'faltante': faltante,
          'sobrante': sobrante,
          'fecha_cierre': now,
          'estado': 'CERRADA',
        },
        where: 'id = ?',
        whereArgs: [caja.id],
      );
    });

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CERRAR_CAJA',
      tablaAfectada: 'cajas',
      registroId: caja.id,
      detalle:
          'Caja cerrada. Esperado \$${esperado.toStringAsFixed(2)}, contado \$${montoContado.toStringAsFixed(2)}, faltante \$${faltante.toStringAsFixed(2)}, sobrante \$${sobrante.toStringAsFixed(2)}',
    );
  }

  Future<List<MovimientoCaja>> obtenerMovimientosCaja(int cajaId) async {
    final db = await _dbService.database;

    final result = await db.query(
      'movimientos_caja',
      where: 'caja_id = ?',
      whereArgs: [cajaId],
      orderBy: 'fecha ASC',
    );

    return result.map((map) => MovimientoCaja.fromMap(map)).toList();
  }

  Future<List<Caja>> obtenerHistorialCajas() async {
    final db = await _dbService.database;

    final result = await db.query(
      'cajas',
      orderBy: 'fecha_apertura DESC',
    );

    return result.map((map) => Caja.fromMap(map)).toList();
  }
}