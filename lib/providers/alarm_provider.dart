import 'dart:convert';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

class AlarmProvider extends ChangeNotifier {
  static const String _alarmsKey = 'alarms';

  List<AlarmModel> _alarms = [];

  List<AlarmModel> get alarms => _alarms;

  List<AlarmModel> get enabledAlarms =>
      _alarms.where((alarm) => alarm.isEnabled).toList();

  List<AlarmModel> get pinnedAlarms =>
      _alarms.where((alarm) => alarm.isPinned).toList();

  List<AlarmModel> get unpinnedAlarms =>
      _alarms.where((alarm) => !alarm.isPinned).toList();

  AlarmProvider() {
    _loadAlarms();
  }

  // 加载已保存的闹钟
  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getStringList(_alarmsKey);

      if (alarmsJson == null || alarmsJson.isEmpty) {
        _addDefaultAlarms();
        return;
      }

      _alarms =
          alarmsJson
              .map((json) => AlarmModel.fromJson(jsonDecode(json)))
              .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('加载闹钟失败: $e');
      _addDefaultAlarms();
    }
  }

  // 添加默认闹钟
  void _addDefaultAlarms() {
    final now = DateTime.now();

    _alarms = [
      AlarmModel(
        id: 1,
        label: '起床闹钟',
        timeOfDay: TimeOfDay(hour: 7, minute: 0),
        weekdays: [1, 2, 3, 4, 5], // 工作日
        isPinned: true,
      ),
      AlarmModel(
        id: 2,
        label: '周末闹钟',
        timeOfDay: TimeOfDay(hour: 8, minute: 30),
        weekdays: [0, 6], // 周末
      ),
    ];

    _saveAlarms();
  }

  // 保存闹钟设置
  Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson =
          _alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();

      await prefs.setStringList(_alarmsKey, alarmsJson);
    } catch (e) {
      debugPrint('保存闹钟失败: $e');
    }
  }

  // 添加闹钟
  void addAlarm(AlarmModel alarm) {
    final newId =
        _alarms.isEmpty
            ? 1
            : _alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    final newAlarm = alarm.copyWith(id: newId);

    _alarms.add(newAlarm);
    _saveAlarms();
    notifyListeners();
  }

  // 更新闹钟
  void updateAlarm(AlarmModel alarm) {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index >= 0) {
      _alarms[index] = alarm;
      _saveAlarms();
      notifyListeners();
    }
  }

  // 删除闹钟
  void deleteAlarm(int id) {
    _alarms.removeWhere((a) => a.id == id);
    _saveAlarms();
    notifyListeners();
  }

  // 启用/禁用闹钟
  void toggleAlarmEnabled(int id) {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final alarm = _alarms[index];
      _alarms[index] = alarm.copyWith(isEnabled: !alarm.isEnabled);
      _saveAlarms();
      notifyListeners();
    }
  }

  // 切换置顶状态
  void toggleAlarmPinned(int id) {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final alarm = _alarms[index];
      _alarms[index] = alarm.copyWith(isPinned: !alarm.isPinned);
      _saveAlarms();
      notifyListeners();
    }
  }
}
