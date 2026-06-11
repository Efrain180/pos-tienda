

import '../database/database_service.dart';
import '../models/compra.dart';
import '../models/detalle_compra.dart';
import 'auditoria_service.dart';

class CompraService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

Future<int> registrarCompra({
  required Compra compra,
  required List<DetalleCompra> detalles,
}) async {
  final db = await _dbService.database;

  final compraId = await db.transaction((txn) async {
    final compraId = await txn.insert('compras', compra.toMap());

    for (final detalle in detalles) {
      final subtotal = detalle.cantidad * detalle.costoUnitario;

      await txn.insert('detalle_compra', {
        'compra_id': compraId,
        'producto_id': detalle.productoId,
        'cantidad': detalle.cantidad,
        'costo_unitario': detalle.costoUnitario,
        'subtotal': subtotal,
      });

      await txn.insert('lotes_inventario', {
        'producto_id': detalle.productoId,
        'compra_id': compraId,
        'costo_unitario': detalle.costoUnitario,
        'cantidad_inicial': detalle.cantidad,
        'cantidad_disponible': detalle.cantidad,
        'fecha_entrada': compra.fecha,
        'fecha_caducidad': detalle.fechaCaducidad,
      });

      await txn.insert('movimientos_inventario', {
        'producto_id': detalle.productoId,
        'tipo': 'COMPRA',
        'cantidad': detalle.cantidad,
        'usuario_id': compra.usuarioId,
        'referencia': 'COMPRA #$compraId',
        'fecha': compra.fecha,
      });

      await txn.rawUpdate(
        '''
        UPDATE productos
        SET stock_actual = stock_actual + ?,
            fecha_actualizacion = ?
        WHERE id = ?
        ''',
        [
          detalle.cantidad,
          DateTime.now().toIso8601String(),
          detalle.productoId,
        ],
      );
    }

    return compraId;
  });

  await _auditoriaService.registrar(
    usuarioId: compra.usuarioId,
    accion: 'COMPRA',
    tablaAfectada: 'compras',
    registroId: compraId,
    detalle: 'Compra registrada por \$${compra.total.toStringAsFixed(2)}',
  );

  return compraId;
}

  Future<List<Compra>> obtenerCompras() async {
    final db = await _dbService.database;

    final result = await db.query(
      'compras',
      orderBy: 'fecha DESC',
    );

    return result.map((map) => Compra.fromMap(map)).toList();
  }
  Future<List<DetalleCompra>> obtenerDetallesCompra(int compraId) async {
  final db = await _dbService.database;

  final result = await db.query(
    'detalle_compra',
    where: 'compra_id = ?',
    whereArgs: [compraId],
  );

  return result.map((map) => DetalleCompra.fromMap(map)).toList();
}
}