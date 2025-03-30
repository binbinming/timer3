import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/stopwatch_model.dart';

class StopwatchProvider extends ChangeNotifier {
  StopwatchState _state = StopwatchState();
  DateTime? _startTime;
  Timer? _timer;

  StopwatchState get state => _state;

  // 开始秒表
  void start() {
    if (_state.isRunning) return;

    final now = DateTime.now();
    _startTime = now.subtract(_state.elapsedTime);

    _state = _state.toggleRunning();

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      final newElapsed = DateTime.now().difference(_startTime!);
      _state = _state.updateTime(newElapsed);
      notifyListeners();
    });

    notifyListeners();
  }

  // 暂停秒表
  void pause() {
    if (!_state.isRunning) return;

    _timer?.cancel();
    _timer = null;
    _state = _state.toggleRunning();

    notifyListeners();
  }

  // 记录分段时间
  void lap() {
    if (!_state.isRunning) return;

    _state = _state.addLap();
    notifyListeners();
  }

  // 重置秒表
  void reset() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _state = StopwatchState();

    notifyListeners();
  }

  // 获取格式化的当前时间
  String get formattedTime => _state.formattedTime;

  // 获取所有计次时间
  List<LapTime> get laps => _state.laps;

  // 是否正在运行
  bool get isRunning => _state.isRunning;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
