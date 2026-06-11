class PagoVenta {
  final int? id;
  final int? ventaId;
  final String tipoPago;
  final double monto;
  final String? referencia;

  PagoVenta({
    this.id,
    this.ventaId,
    required this.tipoPago,
    required this.monto,
    this.referencia,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'tipo_pago': tipoPago,
      'monto': monto,
      'referencia': referencia,
    };
  }
}