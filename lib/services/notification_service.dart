import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  /// 初始化通知服务
  Future<void> init() async {
    // 简化版服务暂不实现通知初始化
    debugPrint('通知服务已初始化（简化版）');
  }

  /// 显示通知
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    debugPrint('显示通知：$title - $body');
    // 简化版服务不实现振动和声音
  }

  /// 显示闹钟通知
  Future<void> showAlarmNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    return showNotification(
      title: title,
      body: body,
      id: id,
      playSound: true,
      vibrate: true,
    );
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    debugPrint('取消所有通知');
  }

  /// 取消指定ID的通知
  Future<void> cancelNotification(int id) async {
    debugPrint('取消通知: $id');
  }
}
