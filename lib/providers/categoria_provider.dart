import 'package:flutter/material.dart';

import '../models/categoria.dart';
import '../services/categoria_service.dart';

class CategoriaProvider extends ChangeNotifier {
  final CategoriaService _service = CategoriaService();

  List<Categoria> _categorias = [];
  bool _cargando = false;

  List<Categoria> get categorias => _categorias;
  bool get cargando => _cargando;

  Future<void> cargarCategorias() async {
    _cargando = true;
    notifyListeners();

    _categorias = await _service.obtenerCategorias();

    _cargando = false;
    notifyListeners();
  }

  Future<void> crearCategoria(
    Categoria categoria, {
    required int usuarioId,
  }) async {
    await _service.crearCategoria(
      categoria,
      usuarioId: usuarioId,
    );

    await cargarCategorias();
  }

  Future<void> actualizarCategoria(
    Categoria categoria, {
    required int usuarioId,
  }) async {
    await _service.actualizarCategoria(
      categoria,
      usuarioId: usuarioId,
    );

    await cargarCategorias();
  }

  Future<void> eliminarCategoria(
    int id, {
    required int usuarioId,
  }) async {
    await _service.eliminarCategoria(
      id,
      usuarioId: usuarioId,
    );

    await cargarCategorias();
  }
}