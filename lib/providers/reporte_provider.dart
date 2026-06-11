import 'package:flutter/material.dart';

import '../services/reporte_service.dart';

class ReporteProvider extends ChangeNotifier {
  final ReporteService _service = ReporteService();

  bool _cargando = false;
  Map<String, double> _resumen = {};
  double _gananciaMes = 0;
  List<Map<String, dynamic>> _productosMasVendidos = [];
  List<Map<String, dynamic>> _clientesConDeuda = [];
  List<Map<String, dynamic>> _gastosMes = [];

  bool get cargando => _cargando;
  Map<String, double> get resumen => _resumen;
  double get gananciaMes => _gananciaMes;
  List<Map<String, dynamic>> get productosMasVendidos => _productosMasVendidos;
  List<Map<String, dynamic>> get clientesConDeuda => _clientesConDeuda;
  List<Map<String, dynamic>> get gastosMes => _gastosMes;

  Future<void> cargarReportes() async {
    _cargando = true;
    notifyListeners();

    _resumen = await _service.resumenGeneral();
    _gananciaMes = await _service.gananciaMes();
    _productosMasVendidos = await _service.productosMasVendidos();
    _clientesConDeuda = await _service.clientesConDeuda();
    _gastosMes = await _service.gastosMes();

    _cargando = false;
    notifyListeners();
  }
}