import '../database/database_service.dart';
import '../models/detalle_venta.dart';
import '../models/pago_venta.dart';
import '../models/venta.dart';
import 'auditoria_service.dart';
import 'firebase_sync_service.dart';

class VentaService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> registrarVenta({
    required Venta venta,
    required List<DetalleVenta> detalles,
    required List<PagoVenta> pagos,
  }) async {
    final db = await _dbService.database;

final ventaId = await db.transaction((txn) async {
      for (final detalle in detalles) {
        final producto = await txn.query(
          'productos',
          columns: ['stock_actual', 'nombre'],
          where: 'id = ?',
          whereArgs: [detalle.productoId],
          limit: 1,
        );

        if (producto.isEmpty) throw Exception('Producto no encontrado');

        final stockActual = (producto.first['stock_actual'] as num).toDouble();

        if (stockActual < detalle.cantidad) {
          throw Exception('Stock insuficiente para ${producto.first['nombre']}');
        }
      }

      final ventaId = await txn.insert('ventas', venta.toMap());

      for (final detalle in detalles) {
final detalleVentaId = await txn.insert('detalle_venta', {
  'venta_id': ventaId,
  'producto_id': detalle.productoId,
  'cantidad': detalle.cantidad,
  'cantidad_mostrada': detalle.cantidadMostrada ?? detalle.cantidad,
  'nombre_presentacion': detalle.nombrePresentacion,
  'factor_conversion': detalle.factorConversion ?? 1,
  'precio_unitario': detalle.precioUnitario,
  'descuento': detalle.descuento,
  'subtotal': detalle.subtotal,
});
        double pendiente = detalle.cantidad;

        final lotes = await txn.query(
          'lotes_inventario',
          where: 'producto_id = ? AND cantidad_disponible > 0',
          whereArgs: [detalle.productoId],
          orderBy: 'fecha_entrada ASC, id ASC',
        );

        for (final lote in lotes) {
          if (pendiente <= 0) break;

          final loteId = lote['id'] as int;
          final disponible = (lote['cantidad_disponible'] as num).toDouble();
          final tomada = disponible >= pendiente ? pendiente : disponible;

          await txn.update(
            'lotes_inventario',
            {'cantidad_disponible': disponible - tomada},
            where: 'id = ?',
            whereArgs: [loteId],
          );

          await txn.insert('consumo_lotes', {
            'detalle_venta_id': detalleVentaId,
            'lote_id': loteId,
            'cantidad': tomada,
          });

          pendiente -= tomada;
        }

        if (pendiente > 0) {
          throw Exception('No hay lotes suficientes para completar la venta');
        }

        await txn.rawUpdate(
          '''
          UPDATE productos
          SET stock_actual = stock_actual - ?,
              fecha_actualizacion = ?
          WHERE id = ?
          ''',
          [
            detalle.cantidad,
            DateTime.now().toIso8601String(),
            detalle.productoId,
          ],
        );

        await txn.insert('movimientos_inventario', {
          'producto_id': detalle.productoId,
          'tipo': 'VENTA',
          'cantidad': detalle.cantidad * -1,
          'usuario_id': venta.usuarioId,
          'referencia': 'VENTA #$ventaId',
          'fecha': venta.fecha,
        });
      }

      for (final pago in pagos) {
        await txn.insert('pagos_venta', {
          'venta_id': ventaId,
          'tipo_pago': pago.tipoPago,
          'monto': pago.monto,
          'referencia': pago.referencia,
        });
      }

      if (venta.tipoVenta == 'CREDITO') {
        final creditoId = await txn.insert('creditos', {
          'cliente_id': venta.clienteId,
          'venta_id': ventaId,
          'monto_original': venta.total,
          'saldo_actual': venta.total,
          'estado': 'PENDIENTE',
          'fecha': venta.fecha,
        });

        await txn.insert('movimientos_credito', {
          'credito_id': creditoId,
          'tipo': 'CARGO',
          'monto': venta.total,
          'usuario_id': venta.usuarioId,
          'fecha': venta.fecha,
        });
      }
if (venta.tipoVenta == 'CONTADO') {
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
    'tipo': 'VENTA_EFECTIVO',
    'monto': venta.total,
    'referencia': 'VENTA #$ventaId',
    'fecha': venta.fecha,
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
}

      return ventaId;
    });
    await _auditoriaService.registrar(
  usuarioId: venta.usuarioId,
  accion: 'VENTA',
  tablaAfectada: 'ventas',
  registroId: ventaId,
  detalle: 'Venta ${venta.tipoVenta} por \$${venta.total.toStringAsFixed(2)}',
);
try {
  FirebaseSyncService().sincronizarTodo().catchError((_) {});

} catch (_) {}

return ventaId;
  }

Future<List<Venta>> obtenerVentas({
  int limit = 50,
  int offset = 0,
  String busqueda = '',
}) async {
  final db = await _dbService.database;

  final texto = busqueda.trim();

  if (texto.isEmpty) {
    final result = await db.query(
      'ventas',
      orderBy: 'fecha DESC',
      limit: limit,
      offset: offset,
    );

    return result.map((map) => Venta.fromMap(map)).toList();
  }

  final ventaId = int.tryParse(texto.replaceAll('#', ''));

  final result = await db.rawQuery('''
    SELECT v.*
    FROM ventas v
    INNER JOIN clientes c ON c.id = v.cliente_id
    WHERE 
      (? IS NOT NULL AND v.id = ?)
      OR c.nombre LIKE ?
      OR v.tipo_venta LIKE ?
    ORDER BY v.fecha DESC
    LIMIT ?
    OFFSET ?
  ''', [
    ventaId,
    ventaId,
    '%$texto%',
    '%$texto%',
    limit,
    offset,
  ]);

  return result.map((map) => Venta.fromMap(map)).toList();
}

  Future<List<DetalleVenta>> obtenerDetallesVenta(int ventaId) async {
    final db = await _dbService.database;

    final result = await db.query(
      'detalle_venta',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );

    return result.map((map) => DetalleVenta.fromMap(map)).toList();
  }
}