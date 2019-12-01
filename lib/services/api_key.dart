import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:demo_api_app_flutter/models/api_key.dart' as key_model;

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

Future<void> insertKey(key_model.ApiKey key) async {
  // Get a reference to the database.
  final Database db = await database;

  // Insert the key into the correct table. You might also specify the
  // `conflictAlgorithm` to use in case the same api key is inserted twice.
  //
  // In this case, replace any previous data.
  await db.insert(
    'api_key_store',
    key.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> removeKey(int id) async {
  final Database db = await database;

  await db.delete('api_key_store', where: "id==?", whereArgs: [id]);
}

Future<List<key_model.ApiKey>> retrieveKey() async {
  // Get a reference to the database.
  final Database db = await database;

  // Query the table for all The Dogs.
  final List<Map<String, dynamic>> maps = await db.query('api_key_store');
  // Convert the List<Map<String, dynamic> into a List<Dog>.
  return List.generate(maps.length, (i) {
    return key_model.ApiKey(
      id: maps[i]['id'],
      key: maps[i]['key'],
    );
  });
}
