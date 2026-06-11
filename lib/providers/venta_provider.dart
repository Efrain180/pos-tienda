import 'package:flutter/material.dart';

import '../models/detalle_venta.dart';
import '../models/pago_venta.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';

class VentaProvider extends ChangeNotifier {
  final VentaService _service = VentaService();

  List<Venta> _ventas = [];
  bool _cargando = false;

  List<Venta> get ventas => _ventas;
  bool get cargando => _cargando;

  Future<void> cargarVentas() async {
    _cargando = true;
    notifyListeners();

    _ventas = await _service.obtenerVentas();

    _cargando = false;
    notifyListeners();
  }

  Future<int> registrarVenta({
    required Venta venta,
    required List<DetalleVenta> detalles,
    required List<PagoVenta> pagos,
  }) async {
    _cargando = true;
    notifyListeners();

    try {
      final ventaId = await _service.registrarVenta(
        venta: venta,
        detalles: detalles,
        pagos: pagos,
      );

      await cargarVentas();

      return ventaId;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<List<DetalleVenta>> obtenerDetallesVenta(int ventaId) async {
    return _service.obtenerDetallesVenta(ventaId);
  }
}