class Producto {
  final int id;
  final String? idLicencia;
  final String nombre;
  final double precio;
  final bool precioVariable;
  final double costo;
  final String? codigo;
  final String? codigosExtra;
  final int iva; // 0, 5 or 10
  final String? color;
  final int? idCategoria;
  final bool activo;

  const Producto({
    required this.id,
    this.idLicencia,
    required this.nombre,
    required this.precio,
    required this.precioVariable,
    required this.costo,
    this.codigo,
    this.codigosExtra,
    required this.iva,
    this.color,
    this.idCategoria,
    required this.activo,
  });

  Producto copyWith({
    int? id,
    String? idLicencia,
    String? nombre,
    double? precio,
    bool? precioVariable,
    double? costo,
    String? codigo,
    String? codigosExtra,
    int? iva,
    String? color,
    int? idCategoria,
    bool? activo,
  }) {
    return Producto(
      id: id ?? this.id,
      idLicencia: idLicencia ?? this.idLicencia,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      precioVariable: precioVariable ?? this.precioVariable,
      costo: costo ?? this.costo,
      codigo: codigo ?? this.codigo,
      codigosExtra: codigosExtra ?? this.codigosExtra,
      iva: iva ?? this.iva,
      color: color ?? this.color,
      idCategoria: idCategoria ?? this.idCategoria,
      activo: activo ?? this.activo,
    );
  }

  /// Creates a Producto from an APISQL JSON response row.
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['IDProducto'] as num).toInt(),
      idLicencia: json['IDLicencia'] as String?,
      nombre: (json['Nombre'] as String?) ?? '',
      precio: (json['Precio'] as num?)?.toDouble() ?? 0.0,
      precioVariable: _parseBool(json['PrecioVariable']),
      costo: (json['Costo'] as num?)?.toDouble() ?? 0.0,
      codigo: json['Codigo'] as String?,
      codigosExtra: json['CodigosExtra'] as String?,
      iva: (json['IVA'] as num?)?.toInt() ?? 0,
      color: json['Color'] as String?,
      idCategoria: (json['IDCategoria'] as num?)?.toInt(),
      activo: _parseBool(json['Activo']),
    );
  }

  /// Creates a Producto from a SQLite row map.
  factory Producto.fromDb(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int,
      idLicencia: map['id_licencia'] as String?,
      nombre: (map['nombre'] as String?) ?? '',
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      precioVariable: (map['precio_variable'] as int?) == 1,
      costo: (map['costo'] as num?)?.toDouble() ?? 0.0,
      codigo: map['codigo'] as String?,
      codigosExtra: map['codigos_extra'] as String?,
      iva: (map['iva'] as int?) ?? 0,
      color: map['color'] as String?,
      idCategoria: map['id_categoria'] as int?,
      activo: (map['activo'] as int?) == 1,
    );
  }

  /// Converts this Producto to a SQLite row map.
  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'id_licencia': idLicencia,
      'nombre': nombre,
      'precio': precio,
      'precio_variable': precioVariable ? 1 : 0,
      'costo': costo,
      'codigo': codigo,
      'codigos_extra': codigosExtra,
      'iva': iva,
      'color': color,
      'id_categoria': idCategoria,
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
