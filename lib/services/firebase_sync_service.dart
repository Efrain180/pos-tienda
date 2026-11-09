import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database/database_service.dart';
import 'premium_guard_service.dart';

class FirebaseSyncService {
  static const String projectId = 'pos-tienda-5312b';

  final _dbService = DatabaseService.instance;

  Future<String> _obtenerNegocioId() async {
    final db = await _dbService.database;

    final result = await db.query(
      'configuracion',
      columns: ['negocio_id', 'nube_activa'],
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No existe configuración del negocio');
    }

    final nubeActiva = (result.first['nube_activa'] as int? ?? 0) == 1;
    final negocioId = result.first['negocio_id']?.toString().trim();

if (!nubeActiva) {
  throw Exception('La nube no está activa para este negocio');
}

    if (negocioId == null || negocioId.isEmpty) {
      throw Exception('No hay negocio_id configurado');
    }

    return negocioId;
  }

Future<void> sincronizarTodo() async {
  final premiumActivo =
      await PremiumGuardService().verificarPremiumOnlineYActualizarLocal();

  if (!premiumActivo) {
    throw Exception(
      'La nube está disponible solo con Premium activo. '
      'El POS seguirá funcionando en modo Básico.',
    );
  }

  await sincronizarResumen();
  await sincronizarListasUtiles();
  await sincronizarReportes();
}

  Future<void> sincronizarResumen() async {
    final db = await _dbService.database;
    final negocioId = await _obtenerNegocioId();

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioMes = DateTime(ahora.year, ahora.month, 1);

    final ventasHoyResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM ventas
      WHERE estado = 'COMPLETADA'
      AND fecha >= ?
    ''', [inicioHoy.toIso8601String()]);

    final ventasMesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM ventas
      WHERE estado = 'COMPLETADA'
      AND fecha >= ?
    ''', [inicioMes.toIso8601String()]);

    final numeroVentasHoyResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM ventas
      WHERE estado = 'COMPLETADA'
      AND fecha >= ?
    ''', [inicioHoy.toIso8601String()]);

    final fiadoPendienteResult = await db.rawQuery('''
      SELECT COALESCE(SUM(saldo_actual), 0) AS total
      FROM creditos
      WHERE estado = 'PENDIENTE'
    ''');

    final productosBajosResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM productos
      WHERE estado = 'ACTIVO'
      AND stock_actual <= stock_minimo
      AND stock_actual > 0
    ''');

    final productosAgotadosResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM productos
      WHERE estado = 'ACTIVO'
      AND stock_actual <= 0
    ''');

    final cajaAbiertaResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM cajas
      WHERE estado = 'ABIERTA'
    ''');

    await _subirDocumento(
      path: 'negocios/$negocioId/resumen/actual',
      data: {
        'ventasHoy': (ventasHoyResult.first['total'] as num).toDouble(),
        'ventasMes': (ventasMesResult.first['total'] as num).toDouble(),
        'numeroVentasHoy':
            (numeroVentasHoyResult.first['total'] as num).toInt(),
        'fiadoPendiente':
            (fiadoPendienteResult.first['total'] as num).toDouble(),
        'productosBajos':
            (productosBajosResult.first['total'] as num).toInt(),
        'productosAgotados':
            (productosAgotadosResult.first['total'] as num).toInt(),
        'cajaAbierta':
            ((cajaAbiertaResult.first['total'] as num).toInt()) > 0,
        'ultimaSync': ahora.toIso8601String(),
      },
    );
  }

  Future<void> sincronizarReportes() async {
    final negocioId = await _obtenerNegocioId();

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana =
        inicioHoy.subtract(Duration(days: inicioHoy.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month, 1);

    await _sincronizarReportePeriodo(
      negocioId: negocioId,
      nombre: 'hoy',
      inicio: inicioHoy,
    );

    await _sincronizarReportePeriodo(
      negocioId: negocioId,
      nombre: 'semana',
      inicio: inicioSemana,
    );

    await _sincronizarReportePeriodo(
      negocioId: negocioId,
      nombre: 'mes',
      inicio: inicioMes,
    );
  }

  Future<void> _sincronizarReportePeriodo({
    required String negocioId,
    required String nombre,
    required DateTime inicio,
  }) async {
    final db = await _dbService.database;

    final ventasResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(total), 0) AS ventas,
        COUNT(*) AS numero_ventas,
        COALESCE(AVG(total), 0) AS ticket_promedio
      FROM ventas
      WHERE estado = 'COMPLETADA'
        AND fecha >= ?
    ''', [inicio.toIso8601String()]);

    final costoResult = await db.rawQuery('''
      SELECT COALESCE(SUM(cl.cantidad * li.costo_unitario), 0) AS costo
      FROM consumo_lotes cl
      INNER JOIN lotes_inventario li ON li.id = cl.lote_id
      INNER JOIN detalle_venta dv ON dv.id = cl.detalle_venta_id
      INNER JOIN ventas v ON v.id = dv.venta_id
      WHERE v.estado = 'COMPLETADA'
        AND v.fecha >= ?
    ''', [inicio.toIso8601String()]);

    final gastosResult = await db.rawQuery('''
      SELECT COALESCE(SUM(monto), 0) AS total
      FROM gastos
      WHERE fecha >= ?
    ''', [inicio.toIso8601String()]);

    final mermasResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM mermas
      WHERE fecha >= ?
    ''', [inicio.toIso8601String()]);

    final productosVendidos = await db.rawQuery('''
      SELECT 
        p.nombre AS producto,
        COALESCE(SUM(dv.cantidad_mostrada), SUM(dv.cantidad)) AS cantidad,
        COALESCE(SUM(dv.subtotal), 0) AS total
      FROM detalle_venta dv
      INNER JOIN ventas v ON v.id = dv.venta_id
      INNER JOIN productos p ON p.id = dv.producto_id
      WHERE v.estado = 'COMPLETADA'
        AND v.fecha >= ?
      GROUP BY p.id
      ORDER BY cantidad DESC
      LIMIT 10
    ''', [inicio.toIso8601String()]);

    final ventas = (ventasResult.first['ventas'] as num).toDouble();
    final costoVentas = (costoResult.first['costo'] as num).toDouble();
    final gastos = (gastosResult.first['total'] as num).toDouble();

    final utilidadBruta = ventas - costoVentas;
    final margenBruto = ventas <= 0 ? 0.0 : (utilidadBruta / ventas) * 100;
    final utilidadNeta = utilidadBruta - gastos;

    await _subirDocumento(
      path: 'negocios/$negocioId/reportes/$nombre',
      data: {
        'ventas': ventas,
        'ventasNetas': ventas,
        'costoVentas': costoVentas,
        'utilidadBruta': utilidadBruta,
        'margenBruto': margenBruto,
        'gastos': gastos,
        'utilidadNeta': utilidadNeta,
        'numeroVentas': (ventasResult.first['numero_ventas'] as num).toInt(),
        'ticketPromedio':
            (ventasResult.first['ticket_promedio'] as num).toDouble(),
        'numeroMermas': (mermasResult.first['total'] as num).toInt(),
        'productosMasVendidos': productosVendidos,
        'fechaInicio': inicio.toIso8601String(),
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> sincronizarListasUtiles() async {
    final db = await _dbService.database;
    final negocioId = await _obtenerNegocioId();

final auditoriaReciente = await db.rawQuery('''
  SELECT 
    a.id,
    a.accion,
    a.tabla_afectada,
    a.registro_id,
    a.fecha,
    u.nombre AS usuario
  FROM auditoria a
  LEFT JOIN usuarios u ON u.id = a.usuario_id
  ORDER BY a.fecha DESC
  LIMIT 30
''');


    final productosBajos = await db.rawQuery('''
      SELECT id, nombre, stock_actual, stock_minimo, unidad_medida
      FROM productos
      WHERE estado = 'ACTIVO'
        AND stock_actual <= stock_minimo
        AND stock_actual > 0
      ORDER BY stock_actual ASC
      LIMIT 30
    ''');

    final productosAgotados = await db.rawQuery('''
      SELECT id, nombre, stock_actual, stock_minimo, unidad_medida
      FROM productos
      WHERE estado = 'ACTIVO'
        AND stock_actual <= 0
      ORDER BY nombre ASC
      LIMIT 30
    ''');

    final fiadosPendientes = await db.rawQuery('''
      SELECT 
        cr.id,
        cr.venta_id,
        cr.monto_original,
        cr.saldo_actual,
        cr.fecha,
        c.nombre AS cliente
      FROM creditos cr
      INNER JOIN clientes c ON c.id = cr.cliente_id
      WHERE cr.estado = 'PENDIENTE'
        AND cr.saldo_actual > 0
      ORDER BY cr.fecha DESC
      LIMIT 30
    ''');

    final fiadosPendientesConDetalle = <Map<String, dynamic>>[];

    for (final fiado in fiadosPendientes) {
      final ventaId = fiado['venta_id'] as int;

      fiadosPendientesConDetalle.add({
        ...fiado,
        'detalles': await _detallesVenta(ventaId),
      });
    }

    final ventasRecientes = await db.rawQuery('''
      SELECT 
        v.id,
        v.fecha,
        v.tipo_venta,
        v.total,
        c.nombre AS cliente
      FROM ventas v
      INNER JOIN clientes c ON c.id = v.cliente_id
      WHERE v.estado = 'COMPLETADA'
      ORDER BY v.fecha DESC
      LIMIT 30
    ''');

final ventasRecientesConDetalle = ventasRecientes;

    final cajaActual = await db.rawQuery('''
      SELECT 
        id,
        monto_inicial,
        monto_esperado,
        fecha_apertura,
        estado
      FROM cajas
      WHERE estado = 'ABIERTA'
      ORDER BY fecha_apertura DESC
      LIMIT 1
    ''');

    final gastosRecientes = await db.rawQuery('''
      SELECT
        id,
        categoria,
        descripcion,
        monto,
        fecha
      FROM gastos
      ORDER BY fecha DESC
      LIMIT 30
    ''');

    final mermasRecientes = await db.rawQuery('''
      SELECT 
        m.id,
        m.producto_id,
        p.nombre AS producto,
        m.cantidad,
        m.motivo,
        m.fecha
      FROM mermas m
      LEFT JOIN productos p ON p.id = m.producto_id
      ORDER BY m.fecha DESC
      LIMIT 30
    ''');

    final movimientosCaja = await db.rawQuery('''
      SELECT id, caja_id, tipo, monto, referencia, fecha
      FROM movimientos_caja
      ORDER BY fecha DESC
      LIMIT 30
    ''');


    await _subirDocumento(
      path: 'negocios/$negocioId/listas/productos_bajos',
      data: {
        'items': productosBajos,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );

    await _subirDocumento(
      path: 'negocios/$negocioId/listas/productos_agotados',
      data: {
        'items': productosAgotados,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );
    await _subirDocumento(
  path: 'negocios/$negocioId/listas/auditoria_reciente',
  data: {
    'items': auditoriaReciente,
    'ultimaSync': DateTime.now().toIso8601String(),
  },
);

    await _subirDocumento(
      path: 'negocios/$negocioId/listas/fiados_pendientes',
      data: {
        'items': fiadosPendientesConDetalle,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );

    await _subirDocumento(
      path: 'negocios/$negocioId/listas/ventas_recientes',
      data: {
        'items': ventasRecientesConDetalle,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );

    await _subirDocumento(
      path: 'negocios/$negocioId/listas/caja_actual',
      data: {
        'items': cajaActual,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );

    await _subirDocumento(
      path: 'negocios/$negocioId/listas/gastos_recientes',
      data: {
        'items': gastosRecientes,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );

    await _subirDocumento(
      path: 'negocios/$negocioId/listas/mermas_recientes',
      data: {
        'items': mermasRecientes,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );

    await _subirDocumento(
      path: 'negocios/$negocioId/listas/movimientos_caja',
      data: {
        'items': movimientosCaja,
        'ultimaSync': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> _detallesVenta(int ventaId) async {
    final db = await _dbService.database;

    return await db.rawQuery('''
      SELECT 
        p.nombre AS producto,
        dv.cantidad,
        dv.cantidad_mostrada,
        dv.nombre_presentacion,
        dv.precio_unitario,
        dv.subtotal
      FROM detalle_venta dv
      INNER JOIN productos p ON p.id = dv.producto_id
      WHERE dv.venta_id = ?
      ORDER BY dv.id ASC
    ''', [ventaId]);
  }

  Future<void> _subirDocumento({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$path',
    );

    final body = {
      'fields': data.map(
        (key, value) => MapEntry(
          key,
          _valorFirestore(value),
        ),
      ),
    };

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error Firebase ${response.statusCode}: ${response.body}',
      );
    }
  }

  Map<String, dynamic> _valorFirestore(dynamic value) {
    if (value is int) {
      return {'integerValue': value.toString()};
    }

    if (value is double) {
      return {'doubleValue': value};
    }

    if (value is num) {
      return {'doubleValue': value.toDouble()};
    }

    if (value is bool) {
      return {'booleanValue': value};
    }

    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map(_valorFirestore).toList(),
        },
      };
    }

    if (value is Map) {
      return {
        'mapValue': {
          'fields': value.map(
            (key, val) => MapEntry(
              key.toString(),
              _valorFirestore(val),
            ),
          ),
        },
      };
    }

    return {'stringValue': value?.toString() ?? ''};
  }
}