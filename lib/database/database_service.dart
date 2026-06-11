import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  factory DatabaseService() => instance;

  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDir.path, 'pos_abarrotes.db');

    return await openDatabase(
      dbPath,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
if (oldVersion < 3) {
  await db.execute('''
    ALTER TABLE configuracion
    ADD COLUMN modo_ticket TEXT NOT NULL DEFAULT 'PREGUNTAR'
  ''');
}
}

  Future<void> _onCreate(Database db, int version) async {
  await _crearRoles(db);
  await _crearPermisos(db);
  await _crearRolPermisos(db);

  await _crearUsuarios(db);
  await _crearCategorias(db);
  await _crearMarcas(db);
  await _crearClientes(db);
  await _crearProveedores(db);

  await _crearProductos(db);
  await _crearProductosConversion(db);
  await _crearPreciosProducto(db);
  await _crearHistorialPrecios(db);

  await _crearCompras(db);
  await _crearDetalleCompra(db);
  await _crearLotesInventario(db);

  await _crearVentas(db);
  await _crearDetalleVenta(db);
  await _crearPagosVenta(db);
  await _crearConsumoLotes(db);

  await _crearCreditos(db);
  await _crearMovimientosCredito(db);

  await _crearDevolucionesVenta(db);
  await _crearDetalleDevolucion(db);
  await _crearDevolucionesProveedor(db);
  await _crearDetalleDevolucionProveedor(db);

  await _crearMovimientosInventario(db);
  await _crearMotivosAjuste(db);

  await _crearCajas(db);
  await _crearMovimientosCaja(db);
  await _crearGastos(db);
  await _crearMermas(db);

  await _crearAuditoria(db);
  await _crearAlertas(db);
  await _crearPromociones(db);
  await _crearConfiguracion(db);
  await _crearSesionesUsuario(db);

  await _insertarDatosIniciales(db);
}
  Future<void> _crearRoles(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE roles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<void> _crearPermisos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE permisos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        descripcion TEXT NOT NULL
      )
    ''');
  }

  Future<void> _crearRolPermisos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE rol_permisos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rol_id INTEGER NOT NULL,
        permiso_id INTEGER NOT NULL,
        UNIQUE(rol_id, permiso_id),
        FOREIGN KEY (rol_id) REFERENCES roles(id),
        FOREIGN KEY (permiso_id) REFERENCES permisos(id)
      )
    ''');
  }

  Future<void> _crearUsuarios(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        usuario TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        rol_id INTEGER NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (rol_id) REFERENCES roles(id)
      )
    ''');
  }

  Future<void> _crearCategorias(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE categorias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        descripcion TEXT
      )
    ''');
  }

  Future<void> _crearMarcas(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE marcas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<void> _crearClientes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        direccion TEXT,
        permite_fiado INTEGER NOT NULL DEFAULT 0,
        limite_credito REAL NOT NULL DEFAULT 0,
        bloqueado_credito INTEGER NOT NULL DEFAULT 0,
        activo INTEGER NOT NULL DEFAULT 1,
        fecha_registro TEXT NOT NULL
      )
    ''');
  }

  Future<void> _crearProveedores(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE proveedores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        direccion TEXT,
        contacto TEXT,
        activo INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _crearProductos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE productos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_barras TEXT UNIQUE,
        codigo_interno TEXT UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        categoria_id INTEGER,
        marca_id INTEGER,
        unidad_medida TEXT NOT NULL,
        stock_actual REAL NOT NULL DEFAULT 0,
        stock_minimo REAL NOT NULL DEFAULT 0,
        estado TEXT NOT NULL DEFAULT 'ACTIVO',
        fecha_creacion TEXT NOT NULL,
        fecha_actualizacion TEXT,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id),
        FOREIGN KEY (marca_id) REFERENCES marcas(id)
      )
    ''');
  }

  Future<void> _crearProductosConversion(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE productos_conversion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_padre_id INTEGER NOT NULL,
        producto_hijo_id INTEGER NOT NULL,
        factor_conversion REAL NOT NULL,
        FOREIGN KEY (producto_padre_id) REFERENCES productos(id),
        FOREIGN KEY (producto_hijo_id) REFERENCES productos(id)
      )
    ''');
  }

  Future<void> _crearPreciosProducto(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE precios_producto(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tipo_precio TEXT NOT NULL,
        cantidad_minima REAL NOT NULL DEFAULT 1,
        precio REAL NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
  }

  Future<void> _crearHistorialPrecios(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE historial_precios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        precio_anterior REAL,
        precio_nuevo REAL NOT NULL,
        usuario_id INTEGER,
        fecha TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearCompras(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE compras(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proveedor_id INTEGER,
        usuario_id INTEGER,
        fecha TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0,
        descuento REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        estado TEXT NOT NULL DEFAULT 'COMPLETADA',
        FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearDetalleCompra(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE detalle_compra(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compra_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        costo_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (compra_id) REFERENCES compras(id),
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
  }

  Future<void> _crearLotesInventario(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE lotes_inventario(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        compra_id INTEGER,
        costo_unitario REAL NOT NULL,
        cantidad_inicial REAL NOT NULL,
        cantidad_disponible REAL NOT NULL,
        fecha_entrada TEXT NOT NULL,
        fecha_caducidad TEXT,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (compra_id) REFERENCES compras(id)
      )
    ''');
  }

  Future<void> _crearVentas(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE ventas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL DEFAULT 1,
        usuario_id INTEGER,
        tipo_venta TEXT NOT NULL,
        subtotal REAL NOT NULL,
        descuento REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        estado TEXT NOT NULL DEFAULT 'COMPLETADA',
        fecha TEXT NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearDetalleVenta(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE detalle_venta(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        precio_unitario REAL NOT NULL,
        descuento REAL NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES ventas(id),
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
  }

  Future<void> _crearPagosVenta(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE pagos_venta(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        tipo_pago TEXT NOT NULL,
        monto REAL NOT NULL,
        referencia TEXT,
        FOREIGN KEY (venta_id) REFERENCES ventas(id)
      )
    ''');
  }

  Future<void> _crearConsumoLotes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE consumo_lotes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        detalle_venta_id INTEGER NOT NULL,
        lote_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        FOREIGN KEY (detalle_venta_id) REFERENCES detalle_venta(id),
        FOREIGN KEY (lote_id) REFERENCES lotes_inventario(id)
      )
    ''');
  }

  Future<void> _crearCreditos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE creditos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        venta_id INTEGER NOT NULL,
        monto_original REAL NOT NULL,
        saldo_actual REAL NOT NULL,
        estado TEXT NOT NULL DEFAULT 'ACTIVO',
        fecha TEXT NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id),
        FOREIGN KEY (venta_id) REFERENCES ventas(id)
      )
    ''');
  }

  Future<void> _crearMovimientosCredito(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE movimientos_credito(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        credito_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        monto REAL NOT NULL,
        usuario_id INTEGER,
        fecha TEXT NOT NULL,
        FOREIGN KEY (credito_id) REFERENCES creditos(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearDevolucionesVenta(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE devoluciones_venta(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        motivo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        reembolso REAL NOT NULL DEFAULT 0,
        autorizada_por INTEGER,
        FOREIGN KEY (venta_id) REFERENCES ventas(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
        FOREIGN KEY (autorizada_por) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearDetalleDevolucion(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE detalle_devolucion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        devolucion_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        precio REAL NOT NULL,
        FOREIGN KEY (devolucion_id) REFERENCES devoluciones_venta(id),
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
  }

  Future<void> _crearDevolucionesProveedor(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE devoluciones_proveedor(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proveedor_id INTEGER,
        usuario_id INTEGER,
        fecha TEXT NOT NULL,
        motivo TEXT NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearDetalleDevolucionProveedor(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE detalle_devolucion_proveedor(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        devolucion_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        costo REAL NOT NULL,
        FOREIGN KEY (devolucion_id) REFERENCES devoluciones_proveedor(id),
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
  }

  Future<void> _crearMovimientosInventario(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE movimientos_inventario(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        cantidad REAL NOT NULL,
        usuario_id INTEGER,
        referencia TEXT,
        fecha TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearMotivosAjuste(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE motivos_ajuste(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<void> _crearCajas(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE cajas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_apertura INTEGER,
        usuario_cierre INTEGER,
        monto_inicial REAL NOT NULL DEFAULT 0,
        monto_esperado REAL NOT NULL DEFAULT 0,
        monto_contado REAL,
        faltante REAL NOT NULL DEFAULT 0,
        sobrante REAL NOT NULL DEFAULT 0,
        fecha_apertura TEXT NOT NULL,
        fecha_cierre TEXT,
        estado TEXT NOT NULL DEFAULT 'ABIERTA',
        FOREIGN KEY (usuario_apertura) REFERENCES usuarios(id),
        FOREIGN KEY (usuario_cierre) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearMovimientosCaja(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE movimientos_caja(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caja_id INTEGER,
        tipo TEXT NOT NULL,
        monto REAL NOT NULL,
        referencia TEXT,
        fecha TEXT NOT NULL,
        FOREIGN KEY (caja_id) REFERENCES cajas(id)
      )
    ''');
  }

  Future<void> _crearGastos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE gastos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria TEXT NOT NULL,
        descripcion TEXT,
        monto REAL NOT NULL,
        usuario_id INTEGER,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearMermas(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE mermas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        motivo TEXT NOT NULL,
        usuario_id INTEGER,
        fecha TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearAuditoria(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE auditoria(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER,
        accion TEXT NOT NULL,
        tabla_afectada TEXT NOT NULL,
        registro_id INTEGER,
        detalle TEXT,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _crearAlertas(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE alertas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        mensaje TEXT NOT NULL,
        leida INTEGER NOT NULL DEFAULT 0,
        fecha TEXT NOT NULL
      )
    ''');
  }

  Future<void> _crearPromociones(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE promociones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        fecha_inicio TEXT,
        fecha_fin TEXT,
        activo INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _crearConfiguracion(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE configuracion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_negocio TEXT,
        telefono TEXT,
        direccion TEXT,
        usa_fifo INTEGER NOT NULL DEFAULT 1,
        usa_fiados INTEGER NOT NULL DEFAULT 1,
        stock_minimo_global REAL NOT NULL DEFAULT 5,
        impresora_tickets TEXT,
        margen_ganancia_default REAL NOT NULL DEFAULT 25,
        firebase_activo INTEGER NOT NULL DEFAULT 0
        
      )
    ''');
  }

  Future<void> _crearSesionesUsuario(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE sesiones_usuario(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT,
        equipo TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<void> _insertarDatosIniciales(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('roles', {'id': 1, 'nombre': 'Administrador'});
    await db.insert('roles', {'id': 2, 'nombre': 'Encargado'});
    await db.insert('roles', {'id': 3, 'nombre': 'Cajero'});

    final permisos = [
      ['CREAR_PRODUCTO', 'Crear productos'],
      ['EDITAR_PRODUCTO', 'Editar productos'],
      ['ELIMINAR_PRODUCTO', 'Eliminar o desactivar productos'],
      ['REALIZAR_VENTA', 'Realizar ventas'],
      ['CANCELAR_VENTA', 'Cancelar ventas'],
      ['REGISTRAR_COMPRA', 'Registrar compras'],
      ['AJUSTAR_INVENTARIO', 'Ajustar inventario'],
      ['REGISTRAR_MERMA', 'Registrar mermas'],
      ['CREAR_CLIENTE', 'Crear clientes'],
      ['CREAR_FIADO', 'Crear ventas fiadas'],
      ['COBRAR_FIADO', 'Cobrar abonos de fiados'],
      ['VER_COSTOS', 'Ver costos'],
      ['VER_GANANCIAS', 'Ver ganancias'],
      ['VER_AUDITORIA', 'Ver auditoría'],
      ['ADMIN_USUARIOS', 'Administrar usuarios'],
      ['ADMIN_CONFIGURACION', 'Administrar configuración'],
      ['REGISTRAR_GASTO', 'Registrar gastos'],
      ['AUTORIZAR_DEVOLUCION', 'Autorizar devoluciones'],
    ];

    for (final permiso in permisos) {
      await db.insert('permisos', {
        'codigo': permiso[0],
        'descripcion': permiso[1],
      });
    }

    // Admin recibe todos los permisos.
    final permisosDb = await db.query('permisos');
    for (final permiso in permisosDb) {
      await db.insert('rol_permisos', {
        'rol_id': 1,
        'permiso_id': permiso['id'],
      });
    }

    // Encargado recibe permisos operativos.
    final permisosEncargado = [
      'CREAR_PRODUCTO',
      'EDITAR_PRODUCTO',
      'REALIZAR_VENTA',
      'REGISTRAR_COMPRA',
      'AJUSTAR_INVENTARIO',
      'REGISTRAR_MERMA',
      'CREAR_CLIENTE',
      'CREAR_FIADO',
      'COBRAR_FIADO',
      'REGISTRAR_GASTO',
      'AUTORIZAR_DEVOLUCION',
    ];

    for (final codigo in permisosEncargado) {
      final result = await db.query(
        'permisos',
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (result.isNotEmpty) {
        await db.insert('rol_permisos', {
          'rol_id': 2,
          'permiso_id': result.first['id'],
        });
      }
    }

    // Cajero recibe permisos básicos.
    final permisosCajero = [
      'REALIZAR_VENTA',
      'COBRAR_FIADO',
      'CREAR_CLIENTE',
    ];

    for (final codigo in permisosCajero) {
      final result = await db.query(
        'permisos',
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (result.isNotEmpty) {
        await db.insert('rol_permisos', {
          'rol_id': 3,
          'permiso_id': result.first['id'],
        });
      }
    }

    await db.insert('usuarios', {
      'id': 1,
      'nombre': 'Administrador',
      'usuario': 'admin',
      'password_hash': 'admin123',
      'rol_id': 1,
      'activo': 1,
      'fecha_creacion': now,
    });

    await db.insert('clientes', {
      'id': 1,
      'nombre': 'PUBLICO GENERAL',
      'telefono': null,
      'direccion': null,
      'permite_fiado': 0,
      'limite_credito': 0,
      'bloqueado_credito': 0,
      'activo': 1,
      'fecha_registro': now,
    });

    await db.insert('configuracion', {
      'id': 1,
      'nombre_negocio': 'Mi Tienda',
      'telefono': '',
      'direccion': '',
      'usa_fifo': 1,
      'usa_fiados': 1,
      'stock_minimo_global': 5,
      'impresora_tickets': '',
      'firebase_activo': 0,
    });

    final categorias = [
      'Abarrotes',
      'Ferretería',
      'Bebidas',
      'Dulces',
      'Limpieza',
      'Papelería',
    ];

    for (final categoria in categorias) {
      await db.insert('categorias', {'nombre': categoria});
    }

    final motivos = [
      'CONTEO_FISICO',
      'PRODUCTO_ROTO',
      'PRODUCTO_CADUCADO',
      'PRODUCTO_PERDIDO',
      'ERROR_CAPTURA',
    ];

    for (final motivo in motivos) {
      await db.insert('motivos_ajuste', {'nombre': motivo});
    }
  }

  Future<List<Map<String, Object?>>> obtenerTablas() async {
    final db = await database;
    return db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
  }

  Future<void> cerrarBD() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}