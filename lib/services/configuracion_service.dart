import '../database/database_service.dart';
import '../models/configuracion.dart';
import 'auditoria_service.dart';


class ConfiguracionService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<Configuracion> obtenerConfiguracion() async {
    final db = await _dbService.database;

    final result = await db.query(
      'configuracion',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Configuracion.fromMap(result.first);
    }

    final config = Configuracion(
      nombreNegocio: 'Mi tienda',
      telefono: null,
      direccion: null,
      usaFifo: true,
      usaFiados: true,
      stockMinimoGlobal: 5,
      impresoraTickets: null,
      firebaseActivo: false,
      margenGananciaDefault: 25,
    );

    final id = await db.insert('configuracion', config.toMap());

    return Configuracion(
      id: id,
      nombreNegocio: config.nombreNegocio,
      telefono: config.telefono,
      direccion: config.direccion,
      usaFifo: config.usaFifo,
      usaFiados: config.usaFiados,
      stockMinimoGlobal: config.stockMinimoGlobal,
      impresoraTickets: config.impresoraTickets,
      firebaseActivo: config.firebaseActivo,
      margenGananciaDefault: config.margenGananciaDefault,
    );
  }

  Future<void> guardarConfiguracion(Configuracion config) async {
    final db = await _dbService.database;

    if (config.id == null) {
      final id = await db.insert('configuracion', config.toMap());
      
      await _auditoriaService.registrar(
        accion: 'CAMBIO_CONFIGURACION',
        tablaAfectada: 'configuracion',
        registroId: id,
        detalle: 'Configuración creada: ${config.nombreNegocio}',
      );
      return;
    }

    final result = await db.update(
      'configuracion',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
    
    await _auditoriaService.registrar(
      accion: 'CAMBIO_CONFIGURACION',
      tablaAfectada: 'configuracion',
      registroId: config.id,
      detalle: 'Configuración actualizada: ${config.nombreNegocio}',
    );
  }
}