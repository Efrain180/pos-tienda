class Marca {
  final int? id;
  final String nombre;

  Marca({
    this.id,
    required this.nombre,
  });

  factory Marca.fromMap(Map<String, dynamic> map) {
    return Marca(
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

  Marca copyWith({
    int? id,
    String? nombre,
  }) {
    return Marca(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }
}