class LoteInventario {
  final int? id;
  final int productoId;
  final int? compraId;
  final double costoUnitario;
  final double cantidadInicial;
  final double cantidadDisponible;
  final String fechaEntrada;
  final String? fechaCaducidad;

  LoteInventario({
    this.id,
    required this.productoId,
    this.compraId,
    required this.costoUnitario,
    required this.cantidadInicial,
    required this.cantidadDisponible,
    required this.fechaEntrada,
    this.fechaCaducidad,
  });

  factory LoteInventario.fromMap(Map<String, dynamic> map) {
    return LoteInventario(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      compraId: map['compra_id'] as int?,
      costoUnitario: (map['costo_unitario'] as num).toDouble(),
      cantidadInicial: (map['cantidad_inicial'] as num).toDouble(),
      cantidadDisponible: (map['cantidad_disponible'] as num).toDouble(),
      fechaEntrada: map['fecha_entrada'] as String,
      fechaCaducidad: map['fecha_caducidad'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'compra_id': compraId,
      'costo_unitario': costoUnitario,
      'cantidad_inicial': cantidadInicial,
      'cantidad_disponible': cantidadDisponible,
      'fecha_entrada': fechaEntrada,
      'fecha_caducidad': fechaCaducidad,
    };
  }
}