import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  Usuario? _usuarioActual;
  List<String> _permisos = [];
  bool _cargando = false;

  Usuario? get usuarioActual => _usuarioActual;
  List<String> get permisos => _permisos;
  bool get cargando => _cargando;
  bool get autenticado => _usuarioActual != null;

  bool tienePermiso(String codigo) {
    return _permisos.contains(codigo);
  }

  Future<bool> login({
    required String usuario,
    required String password,
  }) async {
    _cargando = true;
    notifyListeners();

    final user = await _service.login(
      usuario: usuario,
      password: password,
    );

    if (user == null) {
      _cargando = false;
      notifyListeners();
      return false;
    }

    _usuarioActual = user;
    _permisos = await _service.obtenerPermisosUsuario(user.id!);

    _cargando = false;
    notifyListeners();

    return true;
  }

  void logout() {
    _usuarioActual = null;
    _permisos = [];
    notifyListeners();
  }
}