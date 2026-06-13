import '../database/database_service.dart';

class ReporteService {
  final _dbService = DatabaseService.instance;

  Future<Map<String, double>> resumenGeneral({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT
        COALESCE((SELECT SUM(total) FROM ventas WHERE fecha >= ? AND fecha < ? AND estado='COMPLETADA'), 0) AS ventas,
        COALESCE((SELECT COUNT(*) FROM ventas WHERE fecha >= ? AND fecha < ? AND estado='COMPLETADA'), 0) AS numero_ventas,
        COALESCE((SELECT SUM(dv.cantidad)
          FROM detalle_venta dv
          INNER JOIN ventas v ON v.id = dv.venta_id
          WHERE v.fecha >= ? AND v.fecha < ? AND v.estado='COMPLETADA'), 0) AS productos_vendidos,
        COALESCE((SELECT SUM(total) FROM compras WHERE fecha >= ? AND fecha < ? AND estado='COMPLETADA'), 0) AS compras,
        COALESCE((SELECT SUM(monto) FROM gastos WHERE fecha >= ? AND fecha < ?), 0) AS gastos,
        COALESCE((SELECT SUM(saldo_actual) FROM creditos WHERE estado='PENDIENTE'), 0) AS fiado_pendiente
    ''', [
      inicio.toIso8601String(),
      fin.toIso8601String(),
      inicio.toIso8601String(),
      fin.toIso8601String(),
      inicio.toIso8601String(),
      fin.toIso8601String(),
      inicio.toIso8601String(),
      fin.toIso8601String(),
      inicio.toIso8601String(),
      fin.toIso8601String(),
    ]);

    final row = result.first;

    final ventas = (row['ventas'] as num).toDouble();
    final numeroVentas = (row['numero_ventas'] as num).toDouble();

    return {
      'ventas': ventas,
      'numero_ventas': numeroVentas,
      'ticket_promedio': numeroVentas > 0 ? ventas / numeroVentas : 0,
      'productos_vendidos': (row['productos_vendidos'] as num).toDouble(),
      'compras': (row['compras'] as num).toDouble(),
      'gastos': (row['gastos'] as num).toDouble(),
      'fiado_pendiente': (row['fiado_pendiente'] as num).toDouble(),
    };
  }

  Future<Map<String, double>> rentabilidad({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(dv.subtotal), 0) AS ventas_netas,
        COALESCE(SUM(cl.cantidad * li.costo_unitario), 0) AS costo_ventas,
        COALESCE(SUM(dv.subtotal), 0) -
        COALESCE(SUM(cl.cantidad * li.costo_unitario), 0) AS utilidad_bruta
      FROM detalle_venta dv
      INNER JOIN ventas v ON v.id = dv.venta_id
      LEFT JOIN consumo_lotes cl ON cl.detalle_venta_id = dv.id
      LEFT JOIN lotes_inventario li ON li.id = cl.lote_id
      WHERE v.fecha >= ?
        AND v.fecha < ?
        AND v.estado = 'COMPLETADA'
    ''', [
      inicio.toIso8601String(),
      fin.toIso8601String(),
    ]);

    final row = result.first;

    final ventasNetas = (row['ventas_netas'] as num).toDouble();
    final costoVentas = (row['costo_ventas'] as num).toDouble();
    final utilidadBruta = (row['utilidad_bruta'] as num).toDouble();

    return {
      'ventas_netas': ventasNetas,
      'costo_ventas': costoVentas,
      'utilidad_bruta': utilidadBruta,
      'margen_bruto': ventasNetas > 0 ? (utilidadBruta / ventasNetas) * 100 : 0,
    };
  }

  Future<List<Map<String, dynamic>>> ventasPorDia({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final db = await _dbService.database;

    return db.rawQuery('''
      SELECT 
        substr(fecha, 1, 10) AS dia,
        COALESCE(SUM(total), 0) AS total
      FROM ventas
      WHERE fecha >= ?
        AND fecha < ?
        AND estado = 'COMPLETADA'
      GROUP BY substr(fecha, 1, 10)
      ORDER BY dia ASC
    ''', [
      inicio.toIso8601String(),
      fin.toIso8601String(),
    ]);
  }
  Future<Map<String, double>> resumenMermas({
  required DateTime inicio,
  required DateTime fin,
}) async {
  final db = await _dbService.database;

  final result = await db.rawQuery('''
    SELECT
      COALESCE(SUM(m.cantidad), 0) AS cantidad_mermada,
      COALESCE(SUM(
        m.cantidad * COALESCE((
          SELECT dc.costo_unitario
          FROM detalle_compra dc
          WHERE dc.producto_id = m.producto_id
          ORDER BY dc.id DESC
          LIMIT 1
        ), 0)
      ), 0) AS valor_merma
    FROM mermas m
    WHERE m.fecha >= ?
      AND m.fecha < ?
  ''', [
    inicio.toIso8601String(),
    fin.toIso8601String(),
  ]);

  final row = result.first;

  return {
    'cantidad_mermada': (row['cantidad_mermada'] as num).toDouble(),
    'valor_merma': (row['valor_merma'] as num).toDouble(),
  };
}

Future<List<Map<String, dynamic>>> mermasPorMotivo({
  required DateTime inicio,
  required DateTime fin,
}) async {
  final db = await _dbService.database;

  return db.rawQuery('''
    SELECT
      m.motivo,
      COALESCE(SUM(m.cantidad), 0) AS cantidad,
      COALESCE(SUM(
        m.cantidad * COALESCE((
          SELECT dc.costo_unitario
          FROM detalle_compra dc
          WHERE dc.producto_id = m.producto_id
          ORDER BY dc.id DESC
          LIMIT 1
        ), 0)
      ), 0) AS total
    FROM mermas m
    WHERE m.fecha >= ?
      AND m.fecha < ?
    GROUP BY m.motivo
    ORDER BY total DESC
  ''', [
    inicio.toIso8601String(),
    fin.toIso8601String(),
  ]);
}

  Future<List<Map<String, dynamic>>> productosMasVendidos({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final db = await _dbService.database;

    return db.rawQuery('''
      SELECT 
        p.nombre AS producto,
        SUM(dv.cantidad) AS cantidad,
        SUM(dv.subtotal) AS total
      FROM detalle_venta dv
      INNER JOIN ventas v ON v.id = dv.venta_id
      INNER JOIN productos p ON p.id = dv.producto_id
      WHERE v.fecha >= ?
        AND v.fecha < ?
        AND v.estado = 'COMPLETADA'
      GROUP BY p.id
      ORDER BY cantidad DESC
      LIMIT 10
    ''', [
      inicio.toIso8601String(),
      fin.toIso8601String(),
    ]);
  }

  Future<List<Map<String, dynamic>>> productosMasRentables({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final db = await _dbService.database;

    return db.rawQuery('''
      SELECT
        p.nombre AS producto,
        COALESCE(SUM(dv.subtotal), 0) AS venta,
        COALESCE(SUM(cl.cantidad * li.costo_unitario), 0) AS costo,
        COALESCE(SUM(dv.subtotal), 0) -
        COALESCE(SUM(cl.cantidad * li.costo_unitario), 0) AS utilidad
      FROM detalle_venta dv
      INNER JOIN ventas v ON v.id = dv.venta_id
      INNER JOIN productos p ON p.id = dv.producto_id
      LEFT JOIN consumo_lotes cl ON cl.detalle_venta_id = dv.id
      LEFT JOIN lotes_inventario li ON li.id = cl.lote_id
      WHERE v.fecha >= ?
        AND v.fecha < ?
        AND v.estado = 'COMPLETADA'
      GROUP BY p.id
      ORDER BY utilidad DESC
      LIMIT 10
    ''', [
      inicio.toIso8601String(),
      fin.toIso8601String(),
    ]);
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

  Future<List<Map<String, dynamic>>> gastos({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final db = await _dbService.database;

    return db.rawQuery('''
      SELECT
        categoria,
        COALESCE(SUM(monto), 0) AS total
      FROM gastos
      WHERE fecha >= ?
        AND fecha < ?
      GROUP BY categoria
      ORDER BY total DESC
    ''', [
      inicio.toIso8601String(),
      fin.toIso8601String(),
    ]);
  }
}