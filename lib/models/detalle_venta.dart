class DetalleVenta {
  final int? id;
  final int? ventaId;
  final int productoId;

  /// Cantidad real que se descuenta del inventario.
  final double cantidad;

  /// Cantidad que se muestra al cliente.
  final double? cantidadMostrada;

  /// Nombre de la presentación, ejemplo: Cartón, Caja, Paquete.
  final String? nombrePresentacion;

  /// Factor de conversión, ejemplo: 12.
  final double? factorConversion;

  final double precioUnitario;
  final double descuento;
  final double subtotal;

  DetalleVenta({
    this.id,
    this.ventaId,
    required this.productoId,
    required this.cantidad,
    this.cantidadMostrada,
    this.nombrePresentacion,
    this.factorConversion,
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
      cantidadMostrada: map['cantidad_mostrada'] == null
          ? null
          : (map['cantidad_mostrada'] as num).toDouble(),
      nombrePresentacion: map['nombre_presentacion'] as String?,
      factorConversion: map['factor_conversion'] == null
          ? null
          : (map['factor_conversion'] as num).toDouble(),
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
      'cantidad_mostrada': cantidadMostrada,
      'nombre_presentacion': nombrePresentacion,
      'factor_conversion': factorConversion,
      'precio_unitario': precioUnitario,
      'descuento': descuento,
      'subtotal': subtotal,
    };
  }

  double get cantidadParaMostrar => cantidadMostrada ?? cantidad;

  String get textoPresentacion {
    if (nombrePresentacion == null || nombrePresentacion!.trim().isEmpty) {
      return '';
    }

    return nombrePresentacion!;
  }
}