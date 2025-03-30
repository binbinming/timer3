import 'package:flutter/material.dart';
import '../models/timer_preset_model.dart';

class TimerPresetCard extends StatelessWidget {
  final TimerPresetModel preset;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTogglePin;
  final bool isPinned;

  const TimerPresetCard({
    super.key,
    required this.preset,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onTogglePin,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    print('TimerPresetCard: ${preset.name}, isPinned=$isPinned');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 上部内容：图标和名称
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 左侧图标
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _getColorByType(preset.type, context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconByType(preset.type),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // 预设名称
                    Text(
                      preset.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),

                    // 预设时间
                    _buildDurationText(preset),
                  ],
                ),
              ),

              // 底部按钮行
              SizedBox(
                height: 22,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onTogglePin != null)
                      _buildActionButton(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        isPinned ? Theme.of(context).colorScheme.primary : null,
                        onTogglePin,
                        isPinned ? '取消置顶' : '置顶',
                      ),
                    _buildActionButton(Icons.edit, null, onEdit, '编辑'),
                    _buildActionButton(
                      Icons.delete,
                      Theme.of(context).colorScheme.error,
                      onDelete,
                      '删除',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建操作按钮
  Widget _buildActionButton(
    IconData icon,
    Color? color,
    VoidCallback? onPressed,
    String tooltip,
  ) {
    return SizedBox(
      width: 20,
      height: 20,
      child: IconButton(
        icon: Icon(icon, size: 12, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
          maxWidth: 20,
          maxHeight: 20,
        ),
      ),
    );
  }

  // 根据类型获取对应图标
  IconData _getIconByType(TimerPresetType type) {
    // 如果有自定义图标则使用自定义图标
    if (preset.iconCode != null) {
      return IconData(preset.iconCode!, fontFamily: 'MaterialIcons');
    }

    // 否则使用默认图标
    switch (type) {
      case TimerPresetType.work:
        return Icons.work;
      case TimerPresetType.study:
        return Icons.school;
      case TimerPresetType.exercise:
        return Icons.fitness_center;
      case TimerPresetType.meditation:
        return Icons.self_improvement;
      case TimerPresetType.cooking:
        return Icons.restaurant;
      case TimerPresetType.other:
        return Icons.timer;
    }
  }

  // 根据类型获取对应颜色
  Color _getColorByType(TimerPresetType type, BuildContext context) {
    switch (type) {
      case TimerPresetType.work:
        return Colors.blue;
      case TimerPresetType.study:
        return Colors.green;
      case TimerPresetType.exercise:
        return Colors.orange;
      case TimerPresetType.meditation:
        return Colors.purple;
      case TimerPresetType.cooking:
        return Colors.red;
      case TimerPresetType.other:
        return Colors.grey;
    }
  }

  // 根据类型获取文本
  String _getTypeText(TimerPresetType type) {
    switch (type) {
      case TimerPresetType.work:
        return '工作';
      case TimerPresetType.study:
        return '学习';
      case TimerPresetType.exercise:
        return '锻炼';
      case TimerPresetType.meditation:
        return '冥想';
      case TimerPresetType.cooking:
        return '烹饪';
      case TimerPresetType.other:
        return '其他';
    }
  }

  // 显示计时器时长
  Widget _buildDurationText(TimerPresetModel preset) {
    return Text(
      preset.formattedDuration,
      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}
