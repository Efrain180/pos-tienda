import '../database/database_service.dart';

class TicketService {
  final _dbService = DatabaseService.instance;

  Future<Map<String, dynamic>> obtenerTicketVenta(int ventaId) async {
    final db = await _dbService.database;

    final ventaResult = await db.rawQuery('''
      SELECT 
        v.id,
        v.fecha,
        v.tipo_venta,
        v.subtotal,
        v.descuento,
        v.total,
        v.estado,
        c.nombre AS cliente
      FROM ventas v
      INNER JOIN clientes c ON c.id = v.cliente_id
      WHERE v.id = ?
      LIMIT 1
    ''', [ventaId]);

    if (ventaResult.isEmpty) {
      throw Exception('Venta no encontrada');
    }

    final detalles = await db.rawQuery('''
      SELECT 
        p.nombre AS producto,
        dv.cantidad,
        dv.cantidad_mostrada,
        dv.nombre_presentacion,
        dv.factor_conversion,
        dv.precio_unitario,
        dv.descuento,
        dv.subtotal
      FROM detalle_venta dv
      INNER JOIN productos p ON p.id = dv.producto_id
      WHERE dv.venta_id = ?
      ORDER BY dv.id ASC
    ''', [ventaId]);

    final pagos = await db.rawQuery('''
      SELECT 
        tipo_pago, 
        monto, 
        referencia
      FROM pagos_venta
      WHERE venta_id = ?
    ''', [ventaId]);

    final configResult = await db.query(
      'configuracion',
      limit: 1,
    );

    final config =
        configResult.isEmpty ? <String, dynamic>{} : configResult.first;

    return {
      'venta': ventaResult.first,
      'detalles': detalles,
      'pagos': pagos,
      'configuracion': config,
    };
  }
}