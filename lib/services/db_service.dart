import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/categoria.dart';
import '../models/producto.dart';
import '../models/turno.dart';
import '../models/venta.dart';

class DbService {
  static final DbService instance = DbService._();
  DbService._();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ampersand_pos.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Database get _database {
    if (_db == null) {
      throw StateError('DbService not initialized. Call init() first.');
    }
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos(
        id INTEGER PRIMARY KEY,
        id_licencia TEXT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        precio_variable INTEGER DEFAULT 0,
        costo REAL DEFAULT 0,
        codigo TEXT,
        codigos_extra TEXT,
        iva INTEGER DEFAULT 10,
        color TEXT,
        id_categoria INTEGER,
        activo INTEGER DEFAULT 1,
        fecha_mod TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categorias(
        id INTEGER PRIMARY KEY,
        id_licencia TEXT,
        nombre TEXT NOT NULL,
        color TEXT,
        activo INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ventas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_turno INTEGER NOT NULL,
        total REAL NOT NULL,
        metodo_pago TEXT NOT NULL,
        items_json TEXT NOT NULL,
        estado TEXT DEFAULT 'COMPLETADA',
        fecha TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE turno(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        efectivo_inicial REAL NOT NULL,
        estado TEXT DEFAULT 'ABIERTO',
        fecha_apertura TEXT NOT NULL,
        terminal TEXT NOT NULL
      )
    ''');
  }

  // ── Productos ────────────────────────────────────────────────────────────────

  Future<List<Producto>> getProductos() async {
    final maps = await _database.query(
      'productos',
      where: 'activo = 1',
      orderBy: 'nombre ASC',
    );
    return maps.map(Producto.fromDb).toList();
  }

  Future<void> upsertProducto(Producto p) async {
    await _database.insert(
      'productos',
      p.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Categorías ───────────────────────────────────────────────────────────────

  Future<List<Categoria>> getCategorias() async {
    final maps = await _database.query(
      'categorias',
      where: 'activo = 1',
    );
    return maps.map(Categoria.fromDb).toList();
  }

  Future<void> upsertCategoria(Categoria c) async {
    await _database.insert(
      'categorias',
      c.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Ventas ───────────────────────────────────────────────────────────────────

  Future<int> insertVenta(Venta v) async {
    return _database.insert('ventas', v.toDb());
  }

  Future<List<Venta>> getVentasSinSincronizar() async {
    final maps = await _database.query(
      'ventas',
      where: 'sincronizado = 0',
    );
    return maps.map(Venta.fromDb).toList();
  }

  Future<void> marcarVentaSincronizada(int id) async {
    await _database.update(
      'ventas',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Venta>> getVentasTurno(int idTurno) async {
    final maps = await _database.query(
      'ventas',
      where: 'id_turno = ?',
      whereArgs: [idTurno],
    );
    return maps.map(Venta.fromDb).toList();
  }

  // ── Turno ────────────────────────────────────────────────────────────────────

  Future<void> guardarTurno(Turno t) async {
    await _database.insert('turno', t.toDb());
  }

  Future<Turno?> getTurnoActivo() async {
    final maps = await _database.query(
      'turno',
      where: "estado = 'ABIERTO'",
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Turno.fromDb(maps.first);
  }

  Future<void> cerrarTurnoLocal(int id) async {
    await _database.update(
      'turno',
      {'estado': 'CERRADO'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
