
class AlarmModel {
  final int id;
  final String label;
  final TimeOfDay timeOfDay;
  final List<int> weekdays; // 0-6 表示周日到周六
  final bool isEnabled;
  final bool isPinned;

  AlarmModel({
    required this.id,
    required this.timeOfDay,
    this.label = '闹钟',
    this.weekdays = const [1, 2, 3, 4, 5], // 默认工作日
    this.isEnabled = true,
    this.isPinned = false,
  });

  // 从JSON转换
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      label: json['label'],
      timeOfDay: TimeOfDay(hour: json['hour'], minute: json['minute']),
      weekdays: List<int>.from(json['weekdays']),
      isEnabled: json['isEnabled'] ?? true,
      isPinned: json['isPinned'] ?? false,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
      'weekdays': weekdays,
      'isEnabled': isEnabled,
      'isPinned': isPinned,
    };
  }

  // 复制并修改
  AlarmModel copyWith({
    int? id,
    String? label,
    TimeOfDay? timeOfDay,
    List<int>? weekdays,
    bool? isEnabled,
    bool? isPinned,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      label: label ?? this.label,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weekdays: weekdays ?? this.weekdays,
      isEnabled: isEnabled ?? this.isEnabled,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  // 获取格式化的时间字符串
  String get formattedTime {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 获取周几的文本描述
  String get weekdaysText {
    if (weekdays.length == 7) {
      return '每天';
    }

    if (weekdays.isEmpty) {
      return '从不';
    }

    if (weekdays.length == 5 &&
        weekdays.contains(1) &&
        weekdays.contains(2) &&
        weekdays.contains(3) &&
        weekdays.contains(4) &&
        weekdays.contains(5)) {
      return '工作日';
    }

    if (weekdays.length == 2 && weekdays.contains(0) && weekdays.contains(6)) {
      return '周末';
    }

    final dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays.map((day) => dayNames[day]).join('、');
  }

  // 检查今天是否需要触发闹钟
  bool get shouldRingToday {
    final today = DateTime.now().weekday % 7; // 转换为0-6表示的星期
    return weekdays.contains(today);
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
