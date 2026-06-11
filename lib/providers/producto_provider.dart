import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/producto_service.dart';

class ProductoProvider extends ChangeNotifier {
  final ProductoService _service = ProductoService();

  List<Producto> _productos = [];
  bool _cargando = false;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;

  Future<void> cargarProductos() async {
    _cargando = true;
    notifyListeners();

    _productos = await _service.obtenerProductos();

    _cargando = false;
    notifyListeners();
  }

  Future<void> buscarProductos(String texto) async {
    _cargando = true;
    notifyListeners();

    if (texto.trim().isEmpty) {
      _productos = await _service.obtenerProductos();
    } else {
      _productos = await _service.buscarProductos(texto);
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> crearProducto(
    Producto producto, {
    required int usuarioId,
  }) async {
    await _service.crearProducto(
      producto,
      usuarioId: usuarioId,
    );

    await cargarProductos();
  }

  Future<void> actualizarProducto(
    Producto producto, {
    required int usuarioId,
  }) async {
    await _service.actualizarProducto(
      producto,
      usuarioId: usuarioId,
    );

    await cargarProductos();
  }

  Future<void> cambiarEstadoProducto({
    required int productoId,
    required String estado,
    required int usuarioId,
  }) async {
    await _service.cambiarEstadoProducto(
      productoId: productoId,
      estado: estado,
      usuarioId: usuarioId,
    );

    await cargarProductos();
  }

Future<int> crearProductoConPrecio({
  required Producto producto,
  required double precioVenta,
  required int usuarioId,
}) async {
  final productoId = await _service.crearProductoConPrecio(
    producto: producto,
    precioVenta: precioVenta,
    usuarioId: usuarioId,
  );

  await cargarProductos();

  return productoId;
}

  Future<void> actualizarProductoConPrecio({
    required Producto producto,
    required double precioVenta,
    required int usuarioId,
  }) async {
    await _service.actualizarProductoConPrecio(
      producto: producto,
      precioVenta: precioVenta,
      usuarioId: usuarioId,
    );

    await cargarProductos();
  }
}