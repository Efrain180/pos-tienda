class PresentacionProducto {
  final int? id;
  final int productoId;
  final String nombre;
  final double factorConversion;
  final double precio;
  final String? codigoBarras;
  final bool activo;

  PresentacionProducto({
    this.id,
    required this.productoId,
    required this.nombre,
    required this.factorConversion,
    required this.precio,
    this.codigoBarras,
    this.activo = true,
  });

  factory PresentacionProducto.fromMap(Map<String, dynamic> map) {
    return PresentacionProducto(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      nombre: map['nombre'] as String,
      factorConversion: (map['factor_conversion'] as num).toDouble(),
      precio: (map['precio'] as num).toDouble(),
      codigoBarras: map['codigo_barras'] as String?,
      activo: (map['activo'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'nombre': nombre,
      'factor_conversion': factorConversion,
      'precio': precio,
      'codigo_barras': codigoBarras,
      'activo': activo ? 1 : 0,
    };
  }

  PresentacionProducto copyWith({
    int? id,
    int? productoId,
    String? nombre,
    double? factorConversion,
    double? precio,
    String? codigoBarras,
    bool? activo,
  }) {
    return PresentacionProducto(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      factorConversion: factorConversion ?? this.factorConversion,
      precio: precio ?? this.precio,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      activo: activo ?? this.activo,
    );
  }
}