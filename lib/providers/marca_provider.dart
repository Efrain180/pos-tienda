import 'package:flutter/material.dart';

import '../models/marca.dart';
import '../services/marca_service.dart';

class MarcaProvider extends ChangeNotifier {
  final MarcaService _service = MarcaService();

  List<Marca> _marcas = [];
  bool _cargando = false;

  List<Marca> get marcas => _marcas;
  bool get cargando => _cargando;

  Future<void> cargarMarcas() async {
    _cargando = true;
    notifyListeners();

    _marcas = await _service.obtenerMarcas();

    _cargando = false;
    notifyListeners();
  }

  Future<void> crearMarca(
    Marca marca, {
    required int usuarioId,
  }) async {
    await _service.crearMarca(
      marca,
      usuarioId: usuarioId,
    );

    await cargarMarcas();
  }

  Future<void> actualizarMarca(
    Marca marca, {
    required int usuarioId,
  }) async {
    await _service.actualizarMarca(
      marca,
      usuarioId: usuarioId,
    );

    await cargarMarcas();
  }

  Future<void> eliminarMarca(
    int id, {
    required int usuarioId,
  }) async {
    await _service.eliminarMarca(
      id,
      usuarioId: usuarioId,
    );

    await cargarMarcas();
  }
}