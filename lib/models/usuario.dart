class Usuario {
  final int? id;
  final String nombre;
  final String usuario;
  final String passwordHash;
  final int rolId;
  final bool activo;
  final String fechaCreacion;
  final String? rolNombre;

  Usuario({
    this.id,
    required this.nombre,
    required this.usuario,
    required this.passwordHash,
    required this.rolId,
    required this.activo,
    required this.fechaCreacion,
    this.rolNombre,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      usuario: map['usuario'] as String,
      passwordHash: map['password_hash'] as String,
      rolId: map['rol_id'] as int,
      activo: (map['activo'] as int) == 1,
      fechaCreacion: map['fecha_creacion'] as String,
      rolNombre: map['rol_nombre'] as String?,
    );
  }
}