// 全局事件通知模型

import 'package:flutter/foundation.dart';

/// 应用程序全局通知事件
class AppEvents {
  // 单例实例
  static final AppEvents _instance = AppEvents._internal();

  // 分类添加通知
  final categoryAddedNotifier = ValueNotifier<String?>(null);

  // 工厂构造函数
  factory AppEvents() {
    return _instance;
  }

  // 私有构造函数
  AppEvents._internal();
}
