class Cliente {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? direccion;
  final bool permiteFiado;
  final double limiteCredito;
  final bool bloqueadoCredito;
  final String fechaRegistro;

  Cliente({
    this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
    required this.permiteFiado,
    required this.limiteCredito,
    required this.bloqueadoCredito,
    required this.fechaRegistro,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String?,
      direccion: map['direccion'] as String?,
      permiteFiado: (map['permite_fiado'] as int) == 1,
      limiteCredito: (map['limite_credito'] as num).toDouble(),
      bloqueadoCredito: (map['bloqueado_credito'] as int) == 1,
      fechaRegistro: map['fecha_registro'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'permite_fiado': permiteFiado ? 1 : 0,
      'limite_credito': limiteCredito,
      'bloqueado_credito': bloqueadoCredito ? 1 : 0,
      'fecha_registro': fechaRegistro,
    };
  }
}