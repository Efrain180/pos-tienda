class Producto {
  final int? id;
  final String? codigoBarras;
  final String? codigoInterno;
  final String nombre;
  final String? descripcion;
  final int? categoriaId;
  final int? marcaId;
  final double stockActual;
  final String unidadMedida;
  final double stockMinimo;
  final String estado;
  final String fechaCreacion;
  final String? fechaActualizacion;

  Producto({
    this.id,
    this.codigoBarras,
    this.codigoInterno,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    this.marcaId,
    required this.unidadMedida,
    required this.stockActual,
    required this.stockMinimo,
    required this.estado,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      codigoBarras: map['codigo_barras'] as String?,
      codigoInterno: map['codigo_interno'] as String?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      categoriaId: map['categoria_id'] as int?,
      marcaId: map['marca_id'] as int?,
      unidadMedida: map['unidad_medida'] as String,
      stockActual: (map['stock_actual'] as num).toDouble(),
      stockMinimo: (map['stock_minimo'] as num).toDouble(),
      estado: map['estado'] as String,
      fechaCreacion: map['fecha_creacion'] as String,
      fechaActualizacion: map['fecha_actualizacion'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo_barras': codigoBarras,
      'codigo_interno': codigoInterno,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'marca_id': marcaId,
      'unidad_medida': unidadMedida,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'estado': estado,
      'fecha_creacion': fechaCreacion,
      'fecha_actualizacion': fechaActualizacion,
    };
  }

  Producto copyWith({
    int? id,
    String? codigoBarras,
    String? codigoInterno,
    String? nombre,
    String? descripcion,
    int? categoriaId,
    int? marcaId,
    String? unidadMedida,
    double? stockActual,
    double? stockMinimo,
    String? estado,
    String? fechaCreacion,
    String? fechaActualizacion,
  }) {
    return Producto(
      id: id ?? this.id,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      codigoInterno: codigoInterno ?? this.codigoInterno,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      marcaId: marcaId ?? this.marcaId,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}