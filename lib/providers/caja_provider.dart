import 'package:flutter/material.dart';

import '../models/caja.dart';
import '../models/movimiento_caja.dart';
import '../services/caja_service.dart';

class CajaProvider extends ChangeNotifier {
  final CajaService _service = CajaService();

  Caja? _cajaAbierta;
  List<Caja> _historial = [];
  bool _cargando = false;

  Caja? get cajaAbierta => _cajaAbierta;
  List<Caja> get historial => _historial;
  bool get cargando => _cargando;


  Future<void> cargarCaja() async {
    _cargando = true;
    notifyListeners();

    _cajaAbierta = await _service.obtenerCajaAbierta();
    _historial = await _service.obtenerHistorialCajas();

    _cargando = false;
    notifyListeners();
  }

  Future<void> abrirCaja({
    required double montoInicial,
    int? usuarioId,
  }) async {
    await _service.abrirCaja(
      montoInicial: montoInicial,
      usuarioId: usuarioId,
    );

    await cargarCaja();
  }

  Future<void> registrarMovimiento({
    required String tipo,
    required double monto,
    String? referencia,
  }) async {
    await _service.registrarMovimiento(
      tipo: tipo,
      monto: monto,
      referencia: referencia,
    );

    await cargarCaja();
  }

  Future<void> registrarGasto({
    required String categoria,
    String? descripcion,
    required double monto,
    int? usuarioId,
  }) async {
    await _service.registrarGasto(
      categoria: categoria,
      descripcion: descripcion,
      monto: monto,
      usuarioId: usuarioId,
    );

    await cargarCaja();
  }

  Future<void> cerrarCaja({
    required double montoContado,
    int? usuarioId,
  }) async {
    await _service.cerrarCaja(
      montoContado: montoContado,
      usuarioId: usuarioId,
    );

    await cargarCaja();
  }

  Future<List<MovimientoCaja>> obtenerMovimientosCaja(int cajaId) {
    return _service.obtenerMovimientosCaja(cajaId);
  }
  Future<Map<String, double>> obtenerResumenCaja(int cajaId) {
  return _service.obtenerResumenCaja(cajaId);
}
}