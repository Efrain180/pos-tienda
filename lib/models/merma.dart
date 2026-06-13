class Merma {
  final int? id;
  final int productoId;
  final double cantidad;
  final String motivo;
  final bool descuentaStock;
  final int? usuarioId;
  final String fecha;

  Merma({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.motivo,
    required this.descuentaStock,
    this.usuarioId,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'cantidad': cantidad,
      'motivo': motivo,
      'descuenta_stock': descuentaStock ? 1 : 0,
      'usuario_id': usuarioId,
      'fecha': fecha,
    };
  }

  factory Merma.fromMap(Map<String, dynamic> map) {
    return Merma(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      cantidad: (map['cantidad'] as num).toDouble(),
      motivo: map['motivo'] as String,
      descuentaStock: (map['descuenta_stock'] as int? ?? 1) == 1,
      usuarioId: map['usuario_id'] as int?,
      fecha: map['fecha'] as String,
    );
  }
}