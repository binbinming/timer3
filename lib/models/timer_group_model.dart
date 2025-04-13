import 'timer_model.dart';

/// 计时器组模型，表示一组按顺序执行的计时器
class TimerGroupModel {
  final int id;
  final String name;
  final List<TimerModel> timers; // 该组中的所有计时器
  final bool isPinned;
  final String category;
  final int? iconCode;

  // 获取整个计时器组的总时长（分钟）
  double get totalMinutes =>
      timers.fold(0.0, (sum, timer) => sum + timer.minutes);

  // 获取组内计时器数量
  int get timerCount => timers.length;

  // 生成计时器组说明
  String get description {
    if (timers.isEmpty) return '空计时器组';

    return timers
        .map((t) => '${t.name} (${_formatDuration(t.totalSeconds)})')
        .join(' → ');
  }

  // 格式化持续时间
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours小时${minutes > 0 ? ' $minutes分' : ''}';
    } else if (minutes > 0) {
      return '$minutes分${remainingSeconds > 0 ? ' $remainingSeconds秒' : ''}';
    } else {
      return '$remainingSeconds秒';
    }
  }

  TimerGroupModel({
    required this.id,
    required this.name,
    required this.timers,
    this.isPinned = false,
    this.category = '未分类',
    this.iconCode,
  });

  // 从JSON转换
  factory TimerGroupModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> timersJson = json['timers'] ?? [];
    final List<TimerModel> timers =
        timersJson.map((t) {
          if (t['type'] == 'interval') {
            return IntervalTimerModel.fromJson(t);
          } else {
            return TimerModel.fromJson(t);
          }
        }).toList();

    return TimerGroupModel(
      id: json['id'],
      name: json['name'],
      timers: timers,
      isPinned: json['isPinned'] ?? false,
      category: json['category'] ?? '未分类',
      iconCode: json['iconCode'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timers': timers.map((t) => t.toJson()).toList(),
      'isPinned': isPinned,
      'category': category,
      'iconCode': iconCode,
      'type': 'group', // 标识为组类型
    };
  }

  // 复制并修改
  TimerGroupModel copyWith({
    int? id,
    String? name,
    List<TimerModel>? timers,
    bool? isPinned,
    String? category,
    int? iconCode,
  }) {
    return TimerGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      timers: timers ?? List.from(this.timers),
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      iconCode: iconCode ?? this.iconCode,
    );
  }
}
