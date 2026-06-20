import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Keys
  static const _keyDarkMode = 'dark_mode';
  static const _keyLanguage = 'language';
  static const _keyCustomStoragePath = 'custom_storage_path';
  static const _keyTotalCreated = 'stat_created';
  static const _keyTotalMerged = 'stat_merged';
  static const _keyTotalCompressed = 'stat_compressed';
  static const _keyFavorites = 'favorite_files';
  static const _keyActivities = 'activity_log';

  // Getters
  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? true;
  String get language => _prefs.getString(_keyLanguage) ?? 'en';
  String get customStoragePath => _prefs.getString(_keyCustomStoragePath) ?? '';
  int get totalCreated => _prefs.getInt(_keyTotalCreated) ?? 0;
  int get totalMerged => _prefs.getInt(_keyTotalMerged) ?? 0;
  int get totalCompressed => _prefs.getInt(_keyTotalCompressed) ?? 0;
  List<String> get favorites => _prefs.getStringList(_keyFavorites) ?? [];
  List<Map<String, dynamic>> get activities {
    final raw = _prefs.getStringList(_keyActivities) ?? [];
    return raw.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  // Setters
  Future<void> setDarkMode(bool val) => _prefs.setBool(_keyDarkMode, val);
  Future<void> setLanguage(String val) => _prefs.setString(_keyLanguage, val);
  Future<void> setCustomStoragePath(String val) => _prefs.setString(_keyCustomStoragePath, val);

  // Increments
  Future<void> incrementCreated() => _prefs.setInt(_keyTotalCreated, totalCreated + 1);
  Future<void> incrementMerged() => _prefs.setInt(_keyTotalMerged, totalMerged + 1);
  Future<void> incrementCompressed() => _prefs.setInt(_keyTotalCompressed, totalCompressed + 1);

  // Favorites management
  Future<void> toggleFavorite(String filePath) async {
    final list = favorites;
    if (list.contains(filePath)) {
      list.remove(filePath);
    } else {
      list.add(filePath);
    }
    await _prefs.setStringList(_keyFavorites, list);
  }

  bool isFavorite(String filePath) => favorites.contains(filePath);

  // Activity Log
  Future<void> logActivity(String actionTitle, String type) async {
    final list = _prefs.getStringList(_keyActivities) ?? [];
    final item = {
      'title': actionTitle,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    };
    list.insert(0, json.encode(item)); // Newest first
    if (list.length > 50) {
      list.removeLast(); // Cap log at 50 entries
    }
    await _prefs.setStringList(_keyActivities, list);
  }

  // Backup data as JSON String
  String exportBackup() {
    final Map<String, dynamic> data = {
      'dark_mode': isDarkMode,
      'language': language,
      'custom_storage_path': customStoragePath,
      'stat_created': totalCreated,
      'stat_merged': totalMerged,
      'stat_compressed': totalCompressed,
      'favorite_files': favorites,
      'activity_log': _prefs.getStringList(_keyActivities) ?? [],
    };
    return json.encode(data);
  }

  // Restore backup from JSON String
  Future<bool> importBackup(String backupJson) async {
    try {
      final Map<String, dynamic> data = json.decode(backupJson) as Map<String, dynamic>;
      if (data.containsKey('dark_mode')) await _prefs.setBool(_keyDarkMode, data['dark_mode']);
      if (data.containsKey('language')) await _prefs.setString(_keyLanguage, data['language']);
      if (data.containsKey('custom_storage_path')) await _prefs.setString(_keyCustomStoragePath, data['custom_storage_path']);
      if (data.containsKey('stat_created')) await _prefs.setInt(_keyTotalCreated, data['stat_created']);
      if (data.containsKey('stat_merged')) await _prefs.setInt(_keyTotalMerged, data['stat_merged']);
      if (data.containsKey('stat_compressed')) await _prefs.setInt(_keyTotalCompressed, data['stat_compressed']);
      if (data.containsKey('favorite_files')) {
        await _prefs.setStringList(_keyFavorites, List<String>.from(data['favorite_files']));
      }
      if (data.containsKey('activity_log')) {
        await _prefs.setStringList(_keyActivities, List<String>.from(data['activity_log']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Riverpod providers
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService not initialized yet');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;
  ThemeModeNotifier(this._storage) : super(_storage.isDarkMode ? ThemeMode.dark : ThemeMode.light);

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      _storage.setDarkMode(false);
    } else {
      state = ThemeMode.dark;
      _storage.setDarkMode(true);
    }
  }
}
