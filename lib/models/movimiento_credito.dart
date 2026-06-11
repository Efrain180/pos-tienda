class MovimientoCredito {
  final int? id;
  final int creditoId;
  final String tipo;
  final double monto;
  final int? usuarioId;
  final String fecha;

  MovimientoCredito({
    this.id,
    required this.creditoId,
    required this.tipo,
    required this.monto,
    this.usuarioId,
    required this.fecha,
  });

  factory MovimientoCredito.fromMap(Map<String, dynamic> map) {
    return MovimientoCredito(
      id: map['id'] as int?,
      creditoId: map['credito_id'] as int,
      tipo: map['tipo'] as String,
      monto: (map['monto'] as num).toDouble(),
      usuarioId: map['usuario_id'] as int?,
      fecha: map['fecha'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'credito_id': creditoId,
      'tipo': tipo,
      'monto': monto,
      'usuario_id': usuarioId,
      'fecha': fecha,
    };
  }
}