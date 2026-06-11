import 'package:flutter/material.dart';

import '../models/auditoria.dart';
import '../services/auditoria_service.dart';

class AuditoriaProvider extends ChangeNotifier {
  final AuditoriaService _service = AuditoriaService();

  List<Auditoria> _registros = [];
  bool _cargando = false;

  List<Auditoria> get registros => _registros;
  bool get cargando => _cargando;

  Future<void> cargarAuditoria() async {
    _cargando = true;
    notifyListeners();

    _registros = await _service.obtenerAuditoria();

    _cargando = false;
    notifyListeners();
  }

  Future<void> registrar({
    int? usuarioId,
    required String accion,
    required String tablaAfectada,
    int? registroId,
    String? detalle,
  }) async {
    await _service.registrar(
      usuarioId: usuarioId,
      accion: accion,
      tablaAfectada: tablaAfectada,
      registroId: registroId,
      detalle: detalle,
    );

    await cargarAuditoria();
  }
}