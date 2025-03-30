class LapTime {
  final int lapNumber;
  final Duration lapDuration;
  final Duration totalDuration;

  const LapTime({
    required this.lapNumber,
    required this.lapDuration,
    required this.totalDuration,
  });

  // 获取格式化的圈时显示
  String get formattedLap {
    return _formatDuration(lapDuration);
  }

  // 获取格式化的总时间显示
  String get formattedTotal {
    return _formatDuration(totalDuration);
  }

  // 格式化时间为 HH:MM:SS.ms 或 MM:SS.ms
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    // 毫秒保留两位
    final msStr = (milliseconds ~/ 10).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$msStr';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$msStr';
    }
  }

  // 用于比较排序
  int compareTo(Duration other) {
    return lapDuration.compareTo(other);
  }
}

class StopwatchState {
  final Duration elapsedTime;
  final bool isRunning;
  final List<LapTime> laps;

  StopwatchState({
    this.elapsedTime = Duration.zero,
    this.isRunning = false,
    this.laps = const [],
  });

  // 创建带有新计次的状态
  StopwatchState addLap() {
    if (!isRunning) return this;

    final newLapNumber = laps.length + 1;
    final lastLapTime =
        laps.isNotEmpty ? laps.last.totalDuration : Duration.zero;
    final lapDuration = elapsedTime - lastLapTime;

    final newLap = LapTime(
      lapNumber: newLapNumber,
      totalDuration: elapsedTime,
      lapDuration: lapDuration,
    );

    return StopwatchState(
      elapsedTime: elapsedTime,
      isRunning: isRunning,
      laps: [...laps, newLap],
    );
  }

  // 更新时间的状态
  StopwatchState updateTime(Duration newElapsedTime) {
    return StopwatchState(
      elapsedTime: newElapsedTime,
      isRunning: isRunning,
      laps: laps,
    );
  }

  // 切换运行状态
  StopwatchState toggleRunning() {
    return StopwatchState(
      elapsedTime: elapsedTime,
      isRunning: !isRunning,
      laps: laps,
    );
  }

  // 重置状态
  StopwatchState reset() {
    return StopwatchState();
  }

  // 获取格式化的时间字符串
  String get formattedTime {
    final hours = elapsedTime.inHours;
    final minutes = (elapsedTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsedTime.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((elapsedTime.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');

    return hours > 0
        ? '$hours:$minutes:$seconds.$milliseconds'
        : '$minutes:$seconds.$milliseconds';
  }
}
