import 'package:flutter/material.dart';
import '../models/timer_model.dart';
import '../models/timer_group_model.dart';
import '../providers/timer_provider.dart';
import 'package:provider/provider.dart';

class AddTimerGroupDialog extends StatefulWidget {
  final TimerGroupModel? group; // 如果不为null则是编辑

  const AddTimerGroupDialog({super.key, this.group});

  @override
  State<AddTimerGroupDialog> createState() => _AddTimerGroupDialogState();
}

class _AddTimerGroupDialogState extends State<AddTimerGroupDialog> {
  late String _name;
  late String _category;
  late List<TimerModel> _timers;
  late bool _isPinned;
  int? _iconCode;

  final TextEditingController _nameController = TextEditingController();

  // 编辑单个计时器的控制器
  final List<TextEditingController> _timerNameControllers = [];
  final List<TextEditingController> _timerMinuteControllers = [];
  final List<TextEditingController> _timerSecondControllers = [];

  @override
  void initState() {
    super.initState();

    // 初始化值，如果是编辑则使用传入的组值，否则使用默认值
    if (widget.group != null) {
      _name = widget.group!.name;
      _category = widget.group!.category;
      _timers = List.from(widget.group!.timers);
      _isPinned = widget.group!.isPinned;
      _iconCode = widget.group!.iconCode;
    } else {
      _name = '';
      _category = '未分类';
      _timers = []; // 默认空列表
      _isPinned = false;
      _iconCode = null;
    }

    _nameController.text = _name;

    // 为每个计时器创建控制器
    _initTimerControllers();
  }

  void _initTimerControllers() {
    // 清空现有控制器
    for (var controller in [
      ..._timerNameControllers,
      ..._timerMinuteControllers,
      ..._timerSecondControllers,
    ]) {
      controller.dispose();
    }
    _timerNameControllers.clear();
    _timerMinuteControllers.clear();
    _timerSecondControllers.clear();

    // 为每个计时器创建新的控制器
    for (var timer in _timers) {
      final nameController = TextEditingController(text: timer.name);
      _timerNameControllers.add(nameController);

      final minutes = timer.minutes;
      const seconds = 0; // 假设没有秒级精度，可以根据需要修改

      final minuteController = TextEditingController(text: minutes.toString());
      _timerMinuteControllers.add(minuteController);

      final secondController = TextEditingController(text: seconds.toString());
      _timerSecondControllers.add(secondController);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    // 释放所有计时器控制器
    for (var controller in [
      ..._timerNameControllers,
      ..._timerMinuteControllers,
      ..._timerSecondControllers,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              widget.group == null ? '创建计时器组' : '编辑计时器组',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // 基本信息
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '计时器组名称',
                hintText: '例如: 间歇训练',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _name = value,
            ),
            const SizedBox(height: 16),

            // 分类选择
            _buildCategoryPicker(timerProvider),
            const SizedBox(height: 16),

            // 置顶选项
            Row(
              children: [
                Checkbox(
                  value: _isPinned,
                  onChanged: (value) {
                    setState(() {
                      _isPinned = value ?? false;
                    });
                  },
                ),
                const Text('置顶此计时器组'),
              ],
            ),
            const SizedBox(height: 16),

            // 计时器列表标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('计时器列表', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addNewTimer,
                  tooltip: '添加计时器',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 计时器列表（使用Expanded确保不会溢出）
            Expanded(
              child:
                  _timers.isEmpty
                      ? const Center(child: Text('请添加至少一个计时器'))
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _timers.length,
                        itemBuilder: (context, index) {
                          return _buildTimerItem(index);
                        },
                      ),
            ),

            const SizedBox(height: 16),

            // 总时长显示
            Text(
              '总时长: ${_formatTotalDuration()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _timers.isEmpty ? null : _saveTimerGroup,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建分类选择器
  Widget _buildCategoryPicker(TimerProvider timerProvider) {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: const InputDecoration(
        labelText: '分类',
        border: OutlineInputBorder(),
      ),
      items: [
        ...timerProvider.categories.map(
          (category) =>
              DropdownMenuItem(value: category, child: Text(category)),
        ),
        const DropdownMenuItem(
          value: '新建分类',
          child: Row(
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 8),
              Text('新建分类'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == '新建分类') {
          _showCreateCategoryDialog();
        } else if (value != null) {
          setState(() {
            _category = value;
          });
        }
      },
    );
  }

  // 显示创建新分类的对话框
  void _showCreateCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('新建分类'),
            content: TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                hintText: '输入新的分类名称',
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                final newCategory = categoryController.text.trim();
                if (newCategory.isNotEmpty &&
                    !timerProvider.categories.contains(newCategory)) {
                  timerProvider.addCategory(newCategory);
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _category = newCategory;
                  });
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final newCategory = categoryController.text.trim();
                  if (newCategory.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('请输入分类名称')));
                    return;
                  }

                  if (timerProvider.categories.contains(newCategory)) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('该分类已存在')));
                    return;
                  }

                  timerProvider.addCategory(newCategory);
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _category = newCategory;
                  });
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  // 构建单个计时器项
  Widget _buildTimerItem(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行：序号和删除按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '计时器 ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeTimer(index),
                  tooltip: '删除此计时器',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 计时器名称
            TextField(
              controller: _timerNameControllers[index],
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '例如: 热身',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateTimerName(index, value);
              },
            ),
            const SizedBox(height: 8),

            // 计时器时长
            Row(
              children: [
                // 分钟
                Expanded(
                  child: TextField(
                    controller: _timerMinuteControllers[index],
                    decoration: const InputDecoration(
                      labelText: '分钟',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _updateTimerMinutes(index, value);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // 秒
                Expanded(
                  child: TextField(
                    controller: _timerSecondControllers[index],
                    decoration: const InputDecoration(
                      labelText: '秒',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _updateTimerSeconds(index, value);
                    },
                  ),
                ),
              ],
            ),

            // 重新排序按钮（可选）
            if (_timers.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: index > 0 ? () => _moveTimerUp(index) : null,
                      tooltip: '上移',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed:
                          index < _timers.length - 1
                              ? () => _moveTimerDown(index)
                              : null,
                      tooltip: '下移',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 添加新计时器
  void _addNewTimer() {
    setState(() {
      final newTimer = TimerModel(
        id: DateTime.now().millisecondsSinceEpoch,
        name: '新计时器 ${_timers.length + 1}',
        minutes: 1,
        category: _category,
      );

      _timers.add(newTimer);

      // 添加控制器
      _timerNameControllers.add(TextEditingController(text: newTimer.name));
      _timerMinuteControllers.add(TextEditingController(text: '1'));
      _timerSecondControllers.add(TextEditingController(text: '0'));
    });
  }

  // 移除计时器
  void _removeTimer(int index) {
    setState(() {
      _timers.removeAt(index);

      // 释放并移除控制器
      _timerNameControllers[index].dispose();
      _timerMinuteControllers[index].dispose();
      _timerSecondControllers[index].dispose();

      _timerNameControllers.removeAt(index);
      _timerMinuteControllers.removeAt(index);
      _timerSecondControllers.removeAt(index);
    });
  }

  // 更新计时器名称
  void _updateTimerName(int index, String name) {
    if (index < _timers.length) {
      setState(() {
        _timers[index] = _timers[index].copyWith(name: name);
      });
    }
  }

  // 更新计时器分钟数
  void _updateTimerMinutes(int index, String minutesStr) {
    if (index < _timers.length) {
      final minutes = int.tryParse(minutesStr) ?? 0;
      final seconds = int.tryParse(_timerSecondControllers[index].text) ?? 0;

      setState(() {
        _timers[index] = _timers[index].copyWith(
          minutes: minutes.toDouble(),
          seconds: seconds,
        );
      });
    }
  }

  // 更新计时器秒数
  void _updateTimerSeconds(int index, String secondsStr) {
    if (index < _timers.length) {
      final seconds = int.tryParse(secondsStr) ?? 0;
      final minutes = int.tryParse(_timerMinuteControllers[index].text) ?? 0;

      setState(() {
        _timers[index] = _timers[index].copyWith(
          minutes: minutes.toDouble(),
          seconds: seconds,
        );
      });
    }
  }

  // 上移计时器
  void _moveTimerUp(int index) {
    if (index > 0) {
      setState(() {
        final temp = _timers[index];
        _timers[index] = _timers[index - 1];
        _timers[index - 1] = temp;

        // 交换控制器
        final nameTemp = _timerNameControllers[index];
        _timerNameControllers[index] = _timerNameControllers[index - 1];
        _timerNameControllers[index - 1] = nameTemp;

        final minuteTemp = _timerMinuteControllers[index];
        _timerMinuteControllers[index] = _timerMinuteControllers[index - 1];
        _timerMinuteControllers[index - 1] = minuteTemp;

        final secondTemp = _timerSecondControllers[index];
        _timerSecondControllers[index] = _timerSecondControllers[index - 1];
        _timerSecondControllers[index - 1] = secondTemp;
      });
    }
  }

  // 下移计时器
  void _moveTimerDown(int index) {
    if (index < _timers.length - 1) {
      setState(() {
        final temp = _timers[index];
        _timers[index] = _timers[index + 1];
        _timers[index + 1] = temp;

        // 交换控制器
        final nameTemp = _timerNameControllers[index];
        _timerNameControllers[index] = _timerNameControllers[index + 1];
        _timerNameControllers[index + 1] = nameTemp;

        final minuteTemp = _timerMinuteControllers[index];
        _timerMinuteControllers[index] = _timerMinuteControllers[index + 1];
        _timerMinuteControllers[index + 1] = minuteTemp;

        final secondTemp = _timerSecondControllers[index];
        _timerSecondControllers[index] = _timerSecondControllers[index + 1];
        _timerSecondControllers[index + 1] = secondTemp;
      });
    }
  }

  // 格式化总时长
  String _formatTotalDuration() {
    // 计算总秒数
    final totalSeconds = _timers.fold(
      0,
      (sum, timer) => sum + timer.totalSeconds,
    );

    // 转换为小时、分钟、秒
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours小时${minutes > 0 ? ' $minutes分' : ''}${seconds > 0 ? ' $seconds秒' : ''}';
    } else if (minutes > 0) {
      return '$minutes分${seconds > 0 ? ' $seconds秒' : ''}';
    } else {
      return '$seconds秒';
    }
  }

  // 保存计时器组
  void _saveTimerGroup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      // 显示错误
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入计时器组名称')));
      return;
    }

    if (_timers.isEmpty) {
      // 显示错误
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请添加至少一个计时器')));
      return;
    }

    // 创建计时器组
    final timerGroup = TimerGroupModel(
      id: widget.group?.id ?? 0, // 如果是新建则ID为0，provider会分配新ID
      name: name,
      timers: _timers,
      isPinned: _isPinned,
      category: _category,
      iconCode: _iconCode,
    );

    // 返回TimerGroupModel对象，而不是布尔值
    Navigator.of(context).pop(timerGroup);
  }
}
