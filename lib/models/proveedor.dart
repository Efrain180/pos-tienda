class Proveedor {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? direccion;
  final String? contacto;
  final bool activo;

  Proveedor({
    this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
    this.contacto,
    required this.activo,
  });

  factory Proveedor.fromMap(Map<String, dynamic> map) {
    return Proveedor(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String?,
      direccion: map['direccion'] as String?,
      contacto: map['contacto'] as String?,
      activo: (map['activo'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'contacto': contacto,
      'activo': activo ? 1 : 0,
    };
  }

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? direccion,
    String? contacto,
    bool? activo,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      contacto: contacto ?? this.contacto,
      activo: activo ?? this.activo,
    );
  }
}