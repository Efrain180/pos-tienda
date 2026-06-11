class Credito {
  final int? id;
  final int clienteId;
  final int ventaId;
  final double montoOriginal;
  final double saldoActual;
  final String estado;
  final String fecha;

  Credito({
    this.id,
    required this.clienteId,
    required this.ventaId,
    required this.montoOriginal,
    required this.saldoActual,
    required this.estado,
    required this.fecha,
  });

  factory Credito.fromMap(Map<String, dynamic> map) {
    return Credito(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      ventaId: map['venta_id'] as int,
      montoOriginal: (map['monto_original'] as num).toDouble(),
      saldoActual: (map['saldo_actual'] as num).toDouble(),
      estado: map['estado'] as String,
      fecha: map['fecha'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'venta_id': ventaId,
      'monto_original': montoOriginal,
      'saldo_actual': saldoActual,
      'estado': estado,
      'fecha': fecha,
    };
  }
}