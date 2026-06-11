class DetalleCompra {
  final int? id;
  final int? compraId;
  final int productoId;
  final double cantidad;
  final double costoUnitario;
  final double subtotal;
  final String? fechaCaducidad;

  DetalleCompra({
    this.id,
    this.compraId,
    required this.productoId,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
    this.fechaCaducidad,
  });

  factory DetalleCompra.fromMap(Map<String, dynamic> map) {
    return DetalleCompra(
      id: map['id'] as int?,
      compraId: map['compra_id'] as int?,
      productoId: map['producto_id'] as int,
      cantidad: (map['cantidad'] as num).toDouble(),
      costoUnitario: (map['costo_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      fechaCaducidad: map['fecha_caducidad'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compra_id': compraId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'subtotal': subtotal,
      'fecha_caducidad': fechaCaducidad,
    };
  }
}