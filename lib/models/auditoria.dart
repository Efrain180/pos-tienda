class Auditoria {
  final int? id;
  final int? usuarioId;
  final String accion;
  final String tablaAfectada;
  final int? registroId;
  final String? detalle;
  final String fecha;
  final String? usuarioNombre;

  Auditoria({
    this.id,
    this.usuarioId,
    required this.accion,
    required this.tablaAfectada,
    this.registroId,
    this.detalle,
    required this.fecha,
    this.usuarioNombre,
  });

  factory Auditoria.fromMap(Map<String, dynamic> map) {
    return Auditoria(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int?,
      accion: map['accion'] as String,
      tablaAfectada: map['tabla_afectada'] as String,
      registroId: map['registro_id'] as int?,
      detalle: map['detalle'] as String?,
      fecha: map['fecha'] as String,
      usuarioNombre: map['usuario_nombre'] as String?,
    );
  }
}