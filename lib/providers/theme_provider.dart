import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final String _themeKey = 'is_dark_mode';

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // 获取当前是否为深色模式
  bool get isDarkMode => _isDarkMode;

  // 获取当前主题
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // 切换主题模式
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // 设置指定主题
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // 从SharedPreferences加载主题设置
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      // 如果加载失败，使用默认亮色主题
      _isDarkMode = false;
    }
  }

  // 保存主题设置到SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // 保存失败处理
      debugPrint('保存主题设置失败: $e');
    }
  }
}
