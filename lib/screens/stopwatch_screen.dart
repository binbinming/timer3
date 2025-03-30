import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/stopwatch_provider.dart';
import '../models/stopwatch_model.dart';

class StopwatchScreen extends StatelessWidget {
  const StopwatchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stopwatchProvider = Provider.of<StopwatchProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 时间显示
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                stopwatchProvider.formattedTime,
                style: GoogleFonts.robotoMono(
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  letterSpacing: 2,
                ),
              ),
            ),

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 重置按钮
                FloatingActionButton(
                  heroTag: 'reset_sw',
                  onPressed: () => stopwatchProvider.reset(),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  child: const Icon(Icons.refresh),
                ),

                // 开始/暂停按钮
                FloatingActionButton.large(
                  heroTag: 'start_pause_sw',
                  onPressed: () {
                    if (stopwatchProvider.isRunning) {
                      stopwatchProvider.pause();
                    } else {
                      stopwatchProvider.start();
                    }
                  },
                  backgroundColor:
                      stopwatchProvider.isRunning
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                  child: Icon(
                    stopwatchProvider.isRunning
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),

                // 计次按钮
                FloatingActionButton(
                  heroTag: 'lap_sw',
                  onPressed:
                      stopwatchProvider.isRunning
                          ? stopwatchProvider.lap
                          : null,
                  backgroundColor:
                      stopwatchProvider.isRunning
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                  foregroundColor:
                      stopwatchProvider.isRunning
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                  child: const Icon(Icons.flag),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 计次记录
            Expanded(child: _buildLapList(context, stopwatchProvider.laps)),
          ],
        ),
      ),
    );
  }

  Widget _buildLapList(BuildContext context, List<LapTime> laps) {
    if (laps.isEmpty) {
      return Center(
        child: Text(
          '计次记录将显示在这里',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '计次',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '分段',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                '总计',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // 计次列表
        Expanded(
          child: ListView.builder(
            itemCount: laps.length,
            itemBuilder: (context, index) {
              // 倒序显示，让最新的计次显示在最上面
              final lap = laps[laps.length - 1 - index];

              // 找出最快和最慢的一圈
              final lapTimes = laps.map((l) => l.lapDuration).toList();
              final fastestLap = lapTimes.reduce(
                (a, b) => a.compareTo(b) < 0 ? a : b,
              );
              final slowestLap = lapTimes.reduce(
                (a, b) => a.compareTo(b) > 0 ? a : b,
              );

              // 根据速度设置不同颜色
              Color? textColor;
              if (lap.lapDuration == fastestLap && laps.length > 1) {
                textColor = Colors.green;
              } else if (lap.lapDuration == slowestLap && laps.length > 1) {
                textColor = Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // 计次序号
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${lap.lapNumber}',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 分段时间
                    Text(
                      lap.formattedLap,
                      style: GoogleFonts.robotoMono(
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // 总时间
                    Text(
                      lap.formattedTotal,
                      style: GoogleFonts.robotoMono(
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
