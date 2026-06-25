import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/ride_model.dart';
import '../models/pit_stop_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mototrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rides (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        start_time TEXT,
        end_time TEXT,
        total_distance_km REAL,
        avg_speed_kmh REAL,
        max_speed_kmh REAL,
        max_lean_right REAL,
        max_lean_left REAL,
        stop_count INTEGER,
        pit_pause_count INTEGER,
        ride_duration_seconds INTEGER,
        start_location_name TEXT,
        end_location_name TEXT,
        start_lat REAL,
        start_lng REAL,
        end_lat REAL,
        end_lng REAL,
        route_points_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pit_stops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ride_id INTEGER,
        pit_number INTEGER,
        timestamp TEXT,
        lat REAL,
        lng REAL,
        location_name TEXT,
        duration_seconds INTEGER,
        FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertRide(RideModel ride) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final rideId = await txn.insert('rides', ride.toMap());

      for (var pitStop in ride.pitStops) {
        await txn.insert('pit_stops', pitStop.toMap(rideId));
      }

      return rideId;
    });
  }

  Future<List<RideModel>> getAllRides() async {
    final db = await instance.database;

    final ridesMaps = await db.query('rides', orderBy: 'start_time DESC');
    final List<RideModel> ridesList = [];

    for (var rideMap in ridesMaps) {
      final rideId = rideMap['id'] as int;
      final pitStopsMaps = await db.query(
        'pit_stops',
        where: 'ride_id = ?',
        whereArgs: [rideId],
        orderBy: 'pit_number ASC',
      );

      final List<PitStopModel> stops = pitStopsMaps
          .map((stopMap) => PitStopModel.fromMap(stopMap))
          .toList();

      ridesList.add(RideModel.fromMap(rideMap, stops));
    }

    return ridesList;
  }

  Future<int> updateRideName(int id, String name) async {
    final db = await instance.database;
    return await db.update(
      'rides',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRide(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete(
        'pit_stops',
        where: 'ride_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(
        'rides',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<double> getLifetimeDistance() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(total_distance_km) as total FROM rides');
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
