class DetalleVenta {
  final int? id;
  final int? ventaId;
  final int productoId;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;

  DetalleVenta({
    this.id,
    this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.subtotal,
  });

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'] as int?,
      ventaId: map['venta_id'] as int?,
      productoId: map['producto_id'] as int,
      cantidad: (map['cantidad'] as num).toDouble(),
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      descuento: (map['descuento'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'descuento': descuento,
      'subtotal': subtotal,
    };
  }
}