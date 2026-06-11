class MovimientoInventario {
  final int? id;
  final int productoId;
  final String tipo;
  final double cantidad;
  final int? usuarioId;
  final String? referencia;
  final String fecha;

  MovimientoInventario({
    this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    this.usuarioId,
    this.referencia,
    required this.fecha,
  });

  factory MovimientoInventario.fromMap(Map<String, dynamic> map) {
    return MovimientoInventario(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      tipo: map['tipo'] as String,
      cantidad: (map['cantidad'] as num).toDouble(),
      usuarioId: map['usuario_id'] as int?,
      referencia: map['referencia'] as String?,
      fecha: map['fecha'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo': tipo,
      'cantidad': cantidad,
      'usuario_id': usuarioId,
      'referencia': referencia,
      'fecha': fecha,
    };
  }
}