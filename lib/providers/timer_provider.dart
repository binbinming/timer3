import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_model.dart';
import '../models/timer_group_model.dart';
import '../services/notification_service.dart';
import '../screens/home_screen.dart';

enum TimerStatus { idle, running, paused, completed }

class TimerProvider extends ChangeNotifier {
  static const String _presetKey = 'timer_presets';
  static const String _presetCategoryKey = 'timer_preset_categories';
  static const String _groupsKey = 'timer_groups';

  // 预设列表
  List<TimerModel> _presets = [];
  // 计时器组列表
  List<TimerGroupModel> _groups = [];
  List<String> _categories = ['未分类', '学习', '运动健身', '冥想放松', '工作', '生活'];

  // 计时器状态
  TimerStatus _status = TimerStatus.idle;
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  TimerModel? _currentTimer;
  bool _isCountdown = true; // 添加倒计时标志

  // 计时器组状态
  TimerGroupModel? _currentGroup;
  int _currentTimerIndex = 0; // 当前执行到组中的哪个计时器
  List<TimerModel>? _groupTimers; // 当前组中的计时器列表

  // 自动开始间隔定时
  final bool _autoStartInterval = true;

  // 获取器
  List<TimerModel> get presets => _presets;
  List<TimerGroupModel> get groups => _groups;
  List<String> get categories => _categories;
  TimerStatus get status => _status;
  int get secondsRemaining => _secondsRemaining;
  int get totalSeconds => _totalSeconds;
  double get progress =>
      _totalSeconds > 0 ? 1 - (_secondsRemaining / _totalSeconds) : 0;
  TimerModel? get currentTimer => _currentTimer;
  TimerGroupModel? get currentGroup => _currentGroup;
  int get currentTimerIndex => _currentTimerIndex;
  bool get isCountdown => _isCountdown; // 添加getter

  // 是否正在执行计时器组
  bool get isRunningGroup => _currentGroup != null;

  // 计时器组的进度信息
  String get groupProgressText =>
      isRunningGroup
          ? '${_currentTimerIndex + 1}/${_groupTimers?.length ?? 0}'
          : '';

  // 获取按类别分组的预设（包括普通计时器和计时器组）
  Map<String, List<dynamic>> get presetsByCategory {
    // 调试信息
    print('获取 presetsByCategory:');
    print('  所有预设数量: ${_presets.length}');
    print('  所有计时器组数量: ${_groups.length}');

    final result = <String, List<dynamic>>{
      // 始终显示置顶分类，即使没有置顶的预设
      '置顶': [],
    };

    // 处理普通计时器
    for (final preset in _presets) {
      // 所有的预设都放入它们的原始分类中
      if (!result.containsKey(preset.category)) {
        result[preset.category] = [];
      }
      result[preset.category]!.add(preset);

      // 如果是置顶预设，则额外再放入置顶分类
      if (preset.isPinned) {
        result['置顶']!.add(preset);
      }
    }

    // 处理计时器组
    for (final group in _groups) {
      // 所有的组都放入它们的原始分类中
      if (!result.containsKey(group.category)) {
        result[group.category] = [];
      }
      result[group.category]!.add(group);

      // 如果是置顶组，则额外再放入置顶分类
      if (group.isPinned) {
        result['置顶']!.add(group);
      }
    }

    print('  处理后的置顶数量: ${result['置顶']?.length ?? 0}');
    for (var category in result.keys) {
      print('  - $category: ${result[category]?.length ?? 0}个项目');
    }

    return result;
  }

  // 获取所有预设分类（包括置顶和未分类）
  List<String> get allCategories {
    final categories = Set<String>.from(_categories);

    // 确保置顶分类总是存在
    categories.add('置顶');

    // 检查是否有未分类的预设或组
    final hasUncategorized =
        _presets.any((p) => !_categories.contains(p.category) && !p.isPinned) ||
        _groups.any((g) => !_categories.contains(g.category) && !g.isPinned);
    if (hasUncategorized) {
      categories.add('未分类');
    }

    return categories.toList();
  }

  // 获取可排序的分类列表（排除"置顶"和"未分类"）
  List<String> get sortableCategories {
    return _categories.where((cat) => cat != '置顶' && cat != '未分类').toList();
  }

  TimerProvider() {
    _loadPresets();
    _loadGroups();
  }

  // 加载保存的预设
  Future<void> _loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getStringList(_presetKey);
      final categoriesJson = prefs.getStringList(_presetCategoryKey);

      if (categoriesJson != null && categoriesJson.isNotEmpty) {
        _categories = categoriesJson;
      }

      if (presetsJson == null || presetsJson.isEmpty) {
        _addDefaultPresets();
        return;
      }

      final loadedPresets = <TimerModel>[];

      for (final json in presetsJson) {
        try {
          final Map<String, dynamic> data = jsonDecode(json);
          if (data.containsKey('type') && data['type'] == 'interval') {
            loadedPresets.add(IntervalTimerModel.fromJson(data));
          } else {
            loadedPresets.add(TimerModel.fromJson(data));
          }
        } catch (e) {
          debugPrint('解析预设失败: $e');
        }
      }

      _presets = loadedPresets;
      notifyListeners();
    } catch (e) {
      debugPrint('加载预设失败: $e');
      _addDefaultPresets();
    }
  }

  // 加载保存的计时器组
  Future<void> _loadGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = prefs.getStringList(_groupsKey);

      if (groupsJson == null || groupsJson.isEmpty) {
        _addDefaultGroups();
        return;
      }

      final loadedGroups = <TimerGroupModel>[];

      for (final json in groupsJson) {
        try {
          final Map<String, dynamic> data = jsonDecode(json);
          loadedGroups.add(TimerGroupModel.fromJson(data));
        } catch (e) {
          debugPrint('解析计时器组失败: $e');
        }
      }

      _groups = loadedGroups;
      notifyListeners();
    } catch (e) {
      debugPrint('加载计时器组失败: $e');
      _addDefaultGroups();
    }
  }

  // 添加默认预设
  void _addDefaultPresets() {
    _presets = [
      TimerModel(
        id: 1,
        name: '番茄工作法',
        minutes: 25,
        category: '学习',
        isPinned: false,
      ),
      TimerModel(
        id: 2,
        name: '短休息',
        minutes: 5,
        category: '学习',
        isPinned: false,
      ),
      TimerModel(
        id: 3,
        name: '长休息',
        minutes: 15,
        category: '学习',
        isPinned: false,
      ),
      IntervalTimerModel(
        id: 4,
        name: 'HIIT训练',
        workSeconds: 30,
        restSeconds: 10,
        sets: 8,
        category: '运动健身',
        isPinned: false,
      ),
      IntervalTimerModel(
        id: 5,
        name: '力量训练',
        workSeconds: 45,
        restSeconds: 60,
        sets: 5,
        category: '运动健身',
        isPinned: false,
      ),
      TimerModel(
        id: 6,
        name: '冥想',
        minutes: 10,
        category: '冥想放松',
        isPinned: false,
      ),
      TimerModel(
        id: 7,
        name: '阅读时间',
        minutes: 30,
        category: '生活',
        isPinned: false,
      ),
    ];
    _savePresets();
  }

  // 添加默认计时器组
  void _addDefaultGroups() {
    _groups = [
      TimerGroupModel(
        id: 1,
        name: 'HIIT训练',
        category: '运动健身',
        timers: [
          TimerModel(
            id: 1001,
            name: '拉伸',
            minutes: 0,
            seconds: 20,
            category: '运动健身',
          ),
          TimerModel(
            id: 1002,
            name: '高强度运动',
            minutes: 0,
            seconds: 40,
            category: '运动健身',
          ),
          TimerModel(
            id: 1003,
            name: '休息',
            minutes: 0,
            seconds: 20,
            category: '运动健身',
          ),
          TimerModel(
            id: 1004,
            name: '高强度运动',
            minutes: 0,
            seconds: 40,
            category: '运动健身',
          ),
          TimerModel(
            id: 1005,
            name: '休息',
            minutes: 0,
            seconds: 20,
            category: '运动健身',
          ),
          TimerModel(
            id: 1006,
            name: '高强度运动',
            minutes: 0,
            seconds: 40,
            category: '运动健身',
          ),
          TimerModel(
            id: 1007,
            name: '休息',
            minutes: 0,
            seconds: 20,
            category: '运动健身',
          ),
          TimerModel(
            id: 1008,
            name: '高强度运动',
            minutes: 0,
            seconds: 40,
            category: '运动健身',
          ),
          TimerModel(
            id: 1009,
            name: '休息',
            minutes: 0,
            seconds: 20,
            category: '运动健身',
          ),
          TimerModel(
            id: 1010,
            name: '高强度运动',
            minutes: 0,
            seconds: 40,
            category: '运动健身',
          ),
          TimerModel(
            id: 1011,
            name: '休息',
            minutes: 0,
            seconds: 20,
            category: '运动健身',
          ),
          TimerModel(
            id: 1012,
            name: '高强度运动',
            minutes: 0,
            seconds: 40,
            category: '运动健身',
          ),
          TimerModel(
            id: 1013,
            name: '休息',
            minutes: 0,
            seconds: 20,
            category: '运动健身',
          ),
          TimerModel(
            id: 1014,
            name: '拉伸放松',
            minutes: 3,
            seconds: 0,
            category: '运动健身',
          ),
        ],
      ),
      TimerGroupModel(
        id: 2,
        name: '完整番茄工作法',
        category: '学习',
        timers: [
          TimerModel(id: 2001, name: '工作', minutes: 25, category: '学习'),
          TimerModel(id: 2002, name: '短休息', minutes: 5, category: '学习'),
          TimerModel(id: 2003, name: '工作', minutes: 25, category: '学习'),
          TimerModel(id: 2004, name: '短休息', minutes: 5, category: '学习'),
          TimerModel(id: 2005, name: '工作', minutes: 25, category: '学习'),
          TimerModel(id: 2006, name: '短休息', minutes: 5, category: '学习'),
          TimerModel(id: 2007, name: '工作', minutes: 25, category: '学习'),
          TimerModel(id: 2008, name: '长休息', minutes: 15, category: '学习'),
        ],
      ),
    ];
    _saveGroups();
  }

  // 保存预设
  Future<void> _savePresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson =
          _presets.map((preset) => jsonEncode(preset.toJson())).toList();
      await prefs.setStringList(_presetKey, presetsJson);

      // 同时保存分类列表
      await prefs.setStringList(_presetCategoryKey, _categories);
    } catch (e) {
      debugPrint('保存预设失败: $e');
    }
  }

  // 保存计时器组
  Future<void> _saveGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson =
          _groups.map((group) => jsonEncode(group.toJson())).toList();
      await prefs.setStringList(_groupsKey, groupsJson);
    } catch (e) {
      debugPrint('保存计时器组失败: $e');
    }
  }

  // 添加预设
  void addPreset(TimerModel preset) {
    final newId =
        _presets.isEmpty
            ? 1
            : _presets.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    final newPreset = preset.copyWith(id: newId);
    _presets.add(newPreset);
    _savePresets();
    notifyListeners();
  }

  // 添加计时器组
  void addGroup(TimerGroupModel group) {
    final newId =
        _groups.isEmpty
            ? 1
            : _groups.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
    final newGroup = group.copyWith(id: newId);
    _groups.add(newGroup);
    _saveGroups();
    notifyListeners();
  }

  // 更新预设
  void updatePreset(TimerModel preset) {
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index >= 0) {
      _presets[index] = preset;
      _savePresets();
      notifyListeners();
    }
  }

  // 更新计时器组
  void updateGroup(TimerGroupModel group) {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      _groups[index] = group;
      _saveGroups();
      notifyListeners();
    }
  }

  // 删除预设
  void deletePreset(int id) {
    _presets.removeWhere((p) => p.id == id);
    _savePresets();
    notifyListeners();
  }

  // 删除计时器组
  void deleteGroup(int id) {
    _groups.removeWhere((g) => g.id == id);
    _saveGroups();
    notifyListeners();
  }

  // 为预设添加置顶/取消置顶功能
  void togglePinPreset(int id) {
    final index = _presets.indexWhere((preset) => preset.id == id);
    if (index >= 0) {
      final preset = _presets[index];
      final newPinStatus = !preset.isPinned;

      print(
        'togglePinPreset: ID=$id, 名称=${preset.name}, 当前状态=${preset.isPinned}, 新状态=$newPinStatus',
      );

      // 只切换置顶状态，不修改分类
      _presets[index] = preset.copyWith(isPinned: newPinStatus);

      print(
        '置顶切换后: ${_presets[index].name}, isPinned=${_presets[index].isPinned}',
      );

      _savePresets();
      notifyListeners();

      // 验证切换后的状态
      final afterToggle = _presets.where((p) => p.isPinned).length;
      print('切换后置顶的预设总数: $afterToggle');
    } else {
      print('togglePinPreset: 未找到ID为 $id 的预设');
    }
  }

  // 为计时器组添加置顶/取消置顶功能
  void togglePinGroup(int id) {
    final index = _groups.indexWhere((group) => group.id == id);
    if (index >= 0) {
      final group = _groups[index];
      final newPinStatus = !group.isPinned;

      // 只切换置顶状态，不修改分类
      _groups[index] = group.copyWith(isPinned: newPinStatus);

      _saveGroups();
      notifyListeners();
    }
  }

  // 添加新分类
  void addCategory(String category) {
    try {
      final trimmedCategory = category.trim();
      print('添加分类 (开始): "$trimmedCategory"');

      // 检查分类名称是否为空或已存在
      if (trimmedCategory.isEmpty) {
        print('分类名称为空，跳过添加');
        return;
      }

      if (_categories.contains(trimmedCategory)) {
        print('分类 "$trimmedCategory" 已存在，跳过添加');
        return;
      }

      // 添加新分类
      print('正在添加新分类: "$trimmedCategory"');

      // 创建一个新的列表而不是修改现有列表
      final newCategories = List<String>.from(_categories);
      newCategories.add(trimmedCategory);

      // 对分类进行排序（只排序常规分类，确保"未分类"保持在列表头部）
      final specialCategories = newCategories.where((c) => c == '未分类').toList();
      final sortableCategories =
          newCategories.where((c) => c != '未分类').toList();
      sortableCategories.sort(); // 按字母顺序排序

      // 重新组合并分配分类列表
      _categories = [...specialCategories, ...sortableCategories];

      print('分类添加完成，当前列表: ${_categories.join(", ")}');

      // 保存并通知监听者
      _savePresets();
      notifyListeners();

      print('分类 "$trimmedCategory" 添加成功，已保存并通知');
    } catch (e) {
      print('添加分类时发生错误 (被捕获): $e');
      // 捕获错误但不抛出，避免影响UI更新
    }
  }

  // 检查分类中是否有计时器
  bool hasTimersInCategory(String category) {
    return _presets.any((preset) => preset.category == category);
  }

  // 删除分类
  void removeCategory(String category) {
    if (_categories.contains(category)) {
      _categories.remove(category);
      _savePresets(); // 保存分类信息
      notifyListeners();
    }
  }

  // 启动计时器
  void startTimer(TimerModel timer) {
    _stopTimer();

    // 清除计时器组状态
    _currentGroup = null;
    _currentTimerIndex = 0;
    _groupTimers = null;

    _currentTimer = timer;
    _totalSeconds = timer.totalSeconds; // 使用总秒数
    _secondsRemaining = _totalSeconds;
    _status = TimerStatus.running;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _completeTimer();
      }
    });

    notifyListeners();
  }

  // 启动间隔计时器
  void startIntervalTimer(IntervalTimerModel timer) {
    // 简化版实现，实际应用中需要处理不同阶段的计时
    startTimer(timer);
  }

  // 启动计时器组
  void startTimerGroup(TimerGroupModel group) {
    if (group.timers.isEmpty) return;

    _stopTimer();

    _currentGroup = group;
    _currentTimerIndex = 0;
    _groupTimers = List.from(group.timers);

    // 启动组中的第一个计时器
    final firstTimer = group.timers.first;
    _currentTimer = firstTimer;
    _totalSeconds = firstTimer.totalSeconds;
    _secondsRemaining = _totalSeconds;
    _status = TimerStatus.running;

    // 启动计时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _completeCurrentTimerInGroup();
      }
    });

    notifyListeners();
  }

  // 辅助方法：设置全局计时器运行状态
  void _setGlobalTimerStatus(bool isRunning) {
    // 调用全局方法设置计时器运行状态
    setGlobalTimerRunningState(isRunning);
  }

  // 重置计时器
  void resetTimer() {
    _currentTimer = null;
    _totalSeconds = 0;
    _secondsRemaining = 0;
    _timer?.cancel();
    _timer = null;
    _status = TimerStatus.idle;
    _isCountdown = true;
    notifyListeners();
  }

  // 重置计时器组
  void resetTimerGroup() {
    _currentGroup = null;
    _currentTimerIndex = 0;
    _currentTimer = null;
    _totalSeconds = 0;
    _secondsRemaining = 0;
    _timer?.cancel();
    _timer = null;
    _status = TimerStatus.idle;
    _isCountdown = true;
    notifyListeners();
  }

  // 完成当前计时器并继续下一个
  void _completeCurrentTimerInGroup() {
    _stopTimer();

    // 发送通知
    NotificationService().showNotification(
      title: '计时完成',
      body: '${_currentTimer?.name ?? "计时器"} 已完成',
    );

    // 继续下一个计时器
    _currentTimerIndex++;
    if (_currentGroup != null &&
        _currentTimerIndex < _currentGroup!.timers.length) {
      // 还有更多计时器
      final nextTimer = _currentGroup!.timers[_currentTimerIndex];
      _currentTimer = nextTimer;
      _totalSeconds = nextTimer.totalSeconds;
      _secondsRemaining = _totalSeconds;
      _status = TimerStatus.running;

      // 启动下一个计时器
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          notifyListeners();
        } else {
          _completeCurrentTimerInGroup();
        }
      });
    } else {
      // 所有计时器都完成了
      _completeTimerGroup();
    }

    notifyListeners();
  }

  // 完成整个计时器组
  void _completeTimerGroup() {
    // 发送通知，表示完成整个计时器组
    NotificationService().showNotification(
      title: '计时器组完成',
      body: '${_currentGroup!.name} 已完成！',
    );

    // 重置计时器组状态
    resetTimerGroup();
  }

  // 暂停计时器
  void pauseTimer() {
    if (_status == TimerStatus.running) {
      _stopTimer();
      _status = TimerStatus.paused;
      notifyListeners();
    }
  }

  // 继续计时器
  void resumeTimer() {
    if (_status == TimerStatus.paused) {
      _status = TimerStatus.running;

      if (isRunningGroup) {
        // 继续计时器组的当前计时器
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            notifyListeners();
          } else {
            _completeCurrentTimerInGroup();
          }
        });
      } else {
        // 继续单个计时器
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            notifyListeners();
          } else {
            _completeTimer();
          }
        });
      }

      notifyListeners();
    }
  }

  // 停止计时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // 完成计时
  void _completeTimer() {
    _stopTimer();
    _status = TimerStatus.completed;

    // 发送通知
    NotificationService().showNotification(
      title: '计时完成',
      body: '${_currentTimer?.name ?? "计时器"} 已完成',
    );

    notifyListeners();
  }

  // 更新类别顺序
  void updateCategoryOrder(List<String> newOrder) {
    _categories = List.from(newOrder);
    _savePresets();
    notifyListeners();
  }

  // 获取按照分类分组的计时器组
  Map<String, List<TimerGroupModel>> get groupsByCategory {
    final result = <String, List<TimerGroupModel>>{};

    // 初始化置顶分类，确保它始终存在
    result['置顶'] = [];

    // 按照分类分组所有计时器组
    for (final group in _groups) {
      // 如果分类不存在，创建一个新的列表
      if (!result.containsKey(group.category)) {
        result[group.category] = [];
      }

      // 将计时器组添加到其原始分类中
      result[group.category]!.add(group);

      // 如果计时器组被置顶，也添加到置顶分类中
      if (group.isPinned) {
        result['置顶']!.add(group);
      }
    }

    return result;
  }

  // 加载普通计时器但不开始计时
  void loadTimer(TimerModel timer) {
    // 确保当前没有活动的计时
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    // 重置计时器组状态
    _currentGroup = null;
    _groupTimers = null;
    _currentTimerIndex = 0;

    // 设置当前计时器
    _currentTimer = timer;
    _secondsRemaining = timer.totalSeconds; // 使用总秒数
    _totalSeconds = _secondsRemaining;
    _status = TimerStatus.paused; // 设置为暂停状态，等待用户手动开始

    notifyListeners();
  }

  // 加载间隔计时器但不开始计时
  void loadIntervalTimer(IntervalTimerModel timer) {
    // 确保当前没有活动的计时
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    // 重置计时器组状态
    _currentGroup = null;
    _groupTimers = null;
    _currentTimerIndex = 0;

    // 设置当前计时器
    _currentTimer = timer;
    _secondsRemaining = timer.totalSeconds; // 使用总秒数
    _totalSeconds = _secondsRemaining;
    _status = TimerStatus.paused; // 设置为暂停状态，等待用户手动开始

    notifyListeners();
  }

  // 加载计时器组但不开始计时
  void loadTimerGroup(TimerGroupModel group) {
    // 确保当前没有活动的计时
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    // 设置计时器组状态
    _currentGroup = group;
    _currentTimerIndex = 0;

    // 为计时器组创建计时器模型列表
    _groupTimers =
        group.timers.map((timer) {
          return TimerModel(
            id: timer.id,
            name: timer.name,
            minutes: timer.minutes,
            seconds: timer.seconds,
            category: group.category,
            isPinned: false,
            iconCode: timer.iconCode,
          );
        }).toList();

    // 设置第一个计时器
    if (_groupTimers != null && _groupTimers!.isNotEmpty) {
      _currentTimer = _groupTimers![0];
      _secondsRemaining = _currentTimer!.totalSeconds;
      _totalSeconds = _secondsRemaining;
    }

    _status = TimerStatus.paused; // 设置为暂停状态，等待用户手动开始

    notifyListeners();
  }

  // 设置当前计时器组中的计时器位置
  void setCurrentTimerInGroup(int index) {
    if (_currentGroup == null ||
        _groupTimers == null ||
        index < 0 ||
        index >= _groupTimers!.length) {
      return;
    }

    // 先暂停当前计时器
    _stopTimer();

    // 设置新的计时器索引
    _currentTimerIndex = index;

    // 设置当前计时器
    _currentTimer = _groupTimers![index];
    _totalSeconds = _currentTimer!.totalSeconds;
    _secondsRemaining = _totalSeconds;
    _status = TimerStatus.paused; // 设置为暂停状态，等待用户手动开始

    notifyListeners();
  }

  // 重置计时器但不退出计时界面
  void resetTimerOnly() {
    _stopTimer();

    if (isRunningGroup) {
      // 重置到计时器组的第一个计时器
      _currentTimerIndex = 0;
      if (_groupTimers != null && _groupTimers!.isNotEmpty) {
        _currentTimer = _groupTimers![0];
        _totalSeconds = _currentTimer!.totalSeconds;
        _secondsRemaining = _totalSeconds;
      }
    } else if (_currentTimer != null) {
      // 重置单个计时器
      _secondsRemaining = _totalSeconds;
    }

    _status = TimerStatus.paused; // 设置为暂停状态，等待用户手动开始
    notifyListeners();
  }

  // 重置当前阶段计时器但不进入下一阶段也不退出计时界面
  void resetCurrentTimerInGroup() {
    if (_currentGroup == null || _groupTimers == null) return;

    _stopTimer();

    // 仅重置当前计时器，不改变索引
    if (_currentTimer != null) {
      _secondsRemaining = _totalSeconds;
    }

    _status = TimerStatus.paused; // 设置为暂停状态，等待用户手动开始
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
