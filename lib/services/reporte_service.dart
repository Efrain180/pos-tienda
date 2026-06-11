import '../database/database_service.dart';

class ReporteService {
  final _dbService = DatabaseService.instance;

  Future<Map<String, double>> resumenGeneral() async {
    final db = await _dbService.database;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final mes = DateTime.now().toIso8601String().substring(0, 7);

    final result = await db.rawQuery('''
      SELECT
        COALESCE((SELECT SUM(total) FROM ventas WHERE substr(fecha,1,10)=? AND estado='COMPLETADA'), 0) AS ventas_hoy,
        COALESCE((SELECT SUM(total) FROM ventas WHERE substr(fecha,1,7)=? AND estado='COMPLETADA'), 0) AS ventas_mes,
        COALESCE((SELECT SUM(total) FROM compras WHERE substr(fecha,1,7)=? AND estado='COMPLETADA'), 0) AS compras_mes,
        COALESCE((SELECT SUM(monto) FROM gastos WHERE substr(fecha,1,7)=?), 0) AS gastos_mes,
        COALESCE((SELECT SUM(saldo_actual) FROM creditos WHERE estado='PENDIENTE'), 0) AS fiado_pendiente
    ''', [hoy, mes, mes, mes]);

    final row = result.first;

    return {
      'ventas_hoy': (row['ventas_hoy'] as num).toDouble(),
      'ventas_mes': (row['ventas_mes'] as num).toDouble(),
      'compras_mes': (row['compras_mes'] as num).toDouble(),
      'gastos_mes': (row['gastos_mes'] as num).toDouble(),
      'fiado_pendiente': (row['fiado_pendiente'] as num).toDouble(),
    };
  }

  Future<double> gananciaMes() async {
    final db = await _dbService.database;
    final mes = DateTime.now().toIso8601String().substring(0, 7);

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(cl.cantidad * dv.precio_unitario), 0) AS venta,
        COALESCE(SUM(cl.cantidad * li.costo_unitario), 0) AS costo
      FROM consumo_lotes cl
      INNER JOIN detalle_venta dv ON dv.id = cl.detalle_venta_id
      INNER JOIN ventas v ON v.id = dv.venta_id
      INNER JOIN lotes_inventario li ON li.id = cl.lote_id
      WHERE substr(v.fecha, 1, 7) = ?
        AND v.estado = 'COMPLETADA'
    ''', [mes]);

    final venta = (result.first['venta'] as num).toDouble();
    final costo = (result.first['costo'] as num).toDouble();

    return venta - costo;
  }

  Future<List<Map<String, dynamic>>> productosMasVendidos() async {
    final db = await _dbService.database;
    final mes = DateTime.now().toIso8601String().substring(0, 7);

    return db.rawQuery('''
      SELECT 
        p.nombre AS producto,
        SUM(dv.cantidad) AS cantidad,
        SUM(dv.subtotal) AS total
      FROM detalle_venta dv
      INNER JOIN ventas v ON v.id = dv.venta_id
      INNER JOIN productos p ON p.id = dv.producto_id
      WHERE substr(v.fecha, 1, 7) = ?
        AND v.estado = 'COMPLETADA'
      GROUP BY p.id
      ORDER BY cantidad DESC
      LIMIT 10
    ''', [mes]);
  }

  Future<List<Map<String, dynamic>>> clientesConDeuda() async {
    final db = await _dbService.database;

    return db.rawQuery('''
      SELECT
        c.nombre AS cliente,
        c.limite_credito AS limite,
        SUM(cr.saldo_actual) AS saldo
      FROM creditos cr
      INNER JOIN clientes c ON c.id = cr.cliente_id
      WHERE cr.estado = 'PENDIENTE'
      GROUP BY c.id
      ORDER BY saldo DESC
      LIMIT 10
    ''');
  }

  Future<List<Map<String, dynamic>>> gastosMes() async {
    final db = await _dbService.database;
    final mes = DateTime.now().toIso8601String().substring(0, 7);

    return db.rawQuery('''
      SELECT
        categoria,
        COALESCE(SUM(monto), 0) AS total
      FROM gastos
      WHERE substr(fecha, 1, 7) = ?
      GROUP BY categoria
      ORDER BY total DESC
    ''', [mes]);
  }
}