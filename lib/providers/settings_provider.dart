import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = true;
  bool _isNotificationEnabled = true;
  String _username = '时间管理大师';
  String? _avatarPath;
  ThemeMode _themeMode = ThemeMode.system;
  BuildContext? _context;

  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isNotificationEnabled => _isNotificationEnabled;
  String get username => _username;
  String? get avatarPath => _avatarPath;
  ThemeMode get themeMode => _themeMode;

  void setContext(BuildContext context) {
    _context = context;
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // 首先从本地加载主题、震动和通知设置
      final prefs = await SharedPreferences.getInstance();
      _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _isNotificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _themeMode = _parseThemeMode(prefs.getString('theme_mode'));

      if (_context != null) {
        // 只从服务器加载用户资料
        final profile = await ApiService.getProfile(context: _context!);
        if (profile != null) {
          _username = profile['username'] ?? '时间管理大师';
          _avatarPath = profile['avatarPath'];
        } else {
          // 如果服务器获取失败，从本地加载用户资料
          _username = prefs.getString('username') ?? '时间管理大师';
          _avatarPath = prefs.getString('avatar_path');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // 如果出错，确保从本地加载所有设置
      _loadFromLocal();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _isNotificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _themeMode = _parseThemeMode(prefs.getString('theme_mode'));
      _username = prefs.getString('username') ?? '时间管理大师';
      _avatarPath = prefs.getString('avatar_path');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local settings: $e');
    }
  }

  ThemeMode _parseThemeMode(String? mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  Future<void> toggleVibration(bool value) async {
    _isVibrationEnabled = value;
    // 直接保存到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }

  Future<void> toggleSound(bool value) async {
    _isSoundEnabled = value;
    // 直接保存到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    notifyListeners();
  }

  Future<void> toggleNotification(bool value) async {
    _isNotificationEnabled = value;
    // 直接保存到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    _username = newUsername;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateAvatar(String path) async {
    _avatarPath = path;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    // 直接保存到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    try {
      if (_context != null) {
        // 保存用户资料到服务器
        await ApiService.saveProfile(
          username: _username,
          avatarPath: _avatarPath,
          context: _context!,
        );

        // 同时保存到本地
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _username);
        if (_avatarPath != null) {
          await prefs.setString('avatar_path', _avatarPath!);
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      // 如果服务器保存失败，保存到本地
      _saveProfileToLocal();
    }
  }

  Future<void> _saveProfileToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _username);
      if (_avatarPath != null) {
        await prefs.setString('avatar_path', _avatarPath!);
      }
    } catch (e) {
      debugPrint('Error saving profile to local storage: $e');
    }
  }

  Future<void> loadSettings() async {
    await _loadSettings();
  }
} 