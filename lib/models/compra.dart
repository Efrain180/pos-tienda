class Compra {
  final int? id;
  final int? proveedorId;
  final int? usuarioId;
  final String fecha;
  final double subtotal;
  final double descuento;
  final double total;
  final String estado;

  Compra({
    this.id,
    this.proveedorId,
    this.usuarioId,
    required this.fecha,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.estado,
  });

  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      id: map['id'] as int?,
      proveedorId: map['proveedor_id'] as int?,
      usuarioId: map['usuario_id'] as int?,
      fecha: map['fecha'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      descuento: (map['descuento'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      estado: map['estado'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proveedor_id': proveedorId,
      'usuario_id': usuarioId,
      'fecha': fecha,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'estado': estado,
    };
  }
}