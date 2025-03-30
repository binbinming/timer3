// 计时器相关事件总线

import 'dart:async';

class TimerEvents {
  // 单例实例
  static final TimerEvents _instance = TimerEvents._internal();

  // 分类添加事件流
  final _categoryAddedController = StreamController<String>.broadcast();
  Stream<String> get onCategoryAdded => _categoryAddedController.stream;

  // 工厂构造函数
  factory TimerEvents() {
    return _instance;
  }

  // 内部构造函数
  TimerEvents._internal();

  // 添加分类事件
  void addCategory(String category) {
    _categoryAddedController.add(category);
  }

  // 释放资源
  void dispose() {
    _categoryAddedController.close();
  }
}
