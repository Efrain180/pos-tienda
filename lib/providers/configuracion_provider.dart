import 'package:flutter/material.dart';

import '../models/configuracion.dart';
import '../services/configuracion_service.dart';

class ConfiguracionProvider extends ChangeNotifier {
  final ConfiguracionService _service = ConfiguracionService();

  Configuracion? _configuracion;
  bool _cargando = false;

  Configuracion? get configuracion => _configuracion;
  bool get cargando => _cargando;

  Future<void> cargarConfiguracion() async {
    _cargando = true;
    notifyListeners();

    _configuracion = await _service.obtenerConfiguracion();

    _cargando = false;
    notifyListeners();
  }

  Future<void> guardarConfiguracion(Configuracion config) async {
    await _service.guardarConfiguracion(config);
    await cargarConfiguracion();
  }
}