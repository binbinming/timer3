class TimerModel {
  final int id;
  final String name;
  final double minutes; // 改为double类型，支持小数分钟
  final int seconds; // 新增秒数字段
  final bool isPinned;
  final String category;
  final String? originalCategory; // 记录置顶前的原始分类
  final int? iconCode; // 用户自定义图标代码

  TimerModel({
    required this.id,
    required this.name,
    required this.minutes,
    this.seconds = 0, // 默认为0秒
    this.isPinned = false,
    this.category = '未分类',
    this.originalCategory,
    this.iconCode, // 可为空，表示使用默认图标
  });

  // 获取总秒数
  int get totalSeconds => (minutes * 60).round() + seconds;

  // 根据总秒数创建计时器的工厂方法
  factory TimerModel.fromSeconds({
    required int id,
    required String name,
    required int totalSeconds,
    String category = '未分类',
    bool isPinned = false,
    int? iconCode,
  }) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return TimerModel(
      id: id,
      name: name,
      minutes: minutes.toDouble(),
      seconds: seconds,
      category: category,
      isPinned: isPinned,
      iconCode: iconCode,
    );
  }

  // 从JSON转换
  factory TimerModel.fromJson(Map<String, dynamic> json) {
    return TimerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      minutes:
          json['minutes'] is int
              ? (json['minutes'] as int).toDouble()
              : json['minutes'] as double,
      seconds: json['seconds'] as int? ?? 0, // 兼容旧数据
      isPinned: json['isPinned'] as bool? ?? false,
      category: json['category'] as String? ?? '未分类',
      originalCategory: json['originalCategory'],
      iconCode: json['iconCode'] as int?,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'minutes': minutes,
      'seconds': seconds,
      'isPinned': isPinned,
      'category': category,
      'originalCategory': originalCategory,
      'iconCode': iconCode, // 保存图标代码
    };
  }

  // 复制并修改
  TimerModel copyWith({
    int? id,
    String? name,
    double? minutes,
    int? seconds,
    bool? isPinned,
    String? category,
    String? originalCategory,
    int? iconCode,
  }) {
    return TimerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      originalCategory: originalCategory ?? this.originalCategory,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  @override
  String toString() {
    final minutesPart = minutes > 0 ? '${minutes.toInt()}分' : '';
    final secondsPart = seconds > 0 ? '$seconds秒' : '';
    final durationText = minutesPart + secondsPart;
    return '$name ($durationText)';
  }
}

// 间隔计时器模型
class IntervalTimerModel extends TimerModel {
  final int workSeconds;
  final int restSeconds;
  final int sets;

  IntervalTimerModel({
    required super.id,
    required super.name,
    this.workSeconds = 30,
    this.restSeconds = 10,
    this.sets = 4,
    super.isPinned,
    super.category = '间隔训练',
    super.originalCategory,
    super.iconCode,
  }) : super(
         minutes: ((workSeconds + restSeconds) * sets) / 60,
         seconds: ((workSeconds + restSeconds) * sets) % 60,
       );

  // 从JSON转换
  factory IntervalTimerModel.fromJson(Map<String, dynamic> json) {
    return IntervalTimerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      workSeconds: json['workSeconds'] as int,
      restSeconds: json['restSeconds'] as int,
      sets: json['sets'] as int,
      isPinned: json['isPinned'] as bool? ?? false,
      category: json['category'] as String? ?? '间隔训练',
      originalCategory: json['originalCategory'] as String?,
      iconCode: json['iconCode'] as int?,
    );
  }

  // 转换为JSON
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data.addAll({
      'workSeconds': workSeconds,
      'restSeconds': restSeconds,
      'sets': sets,
      'type': 'interval',
    });
    return data;
  }

  // 复制并修改
  @override
  IntervalTimerModel copyWith({
    int? id,
    String? name,
    double? minutes,
    int? seconds,
    bool? isPinned,
    String? category,
    String? originalCategory,
    int? iconCode,
    int? workSeconds,
    int? restSeconds,
    int? sets,
  }) {
    return IntervalTimerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      originalCategory: originalCategory ?? this.originalCategory,
      iconCode: iconCode ?? this.iconCode,
    );
  }
}
