class Rol {
  final int? id;
  final String nombre;

  Rol({
    this.id,
    required this.nombre,
  });

  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  Rol copyWith({
    int? id,
    String? nombre,
  }) {
    return Rol(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }
}