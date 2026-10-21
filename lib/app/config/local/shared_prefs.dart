import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  SharedPrefs._();
  static final SharedPrefs instance = SharedPrefs._();

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<bool> setString(String key, String value) async =>
      (await _prefs()).setString(key, value);
  Future<String?> getString(String key) async =>
      (await _prefs()).getString(key);

  Future<bool> setInt(String key, int value) async =>
      (await _prefs()).setInt(key, value);
  Future<int?> getInt(String key) async => (await _prefs()).getInt(key);

  Future<bool> setBool(String key, bool value) async =>
      (await _prefs()).setBool(key, value);
  Future<bool?> getBool(String key) async => (await _prefs()).getBool(key);

  Future<bool> setDouble(String key, double value) async =>
      (await _prefs()).setDouble(key, value);
  Future<double?> getDouble(String key) async =>
      (await _prefs()).getDouble(key);

  Future<bool> setStringList(String key, List<String> value) async =>
      (await _prefs()).setStringList(key, value);
  Future<List<String>?> getStringList(String key) async =>
      (await _prefs()).getStringList(key);

  Future<bool> remove(String key) async => (await _prefs()).remove(key);
  Future<bool> clear() async => (await _prefs()).clear();

  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    final jsonStr = jsonEncode(value);
    return (await _prefs()).setString(key, jsonStr);
  }

  Future<Map<String, dynamic>?> getObject(String key) async {
    final str = (await _prefs()).getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setTypedObject<T>(String key, T value, Map<String, dynamic> Function(T) toJson) async {
    return setObject(key, toJson(value));
  }

  Future<T?> getTypedObject<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final map = await getObject(key);
    if (map == null) return null;
    return fromJson(map);
  }
}
