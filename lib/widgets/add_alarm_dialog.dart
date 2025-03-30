import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart'
    as material
    show TimeOfDay, showTimePicker;
import '../models/alarm_model.dart';

class AddAlarmDialog extends StatefulWidget {
  final AlarmModel? alarm; // 如果为null则是添加，否则是编辑

  const AddAlarmDialog({Key? key, this.alarm}) : super(key: key);

  @override
  State<AddAlarmDialog> createState() => _AddAlarmDialogState();
}

class _AddAlarmDialogState extends State<AddAlarmDialog> {
  late TimeOfDay _timeOfDay;
  late String _label;
  late List<int> _weekdays;
  final TextEditingController _labelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化值，如果是编辑则使用传入的闹钟值，否则使用默认值
    if (widget.alarm != null) {
      _timeOfDay = widget.alarm!.timeOfDay;
      _label = widget.alarm!.label;
      _weekdays = List.from(widget.alarm!.weekdays);
    } else {
      _timeOfDay = TimeOfDay(hour: 7, minute: 0);
      _label = '';
      _weekdays = List.filled(7, 0);
    }
    _labelController.text = _label;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.alarm == null ? '添加闹钟' : '编辑闹钟'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 时间选择器
            _buildTimePicker(),

            const SizedBox(height: 16),

            // 标签输入框
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '输入闹钟标签（可选）',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _label = value;
              },
            ),

            const SizedBox(height: 16),

            // 重复日期选择
            _buildWeekdaysPicker(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _saveAlarm, child: const Text('保存')),
      ],
    );
  }

  // 构建时间选择器
  Widget _buildTimePicker() {
    return InkWell(
      onTap: _showTimePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Text(
          '${_timeOfDay.hour.toString().padLeft(2, '0')}:${_timeOfDay.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 显示时间选择对话框
  void _showTimePicker() async {
    // 转换为Flutter的TimeOfDay用于显示选择器
    final flutterTimeOfDay = material.TimeOfDay(
      hour: _timeOfDay.hour,
      minute: _timeOfDay.minute,
    );

    final result = await material.showTimePicker(
      context: context,
      initialTime: flutterTimeOfDay,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _timeOfDay = TimeOfDay(hour: result.hour, minute: result.minute);
      });
    }
  }

  // 构建星期选择器
  Widget _buildWeekdaysPicker() {
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '重复',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            // 将索引转换为与AlarmModel匹配的星期表示法（0代表周日，1-6代表周一至周六）
            final weekdayIndex = (index + 1) % 7; // 0-6

            return FilterChip(
              label: Text(days[index]),
              selected: _weekdays.contains(weekdayIndex),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_weekdays.contains(weekdayIndex)) {
                      _weekdays.add(weekdayIndex);
                    }
                  } else {
                    _weekdays.remove(weekdayIndex);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  // 保存闹钟
  void _saveAlarm() {
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch,
      label: _label,
      timeOfDay: _timeOfDay,
      weekdays: _weekdays,
      isEnabled: widget.alarm?.isEnabled ?? true,
      isPinned: widget.alarm?.isPinned ?? false,
    );

    Navigator.pop(context, alarm);
  }
}
