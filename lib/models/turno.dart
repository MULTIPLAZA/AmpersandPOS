class Turno {
  final int? id;
  final double efectivoInicial;
  final String estado; // 'ABIERTO', 'CERRADO'
  final String fechaApertura; // ISO datetime
  final String terminal;

  const Turno({
    this.id,
    required this.efectivoInicial,
    this.estado = 'ABIERTO',
    required this.fechaApertura,
    required this.terminal,
  });

  Turno copyWith({
    int? id,
    double? efectivoInicial,
    String? estado,
    String? fechaApertura,
    String? terminal,
  }) {
    return Turno(
      id: id ?? this.id,
      efectivoInicial: efectivoInicial ?? this.efectivoInicial,
      estado: estado ?? this.estado,
      fechaApertura: fechaApertura ?? this.fechaApertura,
      terminal: terminal ?? this.terminal,
    );
  }

  /// Converts this Turno to a SQLite row map.
  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'efectivo_inicial': efectivoInicial,
      'estado': estado,
      'fecha_apertura': fechaApertura,
      'terminal': terminal,
    };
  }

  /// Creates a Turno from a SQLite row map.
  factory Turno.fromDb(Map<String, dynamic> map) {
    return Turno(
      id: map['id'] as int?,
      efectivoInicial: (map['efectivo_inicial'] as num?)?.toDouble() ?? 0.0,
      estado: (map['estado'] as String?) ?? 'ABIERTO',
      fechaApertura:
          (map['fecha_apertura'] as String?) ?? DateTime.now().toIso8601String(),
      terminal: (map['terminal'] as String?) ?? '',
    );
  }

  /// Creates a Turno from a Supabase row (tabla pos_turno de mi-pos).
  factory Turno.fromSupabase(Map<String, dynamic> json) {
    return Turno(
      id: (json['id'] as num?)?.toInt(),
      efectivoInicial: (json['efectivo_inicial'] as num?)?.toDouble() ?? 0.0,
      estado: (json['estado'] as String?) ?? 'ABIERTO',
      fechaApertura: (json['fecha_apertura'] as String?) ?? DateTime.now().toIso8601String(),
      terminal: (json['terminal'] as String?) ?? '',
    );
  }
}
