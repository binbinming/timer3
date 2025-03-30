import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';
import '../models/alarm_model.dart';
import '../widgets/alarm_list_item.dart';
import '../widgets/add_alarm_dialog.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarmProvider = Provider.of<AlarmProvider>(context);
    final pinnedAlarms = alarmProvider.pinnedAlarms;
    final unpinnedAlarms = alarmProvider.unpinnedAlarms;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 如果有置顶闹钟，显示置顶区域
            if (pinnedAlarms.isNotEmpty) ...[
              _buildSectionTitle(context, '置顶闹钟'),
              const SizedBox(height: 8),
              ...pinnedAlarms.map(
                (alarm) => _buildAlarmItem(context, alarm, alarmProvider),
              ),
              const SizedBox(height: 16),
            ],

            // 其他闹钟区域
            _buildSectionTitle(context, '所有闹钟'),
            const SizedBox(height: 8),
            if (unpinnedAlarms.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无闹钟'),
                ),
              )
            else
              ...unpinnedAlarms.map(
                (alarm) => _buildAlarmItem(context, alarm, alarmProvider),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmDialog(context, alarmProvider),
        tooltip: '添加闹钟',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAlarmItem(
    BuildContext context,
    AlarmModel alarm,
    AlarmProvider alarmProvider,
  ) {
    return AlarmListItem(
      alarm: alarm,
      onToggle: (value) {
        alarmProvider.toggleAlarmEnabled(alarm.id);
      },
      onPin: (value) {
        alarmProvider.toggleAlarmPinned(alarm.id);
      },
      onEdit: () {
        _showAddAlarmDialog(context, alarmProvider, alarm: alarm);
      },
      onDelete: () {
        alarmProvider.deleteAlarm(alarm.id);
      },
    );
  }

  void _showAddAlarmDialog(
    BuildContext context,
    AlarmProvider alarmProvider, {
    AlarmModel? alarm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AddAlarmDialog(alarm: alarm),
    ).then((result) {
      if (result != null && result is AlarmModel) {
        if (alarm == null) {
          alarmProvider.addAlarm(result);
        } else {
          alarmProvider.updateAlarm(result);
        }
      }
    });
  }
}
