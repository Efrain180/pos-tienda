import '../database/database_service.dart';
import '../models/producto.dart';

class DashboardService {
  final _dbService = DatabaseService.instance;

  Future<double> ventasHoy() async {
    final db = await _dbService.database;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM ventas
      WHERE substr(fecha, 1, 10) = ?
        AND estado = 'COMPLETADA'
    ''', [hoy]);

    return (result.first['total'] as num).toDouble();
  }

  Future<double> ventasMes() async {
    final db = await _dbService.database;
    final mes = DateTime.now().toIso8601String().substring(0, 7);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM ventas
      WHERE substr(fecha, 1, 7) = ?
        AND estado = 'COMPLETADA'
    ''', [mes]);

    return (result.first['total'] as num).toDouble();
  }

  Future<double> comprasMes() async {
    final db = await _dbService.database;
    final mes = DateTime.now().toIso8601String().substring(0, 7);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM compras
      WHERE substr(fecha, 1, 7) = ?
        AND estado = 'COMPLETADA'
    ''', [mes]);

    return (result.first['total'] as num).toDouble();
  }

Future<double> gananciaEstimadaMes() async {
  final db = await _dbService.database;
  final mes = DateTime.now().toIso8601String().substring(0, 7);

  final result = await db.rawQuery('''
    SELECT 
      COALESCE(SUM(cl.cantidad * dv.precio_unitario), 0) AS ventas,
      COALESCE(SUM(cl.cantidad * li.costo_unitario), 0) AS costo
    FROM consumo_lotes cl
    INNER JOIN detalle_venta dv ON dv.id = cl.detalle_venta_id
    INNER JOIN ventas v ON v.id = dv.venta_id
    INNER JOIN lotes_inventario li ON li.id = cl.lote_id
    WHERE substr(v.fecha, 1, 7) = ?
      AND v.estado = 'COMPLETADA'
  ''', [mes]);

  final ventas = (result.first['ventas'] as num).toDouble();
  final costo = (result.first['costo'] as num).toDouble();

  return ventas - costo;
}

  Future<List<Producto>> productosStockBajo() async {
    final db = await _dbService.database;

    final result = await db.query(
      'productos',
      where: 'stock_actual <= stock_minimo AND estado = ?',
      whereArgs: ['ACTIVO'],
      orderBy: 'stock_actual ASC',
    );

    return result.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> productosPorVencer({
    int dias = 30,
  }) async {
    final db = await _dbService.database;

    final hoy = DateTime.now();
    final limite = hoy.add(Duration(days: dias));

    return db.rawQuery('''
      SELECT 
        p.nombre AS producto,
        li.cantidad_disponible AS cantidad,
        li.fecha_caducidad AS fecha_caducidad
      FROM lotes_inventario li
      INNER JOIN productos p ON p.id = li.producto_id
      WHERE li.fecha_caducidad IS NOT NULL
        AND li.cantidad_disponible > 0
        AND date(substr(li.fecha_caducidad, 1, 10)) <= date(?)
      ORDER BY li.fecha_caducidad ASC
    ''', [limite.toIso8601String().substring(0, 10)]);
  }
}