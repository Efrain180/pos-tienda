class Venta {
  final int? id;
  final int clienteId;
  final int? usuarioId;
  final String tipoVenta;
  final double subtotal;
  final double descuento;
  final double total;
  final String estado;
  final String fecha;

  Venta({
    this.id,
    required this.clienteId,
    this.usuarioId,
    required this.tipoVenta,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.estado,
    required this.fecha,
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      usuarioId: map['usuario_id'] as int?,
      tipoVenta: map['tipo_venta'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      descuento: (map['descuento'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      estado: map['estado'] as String,
      fecha: map['fecha'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'tipo_venta': tipoVenta,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'estado': estado,
      'fecha': fecha,
    };
  }
}