import 'package:flutter/material.dart';

import '../services/reporte_service.dart';

enum ReportePeriodo {
  hoy,
  semana,
  mes,
}

class ReporteProvider extends ChangeNotifier {
  final ReporteService _service = ReporteService();

  bool _cargando = false;
  ReportePeriodo _periodo = ReportePeriodo.mes;

  Map<String, double> _resumen = {};
  Map<String, double> _rentabilidad = {};
  Map<String, double> _resumenMermas = {};

  List<Map<String, dynamic>> _ventasPorDia = [];
  List<Map<String, dynamic>> _productosMasVendidos = [];
  List<Map<String, dynamic>> _productosMasRentables = [];
  List<Map<String, dynamic>> _clientesConDeuda = [];
  List<Map<String, dynamic>> _gastos = [];
  List<Map<String, dynamic>> _mermasPorMotivo = [];

  bool get cargando => _cargando;
  ReportePeriodo get periodo => _periodo;

  Map<String, double> get resumen => _resumen;
  Map<String, double> get rentabilidad => _rentabilidad;
  Map<String, double> get resumenMermas => _resumenMermas;

  List<Map<String, dynamic>> get ventasPorDia => _ventasPorDia;
  List<Map<String, dynamic>> get productosMasVendidos => _productosMasVendidos;
  List<Map<String, dynamic>> get productosMasRentables =>
      _productosMasRentables;
  List<Map<String, dynamic>> get clientesConDeuda => _clientesConDeuda;
  List<Map<String, dynamic>> get gastosMes => _gastos;
  List<Map<String, dynamic>> get mermasPorMotivo => _mermasPorMotivo;

  // =========================
  // RESUMEN GENERAL
  // =========================

  double get ventas => _resumen['ventas'] ?? 0;
  double get compras => _resumen['compras'] ?? 0;
  double get gastos => _resumen['gastos'] ?? 0;
  double get fiadoPendiente => _resumen['fiado_pendiente'] ?? 0;
  double get ticketPromedio => _resumen['ticket_promedio'] ?? 0;
  double get numeroVentas => _resumen['numero_ventas'] ?? 0;
  double get productosVendidos => _resumen['productos_vendidos'] ?? 0;

  // =========================
  // RENTABILIDAD
  // =========================

  double get ventasNetas => _rentabilidad['ventas_netas'] ?? 0;

  double get costoVentas => _rentabilidad['costo_ventas'] ?? 0;

  double get utilidadBruta =>
      _rentabilidad['utilidad_bruta'] ?? 0;

  double get margenBruto =>
      _rentabilidad['margen_bruto'] ?? 0;

  // =========================
  // MERMAS
  // =========================

  double get cantidadMermada =>
      _resumenMermas['cantidad_mermada'] ?? 0;

  double get valorMerma =>
      _resumenMermas['valor_merma'] ?? 0;

  // =========================
  // UTILIDAD REAL DEL NEGOCIO
  // =========================

  double get utilidadNetaAprox =>
      utilidadBruta - gastos - valorMerma;

  Future<void> cambiarPeriodo(
    ReportePeriodo periodo,
  ) async {
    _periodo = periodo;
    await cargarReportes();
  }

  DateTime get _inicio {
    final ahora = DateTime.now();

    if (_periodo == ReportePeriodo.hoy) {
      return DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
      );
    }

    if (_periodo == ReportePeriodo.semana) {
      final inicioHoy = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
      );

      return inicioHoy.subtract(
        Duration(days: ahora.weekday - 1),
      );
    }

    return DateTime(
      ahora.year,
      ahora.month,
      1,
    );
  }

  DateTime get _fin {
    final ahora = DateTime.now();

    if (_periodo == ReportePeriodo.hoy) {
      return DateTime(
        ahora.year,
        ahora.month,
        ahora.day + 1,
      );
    }

    if (_periodo == ReportePeriodo.semana) {
      return _inicio.add(
        const Duration(days: 7),
      );
    }

    return DateTime(
      ahora.year,
      ahora.month + 1,
      1,
    );
  }

  Future<void> cargarReportes() async {
    _cargando = true;
    notifyListeners();

    try {
      final inicio = _inicio;
      final fin = _fin;

      _resumen = await _service.resumenGeneral(
        inicio: inicio,
        fin: fin,
      );

      _rentabilidad = await _service.rentabilidad(
        inicio: inicio,
        fin: fin,
      );

      _ventasPorDia = await _service.ventasPorDia(
        inicio: inicio,
        fin: fin,
      );

      _productosMasVendidos =
          await _service.productosMasVendidos(
        inicio: inicio,
        fin: fin,
      );

      _productosMasRentables =
          await _service.productosMasRentables(
        inicio: inicio,
        fin: fin,
      );

      _clientesConDeuda =
          await _service.clientesConDeuda();

      _gastos = await _service.gastos(
        inicio: inicio,
        fin: fin,
      );

      _resumenMermas =
          await _service.resumenMermas(
        inicio: inicio,
        fin: fin,
      );

      _mermasPorMotivo =
          await _service.mermasPorMotivo(
        inicio: inicio,
        fin: fin,
      );
    } catch (e) {
      debugPrint(
        'Error cargando reportes: $e',
      );
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}