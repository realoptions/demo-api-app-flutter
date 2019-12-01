import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:demo_api_app_flutter/models/api_key.dart';

class ApiDB {
  ApiDB();
  final Future<Database> database = openDatabase(
    // Set the path to the database.
    'api_key_store.db',
    // When the database is first created, create a table to store the api keys.
    onCreate: (db, version) {
      // Run the CREATE TABLE statement on the database.
      return db.execute(
        "CREATE TABLE api_key_store(id INTEGER PRIMARY KEY, key VARCHAR(64) NOT NULL)",
      );
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );
  Future<void> insertKey(ApiKey key) {
    // Get a reference to the database.
    //final Database db = await database;

    // Insert the key into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same api key is inserted twice.
    //
    // In this case, replace any previous data.
    return database.then((db) {
      db.insert(
        'api_key_store',
        key.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> removeKey(int id) {
    //final Database db = await database;
    return database.then((db) {
      db.delete('api_key_store', where: "id==?", whereArgs: [id]);
    });
  }

  Future<List<ApiKey>> retrieveKey() {
    return database.then((db) {
      return db
          .query('api_key_store')
          .then((final List<Map<String, dynamic>> maps) {
        return List.generate(maps.length, (i) {
          return ApiKey(
            id: maps[i]['id'],
            key: maps[i]['key'],
          );
        });
      });
    });
  }
}
