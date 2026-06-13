import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database_service.dart';

class ImportarExcelService {
  final _dbService = DatabaseService.instance;

  Future<void> seleccionarEImportarCatalogo({
    required int usuarioId,
  }) async {

final result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['xlsx'],
);

    if (result == null || result.files.single.path == null) return;

    await importarCatalogo(
      path: result.files.single.path!,
      usuarioId: usuarioId,
    );
  }

  Future<void> importarCatalogo({
    required String path,
    required int usuarioId,
  }) async {
    final bytes = File(path).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final db = await _dbService.database;

    final sheet = excel['Productos_Importar'];

    await db.transaction((txn) async {
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        String celda(int index) {
          if (index >= row.length) return '';
          return row[index]?.value?.toString().trim() ?? '';
        }

        double numero(int index) {
          return double.tryParse(celda(index).replaceAll(',', '')) ?? 0;
        }

        final codigoBarras = celda(0).isEmpty ? null : celda(0);
        final codigoInterno = celda(1).isEmpty ? null : celda(1);
        final nombre = celda(2);
        final descripcion = celda(3).isEmpty ? null : celda(3);
        final categoria = celda(4);
        final marca = celda(5);
        final unidadMedida = celda(6).isEmpty ? 'PIEZA' : celda(6);
        final stockActual = numero(7);
        final stockMinimo = numero(8);
        final estado = celda(9).isEmpty ? 'ACTIVO' : celda(9);
        final precioVenta = numero(10);
        final costoInicial = numero(11);

        if (nombre.isEmpty) continue;

        int? categoriaId;
        if (categoria.isNotEmpty) {
          await txn.insert(
            'categorias',
            {'nombre': categoria},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          final result = await txn.query(
            'categorias',
            where: 'nombre = ?',
            whereArgs: [categoria],
            limit: 1,
          );

          categoriaId = result.first['id'] as int;
        }

        int? marcaId;
        if (marca.isNotEmpty) {
          await txn.insert(
            'marcas',
            {'nombre': marca},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          final result = await txn.query(
            'marcas',
            where: 'nombre = ?',
            whereArgs: [marca],
            limit: 1,
          );

          marcaId = result.first['id'] as int;
        }

        final existente = await txn.query(
          'productos',
          where: '''
            nombre = ?
            OR codigo_barras = ?
            OR codigo_interno = ?
          ''',
          whereArgs: [
            nombre,
            codigoBarras ?? '',
            codigoInterno ?? '',
          ],
          limit: 1,
        );

        if (existente.isNotEmpty) continue;

        final now = DateTime.now().toIso8601String();

        final productoId = await txn.insert('productos', {
          'codigo_barras': codigoBarras,
          'codigo_interno': codigoInterno,
          'nombre': nombre,
          'descripcion': descripcion,
          'categoria_id': categoriaId,
          'marca_id': marcaId,
          'unidad_medida': unidadMedida,
          'stock_actual': stockActual,
          'stock_minimo': stockMinimo,
          'estado': estado,
          'fecha_creacion': now,
          'fecha_actualizacion': now,
        });

        if (precioVenta > 0) {
          await txn.insert('precios_producto', {
            'producto_id': productoId,
            'tipo_precio': 'MENUDEO',
            'cantidad_minima': 1,
            'precio': precioVenta,
          });
        }

        if (stockActual > 0 && costoInicial > 0) {
          await txn.insert('lotes_inventario', {
            'producto_id': productoId,
            'compra_id': null,
            'costo_unitario': costoInicial,
            'cantidad_inicial': stockActual,
            'cantidad_disponible': stockActual,
            'fecha_entrada': now,
            'fecha_caducidad': null,
          });

          await txn.insert('movimientos_inventario', {
            'producto_id': productoId,
            'tipo': 'IMPORTACION_INICIAL',
            'cantidad': stockActual,
            'usuario_id': usuarioId,
            'referencia': 'IMPORTACION EXCEL',
            'fecha': now,
          });
        }
      }
    });
  }
}