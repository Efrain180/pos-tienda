class Configuracion {
  final int? id;
  final String? nombreNegocio;
  final String? telefono;
  final String? direccion;
  final bool usaFifo;
  final bool usaFiados;
  final double stockMinimoGlobal;
  final String? impresoraTickets;
  final bool firebaseActivo;
  final double margenGananciaDefault;
  final String? negocioId;
  final bool nubeActiva;
  final String? plan;
  final String? tipoLicencia;
  

  Configuracion({
    this.id,
    this.nombreNegocio,
    this.telefono,
    this.direccion,
    required this.usaFifo,
    required this.usaFiados,
    required this.stockMinimoGlobal,
    this.impresoraTickets,
    required this.firebaseActivo,
    required this.margenGananciaDefault,
    this.negocioId,
    this.nubeActiva = false,
    this.plan,
    this.tipoLicencia,
  });

  factory Configuracion.fromMap(Map<String, dynamic> map) {
    return Configuracion(
      id: map['id'] as int?,
      nombreNegocio: map['nombre_negocio'] as String?,
      telefono: map['telefono'] as String?,
      direccion: map['direccion'] as String?,
      usaFifo: (map['usa_fifo'] as int) == 1,
      usaFiados: (map['usa_fiados'] as int) == 1,
      stockMinimoGlobal: (map['stock_minimo_global'] as num).toDouble(),
      impresoraTickets: map['impresora_tickets'] as String?,
      firebaseActivo: (map['firebase_activo'] as int) == 1,
      margenGananciaDefault:
          ((map['margen_ganancia_default'] ?? 25) as num).toDouble(),
      negocioId: map['negocio_id'] as String?,
      nubeActiva: (map['nube_activa'] as int? ?? 0) == 1,
      plan: map['plan'] as String?,
      tipoLicencia: map['tipo_licencia'] as String?,
          
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_negocio': nombreNegocio,
      'telefono': telefono,
      'direccion': direccion,
      'usa_fifo': usaFifo ? 1 : 0,
      'usa_fiados': usaFiados ? 1 : 0,
      'stock_minimo_global': stockMinimoGlobal,
      'impresora_tickets': impresoraTickets,
      'firebase_activo': firebaseActivo ? 1 : 0,
      'margen_ganancia_default': margenGananciaDefault,
      'negocio_id': negocioId,
      'nube_activa': nubeActiva ? 1 : 0,
      'plan': plan,
      'tipo_licencia': tipoLicencia,
    };
  }
}