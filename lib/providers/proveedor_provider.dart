import 'package:flutter/material.dart';

import '../models/proveedor.dart';
import '../services/proveedor_service.dart';

class ProveedorProvider extends ChangeNotifier {
  final ProveedorService _service = ProveedorService();

  List<Proveedor> _proveedores = [];
  bool _cargando = false;

  List<Proveedor> get proveedores => _proveedores;
  bool get cargando => _cargando;

  Future<void> cargarProveedores() async {
    _cargando = true;
    notifyListeners();

    _proveedores = await _service.obtenerProveedores();

    _cargando = false;
    notifyListeners();
  }

  Future<void> crearProveedor(
    Proveedor proveedor, {
    required int usuarioId,
  }) async {
    await _service.crearProveedor(
      proveedor,
      usuarioId: usuarioId,
    );

    await cargarProveedores();
  }

  Future<void> actualizarProveedor(
    Proveedor proveedor, {
    required int usuarioId,
  }) async {
    await _service.actualizarProveedor(
      proveedor,
      usuarioId: usuarioId,
    );

    await cargarProveedores();
  }

  Future<void> desactivarProveedor(
    int id, {
    required int usuarioId,
  }) async {
    await _service.desactivarProveedor(
      id,
      usuarioId: usuarioId,
    );

    await cargarProveedores();
  }
}