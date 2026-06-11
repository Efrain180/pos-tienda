import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../services/cliente_service.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteService _service = ClienteService();

  List<Cliente> _clientes = [];
  bool _cargando = false;

  List<Cliente> get clientes => _clientes;
  bool get cargando => _cargando;

  Future<void> cargarClientes() async {
    _cargando = true;
    notifyListeners();

    _clientes = await _service.obtenerClientes();

    _cargando = false;
    notifyListeners();
  }

  Future<void> crearCliente(
    Cliente cliente, {
    required int usuarioId,
  }) async {
    await _service.crearCliente(
      cliente,
      usuarioId: usuarioId,
    );

    await cargarClientes();
  }

  Future<void> actualizarCliente(
    Cliente cliente, {
    required int usuarioId,
  }) async {
    await _service.actualizarCliente(
      cliente,
      usuarioId: usuarioId,
    );

    await cargarClientes();
  }

  Future<void> bloquearCredito(
    int clienteId,
    bool bloqueado, {
    required int usuarioId,
  }) async {
    await _service.bloquearCredito(
      clienteId,
      bloqueado,
      usuarioId: usuarioId,
    );

    await cargarClientes();
  }

  Future<double> obtenerSaldoPendiente(int clienteId) {
    return _service.obtenerSaldoPendiente(clienteId);
  }
}