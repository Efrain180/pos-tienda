class MovimientoCaja {
  final int? id;
  final int? cajaId;
  final String tipo;
  final double monto;
  final String? referencia;
  final String fecha;

  MovimientoCaja({
    this.id,
    this.cajaId,
    required this.tipo,
    required this.monto,
    this.referencia,
    required this.fecha,
  });

  factory MovimientoCaja.fromMap(Map<String, dynamic> map) {
    return MovimientoCaja(
      id: map['id'] as int?,
      cajaId: map['caja_id'] as int?,
      tipo: map['tipo'] as String,
      monto: (map['monto'] as num).toDouble(),
      referencia: map['referencia'] as String?,
      fecha: map['fecha'] as String,
    );
  }
}