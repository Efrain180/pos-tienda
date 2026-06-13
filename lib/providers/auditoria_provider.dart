import 'package:flutter/material.dart';

import '../models/auditoria.dart';
import '../services/auditoria_service.dart';

enum AuditoriaPeriodo {
  hoy,
  semana,
  mes,
  todo,
}

class AuditoriaProvider extends ChangeNotifier {
  final AuditoriaService _service = AuditoriaService();

  bool _cargando = false;
  bool _cargandoMas = false;
  bool _hayMas = true;

  final int _limite = 200;
  int _offset = 0;

  AuditoriaPeriodo _periodo = AuditoriaPeriodo.hoy;

  String? _accion;
  String? _tabla;
  String _buscar = '';

  List<Auditoria> _registros = [];

  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMas => _hayMas;

  AuditoriaPeriodo get periodo => _periodo;
  String? get accion => _accion;
  String? get tabla => _tabla;
  String get buscar => _buscar;

  List<Auditoria> get registros => _registros;

  Future<void> cargarAuditoria() async {
    _cargando = true;
    _offset = 0;
    _hayMas = true;
    notifyListeners();

    try {
      final nuevos = await _service.obtenerAuditoria(
        limit: _limite,
        offset: _offset,
        accion: _accion,
        tabla: _tabla,
        buscar: _buscar,
        inicio: _inicio,
        fin: _fin,
      );

      _registros = nuevos;
      _offset = nuevos.length;
      _hayMas = nuevos.length == _limite;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarMas() async {
    if (_cargandoMas || !_hayMas) return;

    _cargandoMas = true;
    notifyListeners();

    try {
      final nuevos = await _service.obtenerAuditoria(
        limit: _limite,
        offset: _offset,
        accion: _accion,
        tabla: _tabla,
        buscar: _buscar,
        inicio: _inicio,
        fin: _fin,
      );

      _registros.addAll(nuevos);
      _offset += nuevos.length;
      _hayMas = nuevos.length == _limite;
    } finally {
      _cargandoMas = false;
      notifyListeners();
    }
  }

  Future<void> cambiarPeriodo(AuditoriaPeriodo periodo) async {
    _periodo = periodo;
    await cargarAuditoria();
  }

  Future<void> cambiarAccion(String? accion) async {
    _accion = accion;
    await cargarAuditoria();
  }

  Future<void> cambiarTabla(String? tabla) async {
    _tabla = tabla;
    await cargarAuditoria();
  }

  Future<void> cambiarBusqueda(String value) async {
    _buscar = value;
    await cargarAuditoria();
  }

  Future<void> limpiarFiltros() async {
    _periodo = AuditoriaPeriodo.hoy;
    _accion = null;
    _tabla = null;
    _buscar = '';
    await cargarAuditoria();
  }

  DateTime? get _inicio {
    final ahora = DateTime.now();

    if (_periodo == AuditoriaPeriodo.todo) return null;

    if (_periodo == AuditoriaPeriodo.hoy) {
      return DateTime(ahora.year, ahora.month, ahora.day);
    }

    if (_periodo == AuditoriaPeriodo.semana) {
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      return hoy.subtract(Duration(days: ahora.weekday - 1));
    }

    return DateTime(ahora.year, ahora.month, 1);
  }

  DateTime? get _fin {
    final ahora = DateTime.now();

    if (_periodo == AuditoriaPeriodo.todo) return null;

    if (_periodo == AuditoriaPeriodo.hoy) {
      return DateTime(ahora.year, ahora.month, ahora.day + 1);
    }

    if (_periodo == AuditoriaPeriodo.semana) {
      return _inicio!.add(const Duration(days: 7));
    }

    return DateTime(ahora.year, ahora.month + 1, 1);
  }
}