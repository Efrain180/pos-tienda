import 'package:flutter/material.dart';

import '../models/detalle_venta.dart';
import '../models/pago_venta.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';

class VentaProvider extends ChangeNotifier {
  final VentaService _service = VentaService();

  final int _limite = 50;

  List<Venta> _ventas = [];
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _hayMas = true;

  List<Venta> get ventas => _ventas;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMas => _hayMas;
  String _busqueda = '';
String get busqueda => _busqueda;

Future<void> cargarVentas({String busqueda = ''}) async {
  _cargando = true;
  _hayMas = true;
  _busqueda = busqueda;
  notifyListeners();

  _ventas = await _service.obtenerVentas(
    limit: _limite,
    offset: 0,
    busqueda: _busqueda,
  );

  _hayMas = _ventas.length == _limite;

  _cargando = false;
  notifyListeners();
}

Future<void> cargarMasVentas() async {
  if (_cargandoMas || !_hayMas) return;

  _cargandoMas = true;
  notifyListeners();

  final nuevasVentas = await _service.obtenerVentas(
    limit: _limite,
    offset: _ventas.length,
    busqueda: _busqueda,
  );

  _ventas.addAll(nuevasVentas);
  _hayMas = nuevasVentas.length == _limite;

  _cargandoMas = false;
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