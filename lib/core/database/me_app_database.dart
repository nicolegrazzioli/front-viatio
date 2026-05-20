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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              email TEXT,
              password TEXT,
              profile_image TEXT
            )
            ''');

        await db.execute('''
            CREATE TABLE trips(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              title TEXT,
              start_date TEXT,
              end_date TEXT,
              cover_type TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');

        await db.execute('''
            CREATE TABLE expenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              trip_id INTEGER,
              title TEXT,
              amount REAL,
              currency TEXT,
              category TEXT,
              date TEXT,
              is_average_cost INTEGER,
              exchange_rate REAL,
              amount_brl REAL,
              description TEXT,
              photo_path TEXT,
              FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
            )
            ''');

        await db.execute('''
            CREATE TABLE currency_transactions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              amount REAL,
              currency TEXT,
              amount_brl REAL,
              source TEXT,
              date TEXT,
              vet_rate REAL,
              description TEXT,
              photo_path TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');

        await db.execute('''
            CREATE TABLE wallets(
              user_id INTEGER,
              currency TEXT,
              balance REAL,
              average_vet REAL,
              PRIMARY KEY (user_id, currency),
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');
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
