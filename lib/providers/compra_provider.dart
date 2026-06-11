import 'package:flutter/material.dart';

import '../models/compra.dart';
import '../models/detalle_compra.dart';
import '../services/compra_service.dart';

class CompraProvider extends ChangeNotifier {
  final CompraService _service = CompraService();

  List<Compra> _compras = [];
  bool _cargando = false;

  List<Compra> get compras => _compras;
  bool get cargando => _cargando;

  Future<void> cargarCompras() async {
    _cargando = true;
    notifyListeners();

    _compras = await _service.obtenerCompras();

    _cargando = false;
    notifyListeners();
  }

  Future<int> registrarCompra({
    required Compra compra,
    required List<DetalleCompra> detalles,
  }) async {
    final compraId = await _service.registrarCompra(
      compra: compra,
      detalles: detalles,
    );

    await cargarCompras();
    return compraId;
  }

  Future<List<DetalleCompra>> obtenerDetallesCompra(int compraId) async {
  return _service.obtenerDetallesCompra(compraId);
}
}