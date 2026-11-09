import 'package:flutter/material.dart';

import '../services/licencia_service.dart';

class LicenciaProvider extends ChangeNotifier {
  final LicenciaService _service = LicenciaService();

  LicenciaInfo? _licencia;
  bool _cargando = false;

  LicenciaInfo? get licencia => _licencia;
  bool get cargando => _cargando;

  Future<void> cargarLicencia() async {
    _cargando = true;
    notifyListeners();

    _licencia = await _service.obtenerLicencia();

    _cargando = false;
    notifyListeners();
  }
Future<String?> obtenerPlanLicenciaFirebase(String clave) async {
  return _service.obtenerPlanLicenciaFirebase(clave);
}

Future<bool> activarLicencia({
  required String clave,
  String? usuarioApp,
  String? passwordApp,
}) async {
  final ok = await _service.activarLicencia(
    clave: clave,
    usuarioApp: usuarioApp,
    passwordApp: passwordApp,
  );

  if (ok) {
    await cargarLicencia();
  }

  return ok;
}
}