class Venta {
  final int? id;
  final int idTurno;
  final double total;
  final String metodoPago; // 'EFECTIVO', 'TARJETA', 'TRANSFERENCIA'
  final String itemsJson; // JSON string of items
  final String estado; // 'COMPLETADA', 'ANULADA'
  final String fecha; // ISO datetime string
  final bool sincronizado;

  const Venta({
    this.id,
    required this.idTurno,
    required this.total,
    required this.metodoPago,
    required this.itemsJson,
    this.estado = 'COMPLETADA',
    required this.fecha,
    this.sincronizado = false,
  });

  Venta copyWith({
    int? id,
    int? idTurno,
    double? total,
    String? metodoPago,
    String? itemsJson,
    String? estado,
    String? fecha,
    bool? sincronizado,
  }) {
    return Venta(
      id: id ?? this.id,
      idTurno: idTurno ?? this.idTurno,
      total: total ?? this.total,
      metodoPago: metodoPago ?? this.metodoPago,
      itemsJson: itemsJson ?? this.itemsJson,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// Converts this Venta to a SQLite row map.
  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'id_turno': idTurno,
      'total': total,
      'metodo_pago': metodoPago,
      'items_json': itemsJson,
      'estado': estado,
      'fecha': fecha,
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  /// Creates a Venta from a SQLite row map.
  factory Venta.fromDb(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      idTurno: map['id_turno'] as int,
      total: (map['total'] as num).toDouble(),
      metodoPago: (map['metodo_pago'] as String?) ?? 'EFECTIVO',
      itemsJson: (map['items_json'] as String?) ?? '[]',
      estado: (map['estado'] as String?) ?? 'COMPLETADA',
      fecha: (map['fecha'] as String?) ?? DateTime.now().toIso8601String(),
      sincronizado: (map['sincronizado'] as int?) == 1,
    );
  }
}
