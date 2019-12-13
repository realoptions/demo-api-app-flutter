import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class PersistentStorage {
  Future<SharedPreferences> prefs;
  PersistentStorage() {
    prefs = SharedPreferences.getInstance();
  }
  Future<void> insertValue(String key, String value) async {
    SharedPreferences localPrefs = await prefs;
    return localPrefs.setString(key, value);
  }

  Future<void> removeValue(String key) async {
    SharedPreferences localPrefs = await prefs;
    return localPrefs.remove(key);
  }

  Future<String> retrieveValue(String key) async {
    SharedPreferences localPrefs = await prefs;
    return localPrefs.getString(key);
  }
}
