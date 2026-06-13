import '../database/database_service.dart';
import '../models/credito.dart';
import '../models/movimiento_credito.dart';
import 'auditoria_service.dart';
import '../models/detalle_credito_venta.dart';
import 'firebase_sync_service.dart';

class CreditoService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();
  

  Future<int> crearCreditoDesdeVenta({
    required int clienteId,
    required int ventaId,
    required double monto,
    int? usuarioId,
  }) async {
    final db = await _dbService.database;

    return db.transaction((txn) async {
      final creditoId = await txn.insert('creditos', {
        'cliente_id': clienteId,
        'venta_id': ventaId,
        'monto_original': monto,
        'saldo_actual': monto,
        'estado': 'PENDIENTE',
        'fecha': DateTime.now().toIso8601String(),
      });

      await txn.insert('movimientos_credito', {
        'credito_id': creditoId,
        'tipo': 'CARGO',
        'monto': monto,
        'usuario_id': usuarioId,
        'fecha': DateTime.now().toIso8601String(),
      });

      return creditoId;
    });
  }
  Future<void> liquidarDeudaCliente({
  required int clienteId,
  required int usuarioId,
}) async {
  final db = await _dbService.database;

  await db.transaction((txn) async {
    final creditos = await txn.query(
      'creditos',
      where: 'cliente_id = ? AND estado = ? AND saldo_actual > 0',
      whereArgs: [clienteId, 'PENDIENTE'],
      orderBy: 'fecha ASC',
    );

    for (final credito in creditos) {
      final creditoId = credito['id'] as int;
      final saldoActual = (credito['saldo_actual'] as num).toDouble();

      if (saldoActual <= 0) continue;

      await txn.insert('movimientos_credito', {
        'credito_id': creditoId,
        'tipo': 'ABONO',
        'monto': saldoActual,
        'fecha': DateTime.now().toIso8601String(),
        'usuario_id': usuarioId,
      });

      await txn.update(
        'creditos',
        {
          'saldo_actual': 0,
          'estado': 'PAGADO',
        },
        where: 'id = ?',
        whereArgs: [creditoId],
      );
    }
  });
}

  Future<void> registrarAbono({
    required int creditoId,
    required double monto,
    int? usuarioId,
  }) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      

      final creditoResult = await txn.query(
        'creditos',
        where: 'id = ?',
        whereArgs: [creditoId],
        limit: 1,
      );

      if (creditoResult.isEmpty) {
        throw Exception('Crédito no encontrado');
      }

      final credito = creditoResult.first;
      final saldoActual = (credito['saldo_actual'] as num).toDouble();

      if (monto <= 0) {
        throw Exception('El abono debe ser mayor a 0');
      }

      if (monto > saldoActual) {
        throw Exception('El abono no puede ser mayor al saldo');
      }

      final nuevoSaldo = saldoActual - monto;

      await txn.insert('movimientos_credito', {
        'credito_id': creditoId,
        'tipo': 'ABONO',
        'monto': monto,
        'usuario_id': usuarioId,
        'fecha': now,
      });

      await txn.update(
        'creditos',
        {
          'saldo_actual': nuevoSaldo,
          'estado': nuevoSaldo <= 0 ? 'PAGADO' : 'PENDIENTE',
        },
        where: 'id = ?',
        whereArgs: [creditoId],
      );

      final cajaResult = await txn.query(
        'cajas',
        where: 'estado = ?',
        whereArgs: ['ABIERTA'],
        orderBy: 'fecha_apertura DESC',
        limit: 1,
      );

      if (cajaResult.isEmpty) {
        throw Exception('No hay caja abierta');
      }

      final cajaId = cajaResult.first['id'] as int;

      await txn.insert('movimientos_caja', {
        'caja_id': cajaId,
        'tipo': 'ABONO_CREDITO',
        'monto': monto,
        'referencia': 'ABONO CREDITO #$creditoId',
        'fecha': now,
      });

      final sumaResult = await txn.rawQuery('''
        SELECT COALESCE(SUM(monto), 0) AS total
        FROM movimientos_caja
        WHERE caja_id = ?
      ''', [cajaId]);

      final esperado = (sumaResult.first['total'] as num).toDouble();

      await txn.update(
        'cajas',
        {'monto_esperado': esperado},
        where: 'id = ?',
        whereArgs: [cajaId],
      );
    });
    
    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'ABONO_CREDITO',
      tablaAfectada: 'creditos',
      registroId: creditoId,
      detalle: 'Abono registrado por \$${monto.toStringAsFixed(2)}',
    );
    try {
  FirebaseSyncService().sincronizarTodo().catchError((_) {});
} catch (_) {}
  }

  Future<List<Credito>> obtenerCreditosCliente(int clienteId) async {
    final db = await _dbService.database;

    final result = await db.query(
      'creditos',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha DESC',
    );

    return result.map((map) => Credito.fromMap(map)).toList();
  }
  Future<List<DetalleCreditoVenta>> obtenerDetalleVentaCredito(
  int ventaId,
) async {
  final db = await _dbService.database;

  final result = await db.rawQuery('''
    SELECT
      p.nombre AS producto,
      dv.cantidad,
      dv.cantidad_mostrada,
      dv.nombre_presentacion,
      dv.precio_unitario,
      dv.subtotal
    FROM detalle_venta dv
    INNER JOIN productos p
      ON p.id = dv.producto_id
    WHERE dv.venta_id = ?
  ''', [ventaId]);

  return result
      .map((e) => DetalleCreditoVenta.fromMap(e))
      .toList();
}
  Future<List<Credito>> obtenerCreditosPendientesCliente(int clienteId) async {
    final db = await _dbService.database;

    final result = await db.query(
      'creditos',
      where: 'cliente_id = ? AND estado = ?',
      whereArgs: [clienteId, 'PENDIENTE'],
      orderBy: 'fecha DESC',
    );

    return result.map((map) => Credito.fromMap(map)).toList();
  }

  Future<List<MovimientoCredito>> obtenerMovimientosCredito(
    int creditoId,
  ) async {
    final db = await _dbService.database;

    final result = await db.query(
      'movimientos_credito',
      where: 'credito_id = ?',
      whereArgs: [creditoId],
      orderBy: 'fecha ASC',
    );

    return result.map((map) => MovimientoCredito.fromMap(map)).toList();
  }

  Future<double> obtenerSaldoCliente(int clienteId) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(saldo_actual), 0) AS saldo
      FROM creditos
      WHERE cliente_id = ?
        AND estado = 'PENDIENTE'
    ''', [clienteId]);

    return (result.first['saldo'] as num).toDouble();
  }
}