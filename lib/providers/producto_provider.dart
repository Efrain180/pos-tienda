import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/producto_service.dart';

class ProductoProvider extends ChangeNotifier {
  final ProductoService _service = ProductoService();

  static const int _limite = 20;

  List<Producto> _productos = [];
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _hayMas = true;

  String _busqueda = '';
  String _estado = 'TODOS';
  int _totalProductos = 0;
  int _totalActivos = 0;
  int _totalInactivos = 0;
  int _totalStockBajo = 0;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMas => _hayMas;
  String get busqueda => _busqueda;
  String get estado => _estado;

  int get totalProductos => _totalProductos;
int get totalActivos => _totalActivos;
int get totalInactivos => _totalInactivos;
int get totalStockBajo => _totalStockBajo;

Future<List<Producto>> buscarProductosParaVenta(
  String texto, {
  int limit = 30,
}) async {
  return _service.buscarProductos(
    texto,
    limit: limit,
    offset: 0,
    estado: 'ACTIVO',
  );
}

Future<Producto?> obtenerProductoPorId(int id) async {
  return _service.obtenerProductoPorId(id);
}
  Future<void> cargarProductos({
    String busqueda = '',
    String estado = 'TODOS',
  }) async {
    _cargando = true;
    _hayMas = true;
    _busqueda = busqueda.trim();
    _estado = estado;
    notifyListeners();

    await cargarResumenProductos();

    if (_busqueda.isEmpty) {
      _productos = await _service.obtenerProductos(
        limit: _limite,
        offset: 0,
        estado: _estado,
      );
    } else {
      _productos = await _service.buscarProductos(
        _busqueda,
        limit: _limite,
        offset: 0,
        estado: _estado,
      );
    }

    _hayMas = _productos.length == _limite;

    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarResumenProductos() async {
  final resumen = await _service.obtenerResumenProductos();

  _totalProductos = resumen['total'] ?? 0;
  _totalActivos = resumen['activos'] ?? 0;
  _totalInactivos = resumen['inactivos'] ?? 0;
  _totalStockBajo = resumen['stockBajo'] ?? 0;

  notifyListeners();
}

Future<List<Producto>> buscarProductosParaSeleccion(
  String texto, {
  int limit = 20,
}) async {
  return _service.buscarProductos(
    texto,
    limit: limit,
    offset: 0,
    estado: 'ACTIVO',
  );
}
  Future<void> cargarMasProductos() async {
    if (_cargandoMas || !_hayMas) return;

    _cargandoMas = true;
    notifyListeners();

    final nuevos = _busqueda.isEmpty
        ? await _service.obtenerProductos(
            limit: _limite,
            offset: _productos.length,
            estado: _estado,
          )
        : await _service.buscarProductos(
            _busqueda,
            limit: _limite,
            offset: _productos.length,
            estado: _estado,
          );

    _productos.addAll(nuevos);
    _hayMas = nuevos.length == _limite;

    _cargandoMas = false;
    notifyListeners();
  }

  Future<void> buscarProductos(String texto) async {
    await cargarProductos(
      busqueda: texto,
      estado: _estado,
    );
  }

  Future<void> filtrarPorEstado(String estado) async {
    await cargarProductos(
      busqueda: _busqueda,
      estado: estado,
    );
  }

  Future<void> crearProducto(
    Producto producto, {
    required int usuarioId,
  }) async {
    await _service.crearProducto(
      producto,
      usuarioId: usuarioId,
    );

    await cargarProductos(
      busqueda: _busqueda,
      estado: _estado,
    );
  }

  Future<void> actualizarProducto(
    Producto producto, {
    required int usuarioId,
  }) async {
    await _service.actualizarProducto(
      producto,
      usuarioId: usuarioId,
    );

    await cargarProductos(
      busqueda: _busqueda,
      estado: _estado,
    );
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

    await cargarProductos(
      busqueda: _busqueda,
      estado: _estado,
    );
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

    await cargarProductos(
      busqueda: _busqueda,
      estado: _estado,
    );

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

    await cargarProductos(
      busqueda: _busqueda,
      estado: _estado,
    );
  }
}