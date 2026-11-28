import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/user_profile.dart';

class AuthDatabase {
  AuthDatabase({sqflite.DatabaseFactory? factory, String? path})
      : _factory = factory,
        _path = path;

  static const _databaseName = 'baghbani_users.db';
  static const _version = 2;
  final sqflite.DatabaseFactory? _factory;
  final String? _path;
  Future<sqflite.Database>? _opening;

  Future<sqflite.Database> get _database => _opening ??= _open();

  Future<sqflite.Database> _open() async {
    final factory = _factory ?? sqflite.databaseFactory;
    final path = _path ??
        (kIsWeb
            ? _databaseName
            : p.join(await sqflite.getDatabasesPath(), _databaseName));
    return factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: _version,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              email TEXT NOT NULL COLLATE NOCASE UNIQUE,
              password_hash TEXT NOT NULL,
              phone TEXT NOT NULL,
              location TEXT NOT NULL,
              whatsapp_number TEXT NOT NULL DEFAULT '',
              address TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await database.execute(
              "ALTER TABLE users ADD COLUMN whatsapp_number TEXT NOT NULL DEFAULT ''",
            );
            await database.execute(
              "ALTER TABLE users ADD COLUMN address TEXT NOT NULL DEFAULT ''",
            );
          }
        },
      ),
    );
  }

  Future<int> insertUser(UserProfile profile, String passwordHash) async {
    final database = await _database;
    final values = {
      'name': profile.name.trim(),
      'email': profile.email.trim().toLowerCase(),
      'password_hash': passwordHash,
      'phone': profile.phone.trim(),
      'location': profile.location.trim(),
      'whatsapp_number': profile.whatsappNumber.trim(),
      'address': profile.address.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    return database.transaction((transaction) async {
      final existing = await transaction.query(
        'users',
        columns: ['id'],
        where: 'email = ?',
        whereArgs: [values['email']],
        limit: 1,
      );
      if (existing.isNotEmpty) return 0;
      return transaction.insert('users', values);
    });
  }

  Future<AuthUserRecord?> findByEmail(String email) async {
    final database = await _database;
    final rows = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : AuthUserRecord.fromMap(rows.first);
  }

  Future<AuthUserRecord?> findById(int id) async {
    final database = await _database;
    final rows = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : AuthUserRecord.fromMap(rows.first);
  }

  Future<void> updateUser(int id, UserProfile profile) async {
    final database = await _database;
    await database.update(
      'users',
      {
        'name': profile.name.trim(),
        'email': profile.email.trim().toLowerCase(),
        'phone': profile.phone.trim(),
        'location': profile.location.trim(),
        'whatsapp_number': profile.whatsappNumber.trim(),
        'address': profile.address.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePassword(int id, String passwordHash) async {
    final database = await _database;
    await database.update(
      'users',
      {'password_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    _opening = null;
    await (await opening).close();
  }
}

class AuthUserRecord {
  const AuthUserRecord({
    required this.id,
    required this.profile,
    required this.passwordHash,
  });

  final int id;
  final UserProfile profile;
  final String passwordHash;

  factory AuthUserRecord.fromMap(Map<String, Object?> row) {
    final id = row['id']! as int;
    return AuthUserRecord(
      id: id,
      profile: UserProfile(
        id: id.toString(),
        name: row['name']! as String,
        email: row['email']! as String,
        phone: row['phone']! as String,
        location: row['location']! as String,
        whatsappNumber: (row['whatsapp_number'] as String?) ?? '',
        address: (row['address'] as String?) ?? '',
      ),
      passwordHash: row['password_hash']! as String,
    );
  }
}
