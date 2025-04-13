enum TimerPresetType { work, study, exercise, meditation, cooking, other }

class TimerPresetModel {
  final String id;
  final String name;
  final int durationSeconds;
  final TimerPresetType type;
  final bool isPinned;
  final String category;
  final int? iconCode; // 用户自定义图标代码

  TimerPresetModel({
    required this.id,
    required this.name,
    required this.durationSeconds,
    this.type = TimerPresetType.other,
    this.isPinned = false,
    this.category = '未分类',
    this.iconCode,
  });

  // 获取时、分、秒
  int get hours => durationSeconds ~/ 3600;
  int get minutes => (durationSeconds % 3600) ~/ 60;
  int get seconds => durationSeconds % 60;

  // 获取格式化的时间字符串
  String get formattedDuration {
    final h = hours;
    final m = minutes;
    final s = seconds;

    if (h > 0) {
      return '$h小时${m > 0 ? ' $m分' : ''}${s > 0 ? ' $s秒' : ''}';
    } else if (m > 0) {
      return '$m分${s > 0 ? ' $s秒' : ''}';
    } else {
      return '$s秒';
    }
  }

  // 从JSON创建
  factory TimerPresetModel.fromJson(Map<String, dynamic> json) {
    return TimerPresetModel(
      id: json['id'],
      name: json['name'],
      durationSeconds: json['durationSeconds'],
      type: TimerPresetType.values[json['type']],
      isPinned: json['isPinned'] ?? false,
      category: json['category'] ?? '',
      iconCode: json['iconCode'], // 读取图标代码
    );
  }

  // 转为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationSeconds': durationSeconds,
      'type': type.index,
      'isPinned': isPinned,
      'category': category,
      'iconCode': iconCode, // 保存图标代码
    };
  }

  // 复制一个新的预设模型
  TimerPresetModel copyWith({
    String? id,
    String? name,
    int? durationSeconds,
    TimerPresetType? type,
    bool? isPinned,
    String? category,
    int? iconCode,
  }) {
    return TimerPresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      iconCode: iconCode ?? this.iconCode,
    );
  }
}
