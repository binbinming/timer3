import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmListItem extends StatelessWidget {
  final AlarmModel alarm;
  final Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onPin;

  const AlarmListItem({
    Key? key,
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 启用/禁用开关
                Switch(value: alarm.isEnabled, onChanged: onToggle),

                // 时间显示
                Text(
                  alarm.formattedTime,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        alarm.isEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                // 置顶按钮
                IconButton(
                  icon: Icon(
                    alarm.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color:
                        alarm.isPinned
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => onPin(!alarm.isPinned),
                  tooltip: alarm.isPinned ? '取消置顶' : '置顶',
                ),

                // 编辑按钮
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: onEdit,
                  tooltip: '编辑',
                ),

                // 删除按钮
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: '删除',
                ),
              ],
            ),

            // 闹钟标签
            if (alarm.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                child: Text(
                  alarm.label,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        alarm.isEnabled
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // 重复日期显示
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                alarm.weekdaysText,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
