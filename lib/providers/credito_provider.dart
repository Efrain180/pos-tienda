import 'package:flutter/material.dart';

import '../models/credito.dart';
import '../models/movimiento_credito.dart';
import '../services/credito_service.dart';

class CreditoProvider extends ChangeNotifier {
  final CreditoService _service = CreditoService();

  bool _cargando = false;

  bool get cargando => _cargando;

  Future<int> crearCreditoDesdeVenta({
    required int clienteId,
    required int ventaId,
    required double monto,
    int? usuarioId,
  }) async {
    _cargando = true;
    notifyListeners();

    try {
      return await _service.crearCreditoDesdeVenta(
        clienteId: clienteId,
        ventaId: ventaId,
        monto: monto,
        usuarioId: usuarioId,
      );
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrarAbono({
    required int creditoId,
    required double monto,
    int? usuarioId,
  }) async {
    _cargando = true;
    notifyListeners();

    try {
      await _service.registrarAbono(
        creditoId: creditoId,
        monto: monto,
        usuarioId: usuarioId,
      );
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<List<Credito>> obtenerCreditosCliente(int clienteId) {
    return _service.obtenerCreditosCliente(clienteId);
  }

  Future<List<Credito>> obtenerCreditosPendientesCliente(int clienteId) {
    return _service.obtenerCreditosPendientesCliente(clienteId);
  }

  Future<List<MovimientoCredito>> obtenerMovimientosCredito(int creditoId) {
    return _service.obtenerMovimientosCredito(creditoId);
  }

  Future<double> obtenerSaldoCliente(int clienteId) {
    return _service.obtenerSaldoCliente(clienteId);
  }
}