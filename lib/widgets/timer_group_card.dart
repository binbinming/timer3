import 'package:flutter/material.dart';
import '../models/timer_group_model.dart';

class TimerGroupCard extends StatelessWidget {
  final TimerGroupModel group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTogglePin;
  final bool isPinned;

  const TimerGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onTogglePin,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部行：图标和基本信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧图标
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getIconColor(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIconData(), color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),

                  // 名称和信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 名称和计时器数量
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.timerCount}个',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // 总时长
                        Text(
                          '总时长: ${_formatDuration((group.totalMinutes * 60).round())}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // 计时器列表
              Text(
                '计时器:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                group.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // 编辑/删除按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onTogglePin != null)
                    IconButton(
                      icon: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 14,
                        color:
                            isPinned
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      onPressed: onTogglePin,
                      tooltip: isPinned ? '取消置顶' : '置顶',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 14),
                    onPressed: onEdit,
                    tooltip: '编辑',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: '删除',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取图标
  IconData _getIconData() {
    if (group.iconCode != null) {
      return IconData(group.iconCode!, fontFamily: 'MaterialIcons');
    }

    // 默认图标
    if (group.category == '运动健身') {
      return Icons.fitness_center;
    } else if (group.category == '学习') {
      return Icons.school;
    } else if (group.category == '冥想放松') {
      return Icons.self_improvement;
    } else if (group.category == '工作') {
      return Icons.work;
    } else {
      return Icons.timer;
    }
  }

  // 获取图标颜色
  Color _getIconColor(BuildContext context) {
    if (group.category == '运动健身') {
      return Colors.orange;
    } else if (group.category == '学习') {
      return Colors.blue;
    } else if (group.category == '冥想放松') {
      return Colors.purple;
    } else if (group.category == '工作') {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  // 格式化持续时间
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours小时${minutes > 0 ? ' $minutes分' : ''}';
    } else if (minutes > 0) {
      return '$minutes分${remainingSeconds > 0 ? ' $remainingSeconds秒' : ''}';
    } else {
      return '$remainingSeconds秒';
    }
  }
}
