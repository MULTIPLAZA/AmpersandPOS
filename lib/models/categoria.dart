class Categoria {
  final int id;
  final String? idLicencia;
  final String nombre;
  final String? color;
  final bool activo;

  const Categoria({
    required this.id,
    this.idLicencia,
    required this.nombre,
    this.color,
    required this.activo,
  });

  Categoria copyWith({
    int? id,
    String? idLicencia,
    String? nombre,
    String? color,
    bool? activo,
  }) {
    return Categoria(
      id: id ?? this.id,
      idLicencia: idLicencia ?? this.idLicencia,
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
      activo: activo ?? this.activo,
    );
  }

  /// Creates a Categoria from a Supabase row (tabla pos_categorias de mi-pos).
  factory Categoria.fromSupabase(Map<String, dynamic> json) {
    return Categoria(
      id: (json['id'] as num).toInt(),
      idLicencia: json['licencia_email'] as String?,
      nombre: (json['nombre'] as String?) ?? '',
      color: json['color'] as String?,
      activo: _parseBool(json['activo'] ?? true),
    );
  }

  /// Creates a Categoria from a SQLite row map.
  factory Categoria.fromDb(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int,
      idLicencia: map['id_licencia'] as String?,
      nombre: (map['nombre'] as String?) ?? '',
      color: map['color'] as String?,
      activo: (map['activo'] as int?) == 1,
    );
  }

  /// Converts this Categoria to a SQLite row map.
  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'id_licencia': idLicencia,
      'nombre': nombre,
      'color': color,
      'activo': activo ? 1 : 0,
    };
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
