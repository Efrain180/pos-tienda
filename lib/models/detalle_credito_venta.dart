class DetalleCreditoVenta {
  final String producto;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;

  final double? cantidadMostrada;
  final String? nombrePresentacion;

  DetalleCreditoVenta({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.cantidadMostrada,
    this.nombrePresentacion,
  });

  factory DetalleCreditoVenta.fromMap(
    Map<String, dynamic> map,
  ) {
    return DetalleCreditoVenta(
      producto: map['producto'] ?? '',
      cantidad: (map['cantidad'] ?? 0).toDouble(),
      cantidadMostrada:
          map['cantidad_mostrada'] == null
              ? null
              : (map['cantidad_mostrada'] as num)
                    .toDouble(),
      nombrePresentacion:
          map['nombre_presentacion']?.toString(),
      precioUnitario:
          (map['precio_unitario'] ?? 0).toDouble(),
      subtotal:
          (map['subtotal'] ?? 0).toDouble(),
    );
  }

  double get cantidadVisual =>
      cantidadMostrada ?? cantidad;

  String get nombreVisual =>
      nombrePresentacion == null ||
              nombrePresentacion!.isEmpty
          ? producto
          : '$producto - $nombrePresentacion';
}