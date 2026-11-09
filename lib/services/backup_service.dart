import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../database/database_service.dart';

class BackupService {
  Future<String> crearBackup() async {
    final db = await DatabaseService.instance.database;

    final dbPath = db.path;

    final carpeta = Directory(
      '${Directory.current.path}/backups',
    );

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    final fecha = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-');

    final backupPath =
        '${carpeta.path}/backup_$fecha.db';

    await File(dbPath).copy(backupPath);

    await _limpiarBackupsViejos(carpeta);

    return backupPath;
  }

  Future<void> _limpiarBackupsViejos(
    Directory carpeta,
  ) async {
    final archivos = carpeta
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();

    archivos.sort(
      (a, b) =>
          b.statSync().modified.compareTo(
                a.statSync().modified,
              ),
    );

    if (archivos.length <= 10) return;

    for (final archivo in archivos.skip(10)) {
      await archivo.delete();
    }
  }

  Future<String?> restaurarBackupDesdeArchivo() async {
  final result = await FilePicker.pickFiles(
    dialogTitle: 'Seleccionar respaldo',
    type: FileType.custom,
    allowedExtensions: ['db'],
  );

  if (result == null || result.files.single.path == null) {
    return null;
  }

  final respaldoPath = result.files.single.path!;
  final db = await DatabaseService.instance.database;
  final dbPath = db.path;

  final respaldoSeleccionado = File(respaldoPath);

  if (!await respaldoSeleccionado.exists()) {
    throw Exception('El archivo de respaldo no existe');
  }

  // Backup de emergencia antes de restaurar
  await crearBackup();

  // Cerrar la base actual
  await DatabaseService.instance.cerrarBD();

  // Reemplazar la base actual por el respaldo seleccionado
  await respaldoSeleccionado.copy(dbPath);

  return dbPath;
}

  Future<void> exportarBackupManual() async {
    final db = await DatabaseService.instance.database;

final destino = await FilePicker.saveFile(
  dialogTitle: 'Guardar respaldo',
  fileName: 'respaldo_pos_${DateTime.now().millisecondsSinceEpoch}.db',
);
    if (destino == null) return;

    await File(db.path).copy(destino);
  }
}