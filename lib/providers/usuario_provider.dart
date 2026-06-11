import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final UsuarioService _service = UsuarioService();

  List<Usuario> _usuarios = [];
  List<Map<String, dynamic>> _roles = [];
  bool _cargando = false;

  List<Usuario> get usuarios => _usuarios;
  List<Map<String, dynamic>> get roles => _roles;
  bool get cargando => _cargando;

  Future<void> cargarUsuarios() async {
    _cargando = true;
    notifyListeners();

    _usuarios = await _service.obtenerUsuarios();
    _roles = await _service.obtenerRoles();

    _cargando = false;
    notifyListeners();
  }

  Future<void> crearUsuario({
    required String nombre,
    required String usuario,
    required String password,
    required int rolId,
    required int usuarioId,
  }) async {
    await _service.crearUsuario(
      nombre: nombre,
      usuario: usuario,
      password: password,
      rolId: rolId,
      usuarioId: usuarioId,
    );

    await cargarUsuarios();
  }

  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String usuario,
    String? password,
    required int rolId,
    required bool activo,
    required int usuarioId,
  }) async {
    await _service.actualizarUsuario(
      id: id,
      nombre: nombre,
      usuario: usuario,
      password: password,
      rolId: rolId,
      activo: activo,
      usuarioId: usuarioId,
    );

    await cargarUsuarios();
  }
}