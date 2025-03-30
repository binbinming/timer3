import 'package:flutter/material.dart';
import '../models/timer_preset_model.dart';
import '../providers/timer_provider.dart';
import 'package:provider/provider.dart';
import '../models/app_model.dart'; // 导入新的模型

class AddTimerDialog extends StatefulWidget {
  final TimerPresetModel? preset; // 如果不为null则是编辑

  const AddTimerDialog({super.key, this.preset});

  @override
  State<AddTimerDialog> createState() => _AddTimerDialogState();
}

class _AddTimerDialogState extends State<AddTimerDialog> {
  late String _name;
  late int _hours;
  late int _minutes;
  late int _seconds;
  late TimerPresetType _type;
  late bool _isPinned; // 添加置顶状态
  late String _category; // 添加分类
  int? _iconCode; // 添加图标代码

  final TextEditingController _nameController = TextEditingController();
  late final VoidCallback _categoryListener;

  // 常用图标列表
  final List<IconData> _commonIcons = [
    Icons.timer,
    Icons.work,
    Icons.school,
    Icons.fitness_center,
    Icons.self_improvement,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.book,
    Icons.code,
    Icons.sports_basketball,
    Icons.music_note,
    Icons.movie,
    Icons.call,
    Icons.directions_run,
    Icons.spa,
    Icons.pets,
    Icons.shopping_cart,
    Icons.meeting_room,
    Icons.favorite,
    Icons.bed,
  ];

  @override
  void initState() {
    super.initState();

    // 初始化值，如果是编辑则使用传入的预设值，否则使用默认值
    if (widget.preset != null) {
      _name = widget.preset!.name;

      int totalSeconds = widget.preset!.durationSeconds;
      _hours = totalSeconds ~/ 3600;
      totalSeconds %= 3600;
      _minutes = totalSeconds ~/ 60;
      _seconds = totalSeconds % 60;

      _type = widget.preset!.type;
      _isPinned = widget.preset!.isPinned; // 初始化置顶状态
      _category =
          widget.preset!.category.isNotEmpty
              ? widget.preset!.category
              : _getCategoryFromPresetType(_type); // 从类型获取分类
      _iconCode = widget.preset!.iconCode; // 初始化图标代码
    } else {
      _name = '';
      _hours = 0;
      _minutes = 0;
      _seconds = 0;
      _type = TimerPresetType.work;
      _isPinned = false; // 默认不置顶
      _category = '工作'; // 默认分类
      _iconCode = null; // 默认无自定义图标
    }
    _nameController.text = _name;

    // 监听分类添加事件
    _categoryListener = () {
      final newCategory = AppEvents().categoryAddedNotifier.value;
      if (newCategory != null && mounted) {
        setState(() {
          _category = newCategory;
        });
      }
    };
    AppEvents().categoryAddedNotifier.addListener(_categoryListener);
  }

  @override
  void dispose() {
    _nameController.dispose();
    AppEvents().categoryAddedNotifier.removeListener(_categoryListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final categories = timerProvider.categories;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Text(
              widget.preset == null ? '添加计时器' : '编辑计时器',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 内容区域 - 可滚动
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 名称输入框
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        hintText: '输入计时器名称',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _name = value;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 时间选择器
                    _buildDurationPicker(),

                    const SizedBox(height: 16),

                    // 分类选择器
                    _buildCategoryPicker(categories),

                    const SizedBox(height: 16),

                    // 图标选择器
                    _buildIconPicker(),

                    const SizedBox(height: 16),

                    // 置顶选项
                    _buildPinOption(),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: _validateAndSave,
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
  Widget _buildCategoryPicker(List<String> categories) {
    // 创建一个新列表，包含现有分类和新建分类选项
    final allOptions = List<String>.from(categories);

    // 确保 _category 是一个有效的选项
    if (!allOptions.contains(_category) && _category != '+ 新建分类') {
      // 如果当前分类不在列表中，添加它（可能是刚创建的新分类）
      allOptions.add(_category);
    }

    // 添加新建分类选项
    allOptions.add('+ 新建分类');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '分类',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // 添加分类管理按钮
            TextButton.icon(
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('管理分类'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () {
                _showCategoryManagementDialog(categories);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items:
              allOptions.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              if (value == '+ 新建分类') {
                // 显示创建新分类的对话框
                _showCreateCategoryDialog();
              } else {
                setState(() {
                  _category = value;
                  // 根据分类更新类型
                  _type = _getPresetTypeFromCategory(value);
                });
              }
            }
          },
        ),
      ],
    );
  }

  // 显示分类管理对话框
  void _showCategoryManagementDialog(List<String> categories) {
    // 默认系统分类列表，这些分类不可删除
    final defaultCategories = ['工作', '学习', '运动健身', '冥想放松', '生活', '未分类'];
    final customCategories =
        categories.where((c) => !defaultCategories.contains(c)).toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('管理分类'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  customCategories.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('没有自定义分类'),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: customCategories.length,
                        itemBuilder: (context, index) {
                          final category = customCategories[index];
                          return ListTile(
                            title: Text(category),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _confirmDeleteCategory(category);
                              },
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showCreateCategoryDialog();
                },
                child: const Text('添加新分类'),
              ),
            ],
          ),
    );
  }

  // 确认删除分类
  void _confirmDeleteCategory(String category) {
    // 检查该分类下是否有计时器
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final hasTimers = timerProvider.hasTimersInCategory(category);

    if (hasTimers) {
      // 如果有计时器，显示警告
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('无法删除分类'),
              content: Text('分类"$category"中还有计时器预设，请先删除该分类中的所有计时器后再尝试删除分类。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
              ],
            ),
      );
    } else {
      // 如果没有计时器，确认是否删除
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('删除分类'),
              content: Text('确定要删除分类"$category"吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 删除分类
                    final timerProvider = Provider.of<TimerProvider>(
                      context,
                      listen: false,
                    );
                    timerProvider.removeCategory(category);

                    // 如果当前选中的是被删除的分类，切换到默认分类
                    if (_category == category) {
                      setState(() {
                        _category = '未分类';
                        _type = TimerPresetType.other;
                      });
                    }
                  },
                  child: const Text('删除'),
                ),
              ],
            ),
      );
    }
  }

  // 显示创建新分类的对话框 - 使用新路由
  void _showCreateCategoryDialog() {
    final currentContext = context; // 保存当前上下文

    // 使用Navigator.push打开一个新的路由
    Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (BuildContext routeContext) {
          return _NewCategoryPage(
            existingCategories:
                Provider.of<TimerProvider>(
                  currentContext,
                  listen: false,
                ).categories,
            onCategoryAdded: (newCategory) {
              // 使用保存的上下文添加分类
              if (mounted) {
                final provider = Provider.of<TimerProvider>(
                  currentContext,
                  listen: false,
                );
                provider.addCategory(newCategory);

                setState(() {
                  _category = newCategory;
                });
              }
            },
          );
        },
      ),
    );
  }

  // 构建持续时间选择器
  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时长标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '时长',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("清零"),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                setState(() {
                  _hours = 0;
                  _minutes = 0;
                  _seconds = 0;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 小时选择
            Expanded(
              child: Column(
                children: [
                  const Text('小时', style: TextStyle(fontSize: 13)),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 28,
                          ),
                          onPressed:
                              _hours > 0
                                  ? () {
                                    setState(() {
                                      _hours--;
                                    });
                                  }
                                  : null,
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 30,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  _hours.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _hours++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 分钟选择
            Expanded(
              child: Column(
                children: [
                  const Text('分钟', style: TextStyle(fontSize: 13)),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 28,
                          ),
                          onPressed:
                              _minutes > 0 || _hours > 0
                                  ? () {
                                    setState(() {
                                      if (_minutes > 0) {
                                        _minutes--;
                                      } else if (_hours > 0) {
                                        _hours--;
                                        _minutes = 59;
                                      }
                                    });
                                  }
                                  : null,
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 30,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  _minutes.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _minutes++;
                              if (_minutes >= 60) {
                                _hours++;
                                _minutes = 0;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 秒钟选择
            Expanded(
              child: Column(
                children: [
                  const Text(
                    '秒',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 28,
                          ),
                          onPressed:
                              _seconds > 0 || _minutes > 0 || _hours > 0
                                  ? () {
                                    setState(() {
                                      if (_seconds > 0) {
                                        _seconds--;
                                      } else if (_minutes > 0) {
                                        _minutes--;
                                        _seconds = 59;
                                      } else if (_hours > 0) {
                                        _hours--;
                                        _minutes = 59;
                                        _seconds = 59;
                                      }
                                    });
                                  }
                                  : null,
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 30,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  _seconds.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _seconds++;
                              if (_seconds >= 60) {
                                _minutes++;
                                _seconds = 0;
                                if (_minutes >= 60) {
                                  _hours++;
                                  _minutes = 0;
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 预设快捷按钮
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.start,
          children: [
            _buildQuickTimeButton('1秒', 0, 0, 1),
            _buildQuickTimeButton('5秒', 0, 0, 5),
            _buildQuickTimeButton('10秒', 0, 0, 10),
            _buildQuickTimeButton('30秒', 0, 0, 30),
            _buildQuickTimeButton('1分', 0, 1, 0),
            _buildQuickTimeButton('5分', 0, 5, 0),
            _buildQuickTimeButton('10分', 0, 10, 0),
            _buildQuickTimeButton('25分', 0, 25, 0),
            _buildQuickTimeButton('30分', 0, 30, 0),
            _buildQuickTimeButton('1时', 1, 0, 0),
          ],
        ),
      ],
    );
  }

  // 构建快速时间选择按钮
  Widget _buildQuickTimeButton(
    String label,
    int hours,
    int minutes,
    int seconds,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        minimumSize: const Size(40, 28),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: () {
        setState(() {
          // 累加时间而不是替换
          _seconds += seconds;
          if (_seconds >= 60) {
            _minutes += _seconds ~/ 60;
            _seconds %= 60;
          }

          _minutes += minutes;
          if (_minutes >= 60) {
            _hours += _minutes ~/ 60;
            _minutes %= 60;
          }

          _hours += hours;
        });
      },
      child: Text("+$label"),
    );
  }

  // 构建类型选择器 (改为隐藏，使用分类自动设置类型)
  Widget _buildTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '类型',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              TimerPresetType.values.map((type) {
                return ChoiceChip(
                  label: Text(_getTypeText(type)),
                  selected: _type == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _type = type;
                      });
                    }
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  // 构建图标选择器
  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '图标',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    // 已选图标显示
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColorByType(_type, context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconCode != null
                            ? IconData(_iconCode!, fontFamily: 'MaterialIcons')
                            : _getIconByType(_type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _iconCode != null ? '已选择自定义图标' : '使用默认图标',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // 重置图标按钮
                    if (_iconCode != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _iconCode = null;
                          });
                        },
                        child: const Text('重置'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 图标列表
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: _commonIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _commonIcons[index];
                    final isSelected = _iconCode == icon.codePoint;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _iconCode = icon.codePoint;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建置顶选项
  Widget _buildPinOption() {
    return Row(
      children: [
        Checkbox(
          value: _isPinned,
          onChanged: (value) {
            setState(() {
              _isPinned = value ?? false;
            });
          },
        ),
        const Text('置顶计时器（将显示在置顶区域）'),
      ],
    );
  }

  // 验证输入并保存
  void _validateAndSave() {
    // 验证名称
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入计时器名称')));
      return;
    }

    // 验证时间
    final totalSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
    if (totalSeconds <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请设置大于0的时间')));
      return;
    }

    // 创建预设对象
    final preset = TimerPresetModel(
      id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      durationSeconds: totalSeconds,
      type: _type,
      isPinned: _isPinned,
      category: _category,
      iconCode: _iconCode,
    );

    // 关闭对话框并返回预设对象
    Navigator.pop(context, preset);
  }

  // 获取类型文本
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

  // 从类别获取预设类型
  TimerPresetType _getPresetTypeFromCategory(String category) {
    switch (category) {
      case '工作':
        return TimerPresetType.work;
      case '学习':
        return TimerPresetType.study;
      case '运动健身':
        return TimerPresetType.exercise;
      case '冥想放松':
        return TimerPresetType.meditation;
      case '生活':
        return TimerPresetType.cooking;
      default:
        return TimerPresetType.other;
    }
  }

  // 从预设类型获取类别
  String _getCategoryFromPresetType(TimerPresetType type) {
    switch (type) {
      case TimerPresetType.work:
        return '工作';
      case TimerPresetType.study:
        return '学习';
      case TimerPresetType.exercise:
        return '运动健身';
      case TimerPresetType.meditation:
        return '冥想放松';
      case TimerPresetType.cooking:
        return '生活';
      case TimerPresetType.other:
        return '未分类';
    }
  }

  // 根据类型获取对应图标
  IconData _getIconByType(TimerPresetType type) {
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
}

// 数字选择器组件
class NumberPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const NumberPicker({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 增加按钮
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            icon: const Icon(Icons.add, size: 18),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
            onPressed: value < maxValue ? () => onChanged(value + 1) : null,
          ),
        ),

        // 数值文本
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 18),
          ),
        ),

        // 减少按钮
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            icon: const Icon(Icons.remove, size: 18),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
            onPressed: value > minValue ? () => onChanged(value - 1) : null,
          ),
        ),
      ],
    );
  }
}

// 创建新分类的页面 - 完全独立的路由
class _NewCategoryPage extends StatefulWidget {
  final List<String> existingCategories;
  final Function(String) onCategoryAdded;

  const _NewCategoryPage({
    required this.existingCategories,
    required this.onCategoryAdded,
  });

  @override
  _NewCategoryPageState createState() => _NewCategoryPageState();
}

class _NewCategoryPageState extends State<_NewCategoryPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建分类')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '分类名称',
                hintText: '请输入分类名称',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = _controller.text.trim();

                    // 验证
                    if (name.isEmpty) {
                      setState(() {
                        _errorText = '分类名称不能为空';
                      });
                      return;
                    }

                    if (widget.existingCategories.contains(name)) {
                      setState(() {
                        _errorText = '该分类已存在';
                      });
                      return;
                    }

                    // 调用回调并关闭页面
                    widget.onCategoryAdded(name);
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
