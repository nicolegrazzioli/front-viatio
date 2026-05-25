import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (kIsWeb) {
      path = 'viatio_app.db';
    } else {
      path = join(await getDatabasesPath(), 'viatio_app.db');
    }

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE users(
              id TEXT PRIMARY KEY,
              name TEXT,
              email TEXT,
              password TEXT,
              profile_image TEXT,
              is_synced INTEGER DEFAULT 0,
              is_deleted INTEGER DEFAULT 0
            )
            ''');

        await db.execute('''
            CREATE TABLE trips(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              title TEXT,
              start_date TEXT,
              end_date TEXT,
              cover_type TEXT,
              is_synced INTEGER DEFAULT 0,
              is_deleted INTEGER DEFAULT 0,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');

        await db.execute('''
            CREATE TABLE expenses(
              id TEXT PRIMARY KEY,
              trip_id TEXT,
              title TEXT,
              amount REAL,
              currency TEXT,
              category TEXT,
              date TEXT,
              is_average_cost INTEGER,
              exchange_rate REAL,
              amount_brl REAL,

              photo_path TEXT,
              is_synced INTEGER DEFAULT 0,
              is_deleted INTEGER DEFAULT 0,
              FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
            )
            ''');

        await db.execute('''
            CREATE TABLE currency_transactions(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              amount REAL,
              currency TEXT,
              amount_brl REAL,
              source TEXT,
              date TEXT,
              vet_rate REAL,

              photo_path TEXT,
              is_synced INTEGER DEFAULT 0,
              is_deleted INTEGER DEFAULT 0,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');

        await db.execute('''
            CREATE TABLE wallets(
              user_id TEXT,
              currency TEXT,
              balance REAL,
              average_vet REAL,
              is_synced INTEGER DEFAULT 0,
              is_deleted INTEGER DEFAULT 0,
              PRIMARY KEY (user_id, currency),
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE users ADD COLUMN is_synced INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE trips ADD COLUMN is_synced INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE expenses ADD COLUMN is_synced INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE currency_transactions ADD COLUMN is_synced INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE wallets ADD COLUMN is_synced INTEGER DEFAULT 0");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE users ADD COLUMN is_deleted INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE trips ADD COLUMN is_deleted INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE expenses ADD COLUMN is_deleted INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE currency_transactions ADD COLUMN is_deleted INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE wallets ADD COLUMN is_deleted INTEGER DEFAULT 0");
        }
      },
      onOpen: (db) async {
        await _seedDatabase(db);
      },
    );
  }

  Future<void> _seedDatabase(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    if (count == 0) {
      try {
        final String jsonString = await rootBundle.loadString('assets/data/db_mock.json');
        final Map<String, dynamic> data = json.decode(jsonString);

        await db.transaction((txn) async {
          for (var user in data['users']) {
            await txn.insert('users', user);
          }
          for (var trip in data['trips']) {
            await txn.insert('trips', trip);
          }
          for (var expense in data['expenses']) {
            await txn.insert('expenses', expense);
          }
          for (var transaction in data['currency_transactions']) {
            await txn.insert('currency_transactions', transaction);
          }
          for (var wallet in data['wallets']) {
            await txn.insert('wallets', wallet);
          }
        });
        print("Database seeded from JSON");
      } catch (e) {
        print("Error seeding database: $e");
      }
    }
  }
}
