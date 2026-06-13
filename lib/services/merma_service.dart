import '../database/database_service.dart';
import '../models/merma.dart';
import 'auditoria_service.dart';
import 'firebase_sync_service.dart';

class MermaService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> registrarMerma(Merma merma) async {
    final db = await _dbService.database;

    final mermaId = await db.transaction((txn) async {
      final producto = await txn.query(
        'productos',
        columns: ['stock_actual', 'nombre'],
        where: 'id = ?',
        whereArgs: [merma.productoId],
        limit: 1,
      );

      if (producto.isEmpty) {
        throw Exception('Producto no encontrado');
      }

      if (merma.descuentaStock) {
        final stockActual =
            (producto.first['stock_actual'] as num).toDouble();

        if (stockActual < merma.cantidad) {
          throw Exception('Stock insuficiente para registrar merma');
        }
      }

      final id = await txn.insert('mermas', merma.toMap());

      if (merma.descuentaStock) {
        await txn.rawUpdate(
          '''
          UPDATE productos
          SET stock_actual = stock_actual - ?,
              fecha_actualizacion = ?
          WHERE id = ?
          ''',
          [
            merma.cantidad,
            DateTime.now().toIso8601String(),
            merma.productoId,
          ],
        );

        await txn.insert('movimientos_inventario', {
          'producto_id': merma.productoId,
          'tipo': 'MERMA',
          'cantidad': merma.cantidad * -1,
          'usuario_id': merma.usuarioId,
          'referencia': 'MERMA #$id - ${merma.motivo}',
          'fecha': merma.fecha,
        });
      }

      return id;
    });

    await _auditoriaService.registrar(
      usuarioId: merma.usuarioId,
      accion: 'MERMA',
      tablaAfectada: 'mermas',
      registroId: mermaId,
      detalle:
          'Merma registrada: ${merma.cantidad} unidades. Descuenta stock: ${merma.descuentaStock ? 'SI' : 'NO'}',
    );
    try {
  FirebaseSyncService().sincronizarTodo().catchError((_) {});
} catch (_) {}

    return mermaId;
  }

  Future<List<Merma>> obtenerMermas() async {
    final db = await _dbService.database;

    final result = await db.query(
      'mermas',
      orderBy: 'fecha DESC',
    );

    return result.map((map) => Merma.fromMap(map)).toList();
  }
}