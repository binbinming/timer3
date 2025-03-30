import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/timer_provider.dart';
import '../providers/theme_provider.dart';
import '../models/timer_model.dart';
import '../models/timer_preset_model.dart';
import '../models/timer_group_model.dart';
import '../widgets/timer_preset_card.dart';
import '../widgets/timer_group_card.dart';
import '../widgets/add_timer_dialog.dart';
import '../widgets/add_timer_group_dialog.dart';
import 'package:timer/screens/home_screen.dart';
import 'package:flutter/services.dart';

// 添加全局变量来跟踪计时器屏幕是否是新打开的
bool _isNewTimerScreen = true;

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();

  // 静态方法，可以在任何地方调用
  static void showAddTimerDialog(
    BuildContext context,
    TimerProvider timerProvider, {
    TimerModel? preset,
  }) {
    // 创建一个临时的状态对象来调用私有方法
    final state = _TimerScreenState();
    state._showTimerDialog(context, timerProvider, preset: preset);
  }

  // 静态方法，可以在任何地方调用 - 用于添加或编辑计时器组
  static void showAddTimerGroupDialog(
    BuildContext context,
    TimerProvider timerProvider, {
    TimerGroupModel? group,
  }) {
    // 创建一个临时的状态对象来调用私有方法
    final state = _TimerScreenState();
    state._showTimerGroupDialog(context, timerProvider, group: group);
  }

  // 新增静态方法，处理从其他地方调用的返回操作
  static void handleGoBack(BuildContext context) {
    // 创建一个临时的状态对象来调用私有方法
    final state = _TimerScreenState();
    state._handleGoBack(context);
  }
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  List<String> _reorderableCategories = [];
  bool _isReordering = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      _reorderableCategories = timerProvider.sortableCategories;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final presetsByCategory = timerProvider.presetsByCategory;

    // 更新可排序分类列表
    if (!_isReordering) {
      _reorderableCategories = timerProvider.sortableCategories;
    }

    // 如果有正在运行的计时器组，显示计时器组运行界面
    if (timerProvider.currentGroup != null) {
      return _buildRunningTimerGroup(context, timerProvider);
    }

    // 如果有正在运行的普通计时器，显示计时器界面
    if (timerProvider.status != TimerStatus.idle) {
      return _buildRunningTimer(context, timerProvider);
    }

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.timer), text: '计时器'),
              Tab(icon: Icon(Icons.playlist_play), text: '计时器组'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 单个计时器标签页
                _buildTimersTabContent(timerProvider, presetsByCategory),

                // 计时器组标签页
                _buildTimerGroupsTab(timerProvider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 根据当前标签页决定显示哪种对话框
          if (_tabController.index == 0) {
            _showAddTimerDialog(context, timerProvider);
          } else {
            _showTimerGroupDialog(context, timerProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建计时器标签页
  Widget _buildTimersTabContent(
    TimerProvider timerProvider,
    Map<String, List<dynamic>> mixedPresets,
  ) {
    // 过滤出TimerModel类型的预设
    final presetsByCategory = _filterTimerModels(mixedPresets);

    // 过滤出要显示的分类(有内容的分类)
    final categoriesToShow = <String>[];
    for (final category in _reorderableCategories) {
      if (presetsByCategory[category]?.isNotEmpty ?? false) {
        categoriesToShow.add(category);
      }
    }
    // 添加未分类(如果有内容)
    if (presetsByCategory['未分类']?.isNotEmpty ?? false) {
      categoriesToShow.add('未分类');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 置顶区域 - 始终显示标题
          _buildPinnedSection(context, presetsByCategory, timerProvider),

          // 使用ReorderableListView显示所有分类
          if (categoriesToShow.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                // 只在排序模式下允许拖动
                if (!_isReordering) return;

                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }

                  final item = categoriesToShow.removeAt(oldIndex);
                  categoriesToShow.insert(newIndex, item);

                  // 更新可排序分类的顺序
                  // 注意：未分类不应该被加入排序列表
                  final newOrder = <String>[];
                  for (final category in categoriesToShow) {
                    if (category != '未分类') {
                      newOrder.add(category);
                    }
                  }

                  // 确保包含所有原始分类(即使没有内容的分类)
                  for (final category in _reorderableCategories) {
                    if (!newOrder.contains(category)) {
                      newOrder.add(category);
                    }
                  }

                  _reorderableCategories = newOrder;
                });
              },
              itemCount: categoriesToShow.length,
              itemBuilder: (context, index) {
                final category = categoriesToShow[index];

                return _buildSectionWithReordering(
                  context,
                  category,
                  presetsByCategory[category]!,
                  timerProvider,
                  key: ValueKey(category),
                );
              },
            ),
        ],
      ),
    );
  }

  // 构建计时器组标签页
  Widget _buildTimerGroupsTab(TimerProvider timerProvider) {
    final groupsByCategory = timerProvider.groupsByCategory;

    // 过滤出要显示的分类(有内容的分类)
    final categoriesToShow = <String>[];
    for (final category in _reorderableCategories) {
      if (groupsByCategory[category]?.isNotEmpty ?? false) {
        categoriesToShow.add(category);
      }
    }
    // 添加未分类(如果有内容)
    if (groupsByCategory['未分类']?.isNotEmpty ?? false) {
      categoriesToShow.add('未分类');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 置顶计时器组 - 始终显示
          _buildPinnedGroupSection(context, groupsByCategory, timerProvider),

          // 使用ReorderableListView显示所有分类
          if (categoriesToShow.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                // 只在排序模式下允许拖动
                if (!_isReordering) return;

                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }

                  final item = categoriesToShow.removeAt(oldIndex);
                  categoriesToShow.insert(newIndex, item);

                  // 更新可排序分类的顺序
                  // 注意：未分类不应该被加入排序列表
                  final newOrder = <String>[];
                  for (final category in categoriesToShow) {
                    if (category != '未分类') {
                      newOrder.add(category);
                    }
                  }

                  // 确保包含所有原始分类(即使没有内容的分类)
                  for (final category in _reorderableCategories) {
                    if (!newOrder.contains(category)) {
                      newOrder.add(category);
                    }
                  }

                  _reorderableCategories = newOrder;
                });
              },
              itemCount: categoriesToShow.length,
              itemBuilder: (context, index) {
                final category = categoriesToShow[index];

                return _buildGroupSectionWithReordering(
                  context,
                  category,
                  groupsByCategory[category]!,
                  timerProvider,
                  key: ValueKey(category),
                );
              },
            ),

          // 如果没有计时器组，显示提示信息
          if (timerProvider.groups.isEmpty && categoriesToShow.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_add,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '点击右下角的"+"按钮创建计时器组',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建计时器组区域
  Widget _buildGroupSection(
    BuildContext context,
    String title,
    List<TimerGroupModel> groups,
    TimerProvider timerProvider, {
    bool isPinned = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: isPinned ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return TimerGroupCard(
              group: group,
              onTap: () {
                // 使用WidgetsBinding.instance.addPostFrameCallback确保先完成当前构建
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  timerProvider.loadTimerGroup(group);
                });
              },
              onEdit: () {
                _showTimerGroupDialog(context, timerProvider, group: group);
              },
              onDelete: () {
                _showDeleteGroupDialog(context, timerProvider, group);
              },
              onTogglePin: () {
                timerProvider.togglePinGroup(group.id);
              },
              isPinned: group.isPinned,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 确保弹出对话框都会更新全局对话框状态
  void _showAlertDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    // 设置对话框状态
    setGlobalDialogState(true);

    // 显示对话框
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: Text(
                  '删除',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    ).then((_) {
      // 对话框关闭后重置状态
      setGlobalDialogState(false);
    });
  }

  // 显示删除计时器组确认对话框
  void _showDeleteGroupDialog(
    BuildContext context,
    TimerProvider timerProvider,
    TimerGroupModel group,
  ) {
    _showAlertDialog(
      context,
      '删除确认',
      '确定要删除"${group.name}"计时器组吗？',
      () => timerProvider.deleteGroup(group.id),
    );
  }

  // 构建分类排序控制组件
  Widget _buildCategoryReorderControls(
    BuildContext context,
    TimerProvider timerProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  _isReordering ? Icons.check : Icons.reorder,
                  size: 24,
                ),
                tooltip: _isReordering ? '保存顺序' : '调整顺序',
                onPressed: () {
                  if (_isReordering) {
                    // 保存排序
                    timerProvider.updateCategoryOrder(_reorderableCategories);
                  }
                  setState(() {
                    _isReordering = !_isReordering;
                  });
                },
              ),
            ],
          ),
        ),

        // 显示拖拽排序列表
        if (_isReordering)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _reorderableCategories.removeAt(oldIndex);
                  _reorderableCategories.insert(newIndex, item);
                });
              },
              children:
                  _reorderableCategories.map((category) {
                    return ListTile(
                      key: ValueKey(category),
                      title: Text(category),
                      leading: const Icon(Icons.drag_handle),
                      dense: true,
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<TimerModel> presets,
    TimerProvider timerProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4列
            childAspectRatio: 0.8, // 修改为矩形而不是正方形，增加高度
            crossAxisSpacing: 3, // 减小横向间距
            mainAxisSpacing: 3, // 减小纵向间距
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];

            // 将 TimerModel 转换为 TimerPresetModel
            final presetModel = TimerPresetModel(
              id: preset.id.toString(),
              name: preset.name,
              durationSeconds: preset.totalSeconds,
              type: _getPresetTypeFromCategory(preset.category),
              isPinned: preset.isPinned,
              category: preset.category,
              iconCode: preset.iconCode,
            );

            return TimerPresetCard(
              preset: presetModel,
              onTap: () {
                // 使用WidgetsBinding.instance.addPostFrameCallback确保先完成当前构建
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (preset is IntervalTimerModel) {
                    timerProvider.loadIntervalTimer(preset);
                  } else {
                    timerProvider.loadTimer(preset);
                  }
                });
              },
              onEdit: () {
                _showAddTimerDialog(context, timerProvider, preset: preset);
              },
              onDelete: () {
                // 弹出确认对话框
                _showAlertDialog(
                  context,
                  '删除确认',
                  '确定要删除"${preset.name}"计时器吗？',
                  () => timerProvider.deletePreset(preset.id),
                );
              },
              isPinned: preset.isPinned,
              onTogglePin: () {
                timerProvider.togglePinPreset(preset.id);
              },
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 构建置顶区域
  Widget _buildPinnedSection(
    BuildContext context,
    Map<String, List<TimerModel>> presetsByCategory,
    TimerProvider timerProvider,
  ) {
    // 获取置顶预设
    final pinnedPresets = presetsByCategory['置顶'] ?? [];

    // 调试输出
    print('构建置顶区域:');
    print(
      '  - presetsByCategory 中是否有"置顶"键: ${presetsByCategory.containsKey('置顶')}',
    );
    print('  - 置顶预设数量: ${pinnedPresets.length}');

    // 检查所有预设
    final allPresets = timerProvider.presets;
    final allPinnedPresets = allPresets.where((p) => p.isPinned).toList();
    print('  - 所有预设中置顶的数量: ${allPinnedPresets.length}');
    for (var preset in allPinnedPresets) {
      print(
        '    * ${preset.name} (${preset.id}), isPinned=${preset.isPinned}, category=${preset.category}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '置顶计时器',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isReordering ? Icons.check : Icons.reorder,
                  size: 24,
                ),
                tooltip: _isReordering ? '保存顺序' : '调整顺序',
                onPressed: () {
                  if (_isReordering) {
                    // 保存排序
                    timerProvider.updateCategoryOrder(_reorderableCategories);
                  }
                  setState(() {
                    _isReordering = !_isReordering;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (pinnedPresets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Center(
              child: Text(
                '暂无置顶计时器',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // 改为4列
              childAspectRatio: 1.0, // 设置为正方形
              crossAxisSpacing: 3, // 减小横向间距
              mainAxisSpacing: 3, // 减小纵向间距
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: pinnedPresets.length,
            itemBuilder: (context, index) {
              final preset = pinnedPresets[index];

              // 将 TimerModel 转换为 TimerPresetModel
              final presetModel = TimerPresetModel(
                id: preset.id.toString(),
                name: preset.name,
                durationSeconds: preset.totalSeconds,
                type: _getPresetTypeFromCategory(preset.category),
                isPinned: preset.isPinned,
                category: preset.category,
                iconCode: preset.iconCode,
              );

              return TimerPresetCard(
                preset: presetModel,
                onTap: () {
                  // 使用WidgetsBinding.instance.addPostFrameCallback确保先完成当前构建
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (preset is IntervalTimerModel) {
                      timerProvider.loadIntervalTimer(preset);
                    } else {
                      timerProvider.loadTimer(preset);
                    }
                  });
                },
                onEdit: () {
                  _showAddTimerDialog(context, timerProvider, preset: preset);
                },
                onDelete: () {
                  // 弹出确认对话框
                  _showAlertDialog(
                    context,
                    '删除确认',
                    '确定要删除"${preset.name}"计时器吗？',
                    () => timerProvider.deletePreset(preset.id),
                  );
                },
                isPinned: preset.isPinned,
                onTogglePin: () {
                  timerProvider.togglePinPreset(preset.id);
                },
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  // 构建置顶计时器组区域
  Widget _buildPinnedGroupSection(
    BuildContext context,
    Map<String, List<TimerGroupModel>> groupsByCategory,
    TimerProvider timerProvider,
  ) {
    // 获取置顶预设组
    final pinnedGroups = groupsByCategory['置顶'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '置顶计时器组',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isReordering ? Icons.check : Icons.reorder,
                  size: 24,
                ),
                tooltip: _isReordering ? '保存顺序' : '调整顺序',
                onPressed: () {
                  if (_isReordering) {
                    // 保存排序
                    timerProvider.updateCategoryOrder(_reorderableCategories);
                  }
                  setState(() {
                    _isReordering = !_isReordering;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (pinnedGroups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Center(
              child: Text(
                '暂无置顶计时器组',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: pinnedGroups.length,
            itemBuilder: (context, index) {
              final group = pinnedGroups[index];
              return TimerGroupCard(
                group: group,
                onTap: () {
                  // 使用WidgetsBinding.instance.addPostFrameCallback确保先完成当前构建
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    timerProvider.loadTimerGroup(group);
                  });
                },
                onEdit: () {
                  _showTimerGroupDialog(context, timerProvider, group: group);
                },
                onDelete: () {
                  _showDeleteGroupDialog(context, timerProvider, group);
                },
                onTogglePin: () {
                  timerProvider.togglePinGroup(group.id);
                },
                isPinned: group.isPinned,
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  // 构建可重排序的计时器组分类区域
  Widget _buildGroupSectionWithReordering(
    BuildContext context,
    String title,
    List<TimerGroupModel> groups,
    TimerProvider timerProvider, {
    required Key key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              // 排序模式下显示拖动图标
              if (_isReordering)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return TimerGroupCard(
              group: group,
              onTap: () {
                // 使用WidgetsBinding.instance.addPostFrameCallback确保先完成当前构建
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  timerProvider.loadTimerGroup(group);
                });
              },
              onEdit: () {
                _showTimerGroupDialog(context, timerProvider, group: group);
              },
              onDelete: () {
                _showDeleteGroupDialog(context, timerProvider, group);
              },
              onTogglePin: () {
                timerProvider.togglePinGroup(group.id);
              },
              isPinned: group.isPinned,
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
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

  Widget _buildRunningTimer(BuildContext context, TimerProvider timerProvider) {
    final currentTimer = timerProvider.currentTimer;
    if (currentTimer == null) return const SizedBox();

    // 使用addPostFrameCallback确保在构建完成后才设置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 通知HomeScreen计时器正在运行，禁用滑动
      HomeScreen.setTimerRunningState(context, true);
    });

    final minutes = timerProvider.secondsRemaining ~/ 60;
    final seconds = timerProvider.secondsRemaining % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final bool isInitialState =
        timerProvider.status == TimerStatus.paused &&
        timerProvider.progress == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTimer.name),
        automaticallyImplyLeading: false, // 不自动添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 恢复滑动功能
            HomeScreen.setTimerRunningState(context, false);
            // 重置计时器状态
            timerProvider.resetTimer();
            // 回到主屏幕
            _handleGoBack(context);
          },
          tooltip: '返回',
        ),
        actions: [
          // 添加横屏按钮
          IconButton(
            icon: const Icon(Icons.screen_rotation),
            onPressed: () {
              _enterLandscapeMode(context, timerProvider, isGroupTimer: false);
            },
            tooltip: '横屏模式',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 120,
                lineWidth: 15,
                percent: timerProvider.progress,
                center: Text(
                  timeString,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                progressColor: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animateFromLastPercent: true,
              ),

              // 替换条件渲染为AnimatedOpacity，保持固定高度
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isInitialState ? 1.0 : 0.0,
                  child: SizedBox(
                    height: 24, // 固定高度，保持布局稳定
                    child: Text(
                      '点击开始按钮启动计时',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 重置按钮 - 只重置当前计时器而不退出界面
                  FloatingActionButton(
                    heroTag: 'reset',
                    onPressed: () {
                      timerProvider.resetTimerOnly();
                    },
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    tooltip: '重置计时',
                    child: const Icon(Icons.refresh),
                  ),

                  // 开始/暂停按钮
                  FloatingActionButton.large(
                    heroTag: 'startPause',
                    onPressed: () {
                      if (timerProvider.status == TimerStatus.running) {
                        timerProvider.pauseTimer();
                      } else {
                        timerProvider.resumeTimer();
                      }
                    },
                    child: Icon(
                      timerProvider.status == TimerStatus.running
                          ? Icons.pause
                          : Icons.play_arrow,
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

  // 构建运行中的计时器组界面
  Widget _buildRunningTimerGroup(
    BuildContext context,
    TimerProvider timerProvider,
  ) {
    final currentGroup = timerProvider.currentGroup!;
    final currentTimerIndex = timerProvider.currentTimerIndex;
    final currentTimer = timerProvider.currentTimer;

    if (currentTimer == null) return const SizedBox();

    // 使用addPostFrameCallback确保在构建完成后才设置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 通知HomeScreen计时器组正在运行，禁用滑动
      HomeScreen.setTimerRunningState(context, true);
    });

    final minutes = timerProvider.secondsRemaining ~/ 60;
    final seconds = timerProvider.secondsRemaining % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // 计算总进度
    final totalTimers = currentGroup.timers.length;
    final currentProgress =
        (currentTimerIndex / totalTimers) +
        (timerProvider.progress / totalTimers);

    final bool isInitialState =
        timerProvider.status == TimerStatus.paused &&
        timerProvider.progress == 0 &&
        currentTimerIndex == 0;

    // 计算组的总时间
    int totalGroupSeconds = 0;
    for (var timer in currentGroup.timers) {
      totalGroupSeconds += timer.totalSeconds;
    }

    // 计算已完成的时间
    int completedSeconds = 0;
    for (int i = 0; i < currentTimerIndex; i++) {
      completedSeconds += currentGroup.timers[i].totalSeconds;
    }
    completedSeconds +=
        (timerProvider.totalSeconds - timerProvider.secondsRemaining);

    // 格式化总时间和剩余时间
    final totalTimeFormatted = _formatDuration(totalGroupSeconds);
    final completedTimeFormatted = _formatDuration(completedSeconds);
    final remainingTimeFormatted = _formatDuration(
      totalGroupSeconds - completedSeconds,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGroup.name),
        automaticallyImplyLeading: false, // 不自动添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 恢复滑动功能
            HomeScreen.setTimerRunningState(context, false);
            // 重置计时器组状态
            timerProvider.resetTimerGroup();
            // 回到主屏幕
            _handleGoBack(context);
          },
          tooltip: '返回',
        ),
        actions: [
          // 添加横屏按钮
          IconButton(
            icon: const Icon(Icons.screen_rotation),
            onPressed: () {
              _enterLandscapeMode(context, timerProvider, isGroupTimer: true);
            },
            tooltip: '横屏模式',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false, // 允许内容延伸到底部安全区以解决溢出问题
        child: Column(
          children: [
            // 计时器信息和控制部分
            Expanded(
              flex: 5, // 较大比例给上部分
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 显示当前计时器信息
                    Text(
                      '${currentTimerIndex + 1}/$totalTimers: ${currentTimer.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),

                    // 显示组整体时间信息
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '总时长: $totalTimeFormatted',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '剩余: $remainingTimeFormatted',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // 减少间距
                    // 圆形进度指示器
                    CircularPercentIndicator(
                      radius: 80, // 减小半径
                      lineWidth: 10, // 减小线宽
                      percent: timerProvider.progress,
                      center: Text(
                        timeString,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      progressColor: Theme.of(context).colorScheme.primary,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                      animateFromLastPercent: true,
                    ),

                    // 始终保留此区域，但在不同状态显示不同文本
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isInitialState ? 1.0 : 0.0,
                        child: SizedBox(
                          height: 16, // 固定高度，保持布局稳定
                          child: Text(
                            isInitialState ? '点击开始按钮启动计时器组' : '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4), // 减少间距
                    // 总进度条
                    LinearProgressIndicator(
                      value: currentProgress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '总进度: ${(currentProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4), // 减少间距
                    // 控制按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 重置按钮 - 重置当前阶段而不退出
                        FloatingActionButton.small(
                          heroTag: 'reset',
                          onPressed: () {
                            timerProvider.resetCurrentTimerInGroup();
                          },
                          backgroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          tooltip: '重置当前阶段',
                          child: const Icon(Icons.refresh, size: 18),
                        ),

                        // 开始/暂停按钮
                        FloatingActionButton(
                          heroTag: 'startPause',
                          onPressed: () {
                            if (timerProvider.status == TimerStatus.running) {
                              timerProvider.pauseTimer();
                            } else {
                              timerProvider.resumeTimer();
                            }
                          },
                          child: Icon(
                            timerProvider.status == TimerStatus.running
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 计时器列表部分
            Expanded(
              flex: 3, // 增加下部区域的比例
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 2),
                      child: Text(
                        '计时器列表',
                        style: TextStyle(
                          fontSize: 16, // 增大字体
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const Divider(height: 4), // 减少分隔线高度
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 4),
                        itemCount: currentGroup.timers.length,
                        itemBuilder: (context, index) {
                          final timer = currentGroup.timers[index];
                          final isCurrentTimer = index == currentTimerIndex;

                          return ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(
                              horizontal: 0,
                              vertical: -2, // 减少垂直压缩
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2, // 增加垂直内边距
                            ),
                            title: Text(
                              timer.name,
                              style: TextStyle(
                                fontSize: 15, // 增大字体
                                fontWeight:
                                    isCurrentTimer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isCurrentTimer
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                              ),
                            ),
                            subtitle: Text(
                              '${timer.minutes}分${timer.seconds > 0 ? ' ${timer.seconds}秒' : ''}',
                              style: TextStyle(
                                fontSize: 13, // 增大字体
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            leading: CircleAvatar(
                              radius: 12, // 增大头像尺寸
                              backgroundColor:
                                  isCurrentTimer
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh,
                              foregroundColor:
                                  isCurrentTimer
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 10), // 增大字体
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                index < currentTimerIndex
                                    ? Icons.replay_circle_filled
                                    : (isCurrentTimer
                                        ? Icons.play_circle_filled
                                        : Icons.play_circle_outline),
                                size: 20, // 增大图标尺寸
                                color:
                                    isCurrentTimer
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                              ),
                              onPressed:
                                  isCurrentTimer
                                      ? null
                                      : () {
                                        timerProvider.setCurrentTimerInGroup(
                                          index,
                                        );
                                      },
                              tooltip:
                                  index <= currentTimerIndex ? '重新开始' : '从这里开始',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                            selected: isCurrentTimer,
                            minVerticalPadding: 2, // 增加最小垂直内边距
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  // 改名为 _showTimerDialog，以便与静态方法区分
  void _showTimerDialog(
    BuildContext context,
    TimerProvider timerProvider, {
    TimerModel? preset,
  }) {
    // 从 TimerModel 转换为 TimerPresetModel
    TimerPresetModel? presetModel;

    if (preset != null) {
      print('编辑预设: ${preset.name}, isPinned=${preset.isPinned}');
      presetModel = TimerPresetModel(
        id: preset.id.toString(),
        name: preset.name,
        durationSeconds: preset.totalSeconds,
        type: _getPresetTypeFromCategory(preset.category),
        isPinned: preset.isPinned,
        category: preset.category,
        iconCode: preset.iconCode,
      );
    }

    // 告诉HomeScreen对话框已打开
    HomeScreen.setDialogState(context, true);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddTimerDialog(preset: presetModel),
    ).then((result) {
      // 告诉HomeScreen对话框已关闭
      HomeScreen.setDialogState(context, false);

      if (result != null && result is TimerPresetModel) {
        print(
          '保存预设: ${result.name}, isPinned=${result.isPinned}, category=${result.category}',
        );
        // 从 TimerPresetModel 转换为 TimerModel
        final newTimerModel = TimerModel(
          id: int.tryParse(result.id) ?? 0,
          name: result.name,
          minutes: (result.durationSeconds / 60).toDouble(),
          seconds: result.durationSeconds % 60,
          category: result.category, // 使用用户在对话框中选择的分类
          isPinned: result.isPinned,
          iconCode: result.iconCode,
        );

        print(
          '转换后的 TimerModel: id=${newTimerModel.id}, name=${newTimerModel.name}, isPinned=${newTimerModel.isPinned}, category=${newTimerModel.category}',
        );

        if (preset == null) {
          print('添加新预设');
          timerProvider.addPreset(newTimerModel);
        } else {
          print('更新预设 (id=${preset.id})');
          timerProvider.updatePreset(newTimerModel);
        }
      }
    });
  }

  // 显示添加/编辑计时器组对话框
  void _showTimerGroupDialog(
    BuildContext context,
    TimerProvider timerProvider, {
    TimerGroupModel? group,
  }) {
    // 告诉HomeScreen对话框已打开
    HomeScreen.setDialogState(context, true);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddTimerGroupDialog(group: group),
    ).then((result) {
      // 告诉HomeScreen对话框已关闭
      HomeScreen.setDialogState(context, false);

      if (result != null && result is TimerGroupModel) {
        if (group == null) {
          // 添加新的计时器组
          timerProvider.addGroup(result);
        } else {
          // 更新现有的计时器组
          timerProvider.updateGroup(result);
        }
      }
    });
  }

  // 保留原方法名，调用新方法
  void _showAddTimerDialog(
    BuildContext context,
    TimerProvider timerProvider, {
    TimerModel? preset,
  }) {
    _showTimerDialog(context, timerProvider, preset: preset);
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

  // 修复类型问题，创建一个包装方法来处理不同类型的Map
  Map<String, List<TimerModel>> _filterTimerModels(
    Map<String, List<dynamic>> mixedMap,
  ) {
    final result = <String, List<TimerModel>>{};
    for (final entry in mixedMap.entries) {
      final List<TimerModel> timerModels =
          entry.value.whereType<TimerModel>().toList();
      if (timerModels.isNotEmpty) {
        result[entry.key] = timerModels;
      }
    }
    return result;
  }

  // 构建可重排序的分类区域
  Widget _buildSectionWithReordering(
    BuildContext context,
    String title,
    List<TimerModel> presets,
    TimerProvider timerProvider, {
    required Key key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              // 排序模式下显示拖动图标
              if (_isReordering)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4列
            childAspectRatio: 0.8, // 修改为矩形而不是正方形，增加高度
            crossAxisSpacing: 3, // 减小横向间距
            mainAxisSpacing: 3, // 减小纵向间距
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];

            // 将 TimerModel 转换为 TimerPresetModel
            final presetModel = TimerPresetModel(
              id: preset.id.toString(),
              name: preset.name,
              durationSeconds: preset.totalSeconds,
              type: _getPresetTypeFromCategory(preset.category),
              isPinned: preset.isPinned,
              category: preset.category,
              iconCode: preset.iconCode,
            );

            return TimerPresetCard(
              preset: presetModel,
              onTap: () {
                // 使用WidgetsBinding.instance.addPostFrameCallback确保先完成当前构建
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (preset is IntervalTimerModel) {
                    timerProvider.loadIntervalTimer(preset);
                  } else {
                    timerProvider.loadTimer(preset);
                  }
                });
              },
              onEdit: () {
                _showAddTimerDialog(context, timerProvider, preset: preset);
              },
              onDelete: () {
                // 弹出确认对话框
                _showAlertDialog(
                  context,
                  '删除确认',
                  '确定要删除"${preset.name}"计时器吗？',
                  () => timerProvider.deletePreset(preset.id),
                );
              },
              isPinned: preset.isPinned,
              onTogglePin: () {
                timerProvider.togglePinPreset(preset.id);
              },
            );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // 进入横屏模式
  void _enterLandscapeMode(
    BuildContext context,
    TimerProvider timerProvider, {
    required bool isGroupTimer,
  }) {
    // 设置横屏方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 导航到横屏计时器页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => LandscapeTimerScreen(
              timerProvider: timerProvider,
              isGroupTimer: isGroupTimer,
              onExit: () {
                // 返回时恢复竖屏
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
                Navigator.of(context).pop();
              },
            ),
      ),
    );
  }

  // 最小化应用方法
  void minimizeApp() {
    SystemNavigator.pop();
  }

  // 新增加的返回处理方法
  void _handleGoBack(BuildContext context) {
    // 记录计时器状态
    print('处理返回操作');

    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    // 重置计时器状态
    if (timerProvider.currentGroup != null) {
      timerProvider.resetTimerGroup();
    } else if (timerProvider.currentTimer != null) {
      timerProvider.resetTimer();
    }

    // 设置计时器不再运行
    setGlobalTimerRunningState(false);

    // 返回到首页
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// 横屏计时器界面
class LandscapeTimerScreen extends StatelessWidget {
  final TimerProvider timerProvider;
  final bool isGroupTimer;
  final VoidCallback onExit;

  const LandscapeTimerScreen({
    super.key,
    required this.timerProvider,
    required this.isGroupTimer,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onExit();
        return false;
      },
      child: Consumer<TimerProvider>(
        builder: (context, timerProvider, _) {
          final currentTimer = timerProvider.currentTimer;
          if (currentTimer == null) return const SizedBox();

          final minutes = timerProvider.secondsRemaining ~/ 60;
          final seconds = timerProvider.secondsRemaining % 60;
          final timeString =
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

          String timerName = currentTimer.name;
          String timerProgress = '';

          if (isGroupTimer && timerProvider.currentGroup != null) {
            final currentGroup = timerProvider.currentGroup!;
            final currentTimerIndex = timerProvider.currentTimerIndex;
            final totalTimers = currentGroup.timers.length;
            timerName = '${currentTimerIndex + 1}/$totalTimers: $timerName';
            final currentProgress = (currentTimerIndex / totalTimers) + (timerProvider.progress / totalTimers);
            timerProgress = '总进度: ${(currentProgress * 100).toStringAsFixed(0)}%';
          }

          final screenSize = MediaQuery.of(context).size;
          final maxWidth = screenSize.width;
          final maxHeight = screenSize.height;
          
          // 根据屏幕尺寸动态计算字体大小
          final timeDigitSize = maxHeight * 0.6; // 将字体大小与屏幕高度关联

          return Scaffold(
            backgroundColor: Colors.black,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // 中央计时数字
                    Positioned.fill(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.1),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    fontSize: timeDigitSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black.withOpacity(0.3),
                                    height: 0.8,
                                  ),
                                ),
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    fontSize: timeDigitSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 底部进度条
                    Positioned(
                      bottom: maxHeight * 0.1,
                      left: maxWidth * 0.1,
                      right: maxWidth * 0.1,
                      child: LinearProgressIndicator(
                        value: timerProvider.progress,
                        minHeight: maxHeight * 0.02,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        ),
                        borderRadius: BorderRadius.circular(maxHeight * 0.01),
                      ),
                    ),

                    // 左侧信息
                    Positioned(
                      top: maxHeight * 0.1,
                      left: maxWidth * 0.05,
                      child: Container(
                        padding: EdgeInsets.all(maxHeight * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(maxHeight * 0.02),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timerName,
                              style: TextStyle(
                                fontSize: maxHeight * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 5,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                            if (timerProgress.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: maxHeight * 0.01),
                                child: Text(
                                  timerProgress,
                                  style: TextStyle(
                                    fontSize: maxHeight * 0.03,
                                    color: Colors.white.withOpacity(0.8),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 5,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 右侧控制按钮
                    Positioned(
                      top: maxHeight * 0.3,
                      right: maxWidth * 0.03, // 将按钮向左移动，使其与时间显示中心对齐
                      child: Container(
                        padding: EdgeInsets.all(maxHeight * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(maxHeight * 0.02),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: maxHeight * 0.08,
                              height: maxHeight * 0.08,
                              child: FloatingActionButton(
                                heroTag: 'landscapeStartPause',
                                onPressed: () {
                                  if (timerProvider.status == TimerStatus.running) {
                                    timerProvider.pauseTimer();
                                  } else {
                                    timerProvider.resumeTimer();
                                  }
                                },
                                backgroundColor: Colors.white.withOpacity(0.8),
                                child: Icon(
                                  timerProvider.status == TimerStatus.running
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: maxHeight * 0.05,
                                ),
                              ),
                            ),
                            SizedBox(height: maxHeight * 0.02),
                            SizedBox(
                              width: maxHeight * 0.08,
                              height: maxHeight * 0.08,
                              child: FloatingActionButton(
                                heroTag: 'landscapeReset',
                                onPressed: () {
                                  if (isGroupTimer) {
                                    timerProvider.resetCurrentTimerInGroup();
                                  } else {
                                    timerProvider.resetTimerOnly();
                                  }
                                },
                                backgroundColor: Colors.white.withOpacity(0.6),
                                child: Icon(
                                  Icons.refresh,
                                  size: maxHeight * 0.05,
                                ),
                              ),
                            ),
                            SizedBox(height: maxHeight * 0.02),
                            SizedBox(
                              width: maxHeight * 0.08,
                              height: maxHeight * 0.08,
                              child: FloatingActionButton(
                                heroTag: 'landscapeExit',
                                onPressed: onExit,
                                backgroundColor: Colors.white.withOpacity(0.4),
                                child: Icon(
                                  Icons.screen_rotation,
                                  size: maxHeight * 0.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
