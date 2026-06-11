import '../database/database_service.dart';
import '../models/cliente.dart';
import 'auditoria_service.dart';

class ClienteService {
  final _dbService = DatabaseService.instance;
  final _auditoriaService = AuditoriaService();

  Future<int> crearCliente(
    Cliente cliente, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final id = await db.insert(
      'clientes',
      cliente.toMap(),
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'CREAR_CLIENTE',
      tablaAfectada: 'clientes',
      registroId: id,
      detalle: 'Cliente creado: ${cliente.nombre}',
    );

    return id;
  }

  Future<List<Cliente>> obtenerClientes() async {
    final db = await _dbService.database;

    final result = await db.query(
      'clientes',
      orderBy: 'nombre ASC',
    );

    return result.map((map) => Cliente.fromMap(map)).toList();
  }

  Future<List<Cliente>> obtenerClientesFiado() async {
    final db = await _dbService.database;

    final result = await db.query(
      'clientes',
      where: 'permite_fiado = ? AND bloqueado_credito = ?',
      whereArgs: [1, 0],
      orderBy: 'nombre ASC',
    );

    return result.map((map) => Cliente.fromMap(map)).toList();
  }

  Future<int> actualizarCliente(
    Cliente cliente, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    final result = await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );

    await _auditoriaService.registrar(
      usuarioId: usuarioId,
      accion: 'EDITAR_CLIENTE',
      tablaAfectada: 'clientes',
      registroId: cliente.id,
      detalle: 'Cliente actualizado: ${cliente.nombre}',
    );

    return result;
  }

  Future<int> bloquearCredito(
    int clienteId,
    bool bloqueado, {
    required int usuarioId,
  }) async {
    final db = await _dbService.database;

    String nombreCliente = 'Cliente #$clienteId';

    final clienteResult = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );

    if (clienteResult.isNotEmpty) {
      nombreCliente = clienteResult.first['nombre'].toString();
    }

    final result = await db.update(
      'clientes',
      {'bloqueado_credito': bloqueado ? 1 : 0},
      where: 'id = ?',
      whereArgs: [clienteId],
    );

    if (result > 0) {
      await _auditoriaService.registrar(
        usuarioId: usuarioId,
        accion: bloqueado ? 'BLOQUEAR_CLIENTE' : 'DESBLOQUEAR_CLIENTE',
        tablaAfectada: 'clientes',
        registroId: clienteId,
        detalle: bloqueado
            ? 'Crédito bloqueado para $nombreCliente'
            : 'Crédito desbloqueado para $nombreCliente',
      );
    }

    return result;
  }

  Future<double> obtenerSaldoPendiente(int clienteId) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(saldo_actual), 0) AS saldo
      FROM creditos
      WHERE cliente_id = ?
        AND estado = 'PENDIENTE'
    ''', [clienteId]);

    return (result.first['saldo'] as num).toDouble();
  }
}