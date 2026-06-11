class PrecioProducto {
  final int? id;
  final int productoId;
  final String tipoPrecio;
  final double cantidadMinima;
  final double precio;

  PrecioProducto({
    this.id,
    required this.productoId,
    required this.tipoPrecio,
    required this.cantidadMinima,
    required this.precio,
  });

  factory PrecioProducto.fromMap(Map<String, dynamic> map) {
    return PrecioProducto(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      tipoPrecio: map['tipo_precio'] as String,
      cantidadMinima: (map['cantidad_minima'] as num).toDouble(),
      precio: (map['precio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo_precio': tipoPrecio,
      'cantidad_minima': cantidadMinima,
      'precio': precio,
    };
  }
}