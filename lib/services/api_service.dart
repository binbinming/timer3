import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/timer_model.dart';
import '../models/timer_group_model.dart';
import 'connectivity_service.dart';

class ApiService {
  static const String baseUrl = 'http://35.200.119.248:3001/api';
  static const int defaultUserId = 1; // 临时使用固定用户ID
  static final ConnectivityService _connectivityService = ConnectivityService();
  static final ApiService instance = ApiService._();
  final String _baseUrl = 'http://localhost:3001';
  final _client = http.Client();

  ApiService._();

  // 保存用户资料
  static Future<bool> saveProfile({
    required String username,
    String? avatarPath,
    required BuildContext context,
  }) async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showConnectivityError(context);
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/save_profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'avatarPath': avatarPath,
        }),
      );

      if (response.statusCode >= 500) {
        _connectivityService.showServerError(context);
        return false;
      }

      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      _connectivityService.showServerError(context);
      return false;
    }
  }

  // 获取用户资料
  static Future<Map<String, dynamic>?> getProfile({
    required BuildContext context,
  }) async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showConnectivityError(context);
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile/$defaultUserId'),
      );

      if (response.statusCode >= 500) {
        _connectivityService.showServerError(context);
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile: $e');
      _connectivityService.showServerError(context);
      return null;
    }
  }

  // 保存用户设置
  static Future<bool> saveSettings({
    required bool vibrationEnabled,
    required bool soundEnabled,
    required bool notificationEnabled,
    required String themeMode,
    required BuildContext context,
  }) async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showConnectivityError(context);
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/save_settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vibrationEnabled': vibrationEnabled,
          'soundEnabled': soundEnabled,
          'notificationEnabled': notificationEnabled,
          'themeMode': themeMode,
        }),
      );

      if (response.statusCode >= 500) {
        _connectivityService.showServerError(context);
        return false;
      }

      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      _connectivityService.showServerError(context);
      return false;
    }
  }

  // 获取用户设置
  static Future<Map<String, dynamic>?> getSettings({
    required BuildContext context,
  }) async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showConnectivityError(context);
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/settings/$defaultUserId'),
      );

      if (response.statusCode >= 500) {
        _connectivityService.showServerError(context);
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting settings: $e');
      _connectivityService.showServerError(context);
      return null;
    }
  }

  // 获取计时器数据
  static Future<Map<String, dynamic>?> getTimerData({
    required BuildContext context,
  }) async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showConnectivityError(context);
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/timers/data/$defaultUserId'),
      );

      if (response.statusCode >= 500) {
        _connectivityService.showServerError(context);
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting timer data: $e');
      _connectivityService.showServerError(context);
      return null;
    }
  }

  // 保存计时器预设
  static Future<bool> saveTimerPresets({
    required List<TimerModel> presets,
    required List<String> categories,
    required BuildContext context,
  }) async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showConnectivityError(context);
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/timers/save_presets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'presets': presets.map((preset) => preset.toJson()).toList(),
          'categories': categories,
        }),
      );

      if (response.statusCode >= 500) {
        _connectivityService.showServerError(context);
        return false;
      }

      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      debugPrint('Error saving timer presets: $e');
      _connectivityService.showServerError(context);
      return false;
    }
  }

  // 保存计时器组
  static Future<bool> saveTimerGroups({
    required List<TimerGroupModel> groups,
    required BuildContext context,
  }) async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showConnectivityError(context);
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/timers/save_groups'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'groups': groups.map((group) => group.toJson()).toList(),
        }),
      );

      if (response.statusCode >= 500) {
        _connectivityService.showServerError(context);
        return false;
      }

      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      debugPrint('Error saving timer groups: $e');
      _connectivityService.showServerError(context);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/user/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
} 