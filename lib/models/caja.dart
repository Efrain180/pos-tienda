class Caja {
  final int? id;
  final int? usuarioApertura;
  final int? usuarioCierre;
  final double montoInicial;
  final double montoEsperado;
  final double? montoContado;
  final double faltante;
  final double sobrante;
  final String fechaApertura;
  final String? fechaCierre;
  final String estado;

  Caja({
    this.id,
    this.usuarioApertura,
    this.usuarioCierre,
    required this.montoInicial,
    required this.montoEsperado,
    this.montoContado,
    required this.faltante,
    required this.sobrante,
    required this.fechaApertura,
    this.fechaCierre,
    required this.estado,
  });

  factory Caja.fromMap(Map<String, dynamic> map) {
    return Caja(
      id: map['id'] as int?,
      usuarioApertura: map['usuario_apertura'] as int?,
      usuarioCierre: map['usuario_cierre'] as int?,
      montoInicial: (map['monto_inicial'] as num).toDouble(),
      montoEsperado: (map['monto_esperado'] as num).toDouble(),
      montoContado: map['monto_contado'] == null
          ? null
          : (map['monto_contado'] as num).toDouble(),
      faltante: (map['faltante'] as num).toDouble(),
      sobrante: (map['sobrante'] as num).toDouble(),
      fechaApertura: map['fecha_apertura'] as String,
      fechaCierre: map['fecha_cierre'] as String?,
      estado: map['estado'] as String,
    );
  }
}