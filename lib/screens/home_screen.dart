import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import 'timer_screen.dart';
import 'alarm_screen.dart';
import 'stopwatch_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

// 全局key，用于获取HomeScreen状态
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

// 全局变量，用于跟踪对话框状态
bool isDialogOpenGlobal = false;

// 全局变量，用于跟踪计时器运行状态
bool isTimerRunningGlobal = false;

// 全局方法设置对话框状态
void setGlobalDialogState(bool isOpen) {
  isDialogOpenGlobal = isOpen;
  print('全局对话框状态设置为: $isDialogOpenGlobal');

  // 尝试更新HomeScreen状态
  if (homeScreenKey.currentState != null) {
    homeScreenKey.currentState!.setDialogOpen(isOpen);
  }
}

// 全局方法设置计时器运行状态
void setGlobalTimerRunningState(bool isRunning) {
  isTimerRunningGlobal = isRunning;
  print('全局计时器运行状态设置为: $isTimerRunningGlobal');

  // 尝试更新HomeScreen状态
  if (homeScreenKey.currentState != null) {
    homeScreenKey.currentState!.setTimerRunning(isRunning);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  // 静态方法用于获取HomeScreen的状态并设置对话框
  static void setDialogState(BuildContext context, bool isOpen) {
    // 设置全局状态变量
    setGlobalDialogState(isOpen);

    // 尝试通过key直接更新状态
    if (homeScreenKey.currentState != null) {
      homeScreenKey.currentState!.setDialogOpen(isOpen);
      return;
    }

    // 获取最外层导航器的context
    final navigatorContext = Navigator.of(context).context;
    // 尝试查找HomeScreen的State
    final _HomeScreenState? state =
        navigatorContext.findAncestorStateOfType<_HomeScreenState>();

    if (state != null) {
      state.setDialogOpen(isOpen);
    } else {
      print('Flutter: 无法找到HomeScreen状态');
    }
  }

  // 静态方法用于设置计时器运行状态
  static void setTimerRunningState(BuildContext context, bool isRunning) {
    // 设置全局状态变量
    setGlobalTimerRunningState(isRunning);

    // 尝试通过key直接更新状态
    if (homeScreenKey.currentState != null) {
      homeScreenKey.currentState!.setTimerRunning(isRunning);
      return;
    }

    // 获取最外层导航器的context
    final navigatorContext = Navigator.of(context).context;
    // 尝试查找HomeScreen的State
    final _HomeScreenState? state =
        navigatorContext.findAncestorStateOfType<_HomeScreenState>();

    if (state != null) {
      state.setTimerRunning(isRunning);
    } else {
      print('Flutter: 无法找到HomeScreen状态');
    }
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.timer/app');
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;
  bool _isDialogOpen = false;
  bool _isTimerRunning = false;

  final List<Widget> _screens = [
    const TimerScreen(),
    const AlarmScreen(),
    const StopwatchScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = ['计时器', '闹钟', '秒表', '设置'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 设置方法通道来接收返回键消息
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onBackPressed') {
        // 收到原生层的返回键事件
        print('Flutter: 收到原生层返回键事件，当前计时器运行状态: $_isTimerRunning');

        // 优先顺序：对话框 > 计时器运行 > 计时器暂停 > 默认返回

        // 检查对话框状态
        if (_isDialogOpen || isDialogOpenGlobal) {
          print('Flutter: 对话框开启中，弹出当前对话框');
          // 弹出当前对话框
          Navigator.of(context).pop();
          return true;
        }

        // 检查计时器运行状态
        if (_isTimerRunning || isTimerRunningGlobal) {
          final timerProvider = Provider.of<TimerProvider>(
            context,
            listen: false,
          );

          if (timerProvider.status == TimerStatus.running) {
            print('Flutter: 计时器正在运行中，执行最小化');
            await _minimizeApp();
            return true;
          } else {
            print('Flutter: 计时器暂停中，返回主屏幕');
            // 停止计时器并返回主屏幕
            TimerScreen.handleGoBack(context);
            return true;
          }
        }

        // 默认行为：尝试弹出当前页面，如果不能弹出则退出应用
        print('Flutter: 执行默认返回行为');
        final canPop = Navigator.of(context).canPop();
        if (canPop) {
          print('Flutter: 弹出当前页面');
          Navigator.of(context).pop();
        } else {
          print('Flutter: 无法弹出页面，退出应用');
          SystemNavigator.pop();
        }
        return true;
      }
      return null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 监听应用生命周期变化
    print('生命周期状态改变: $state');
    if (state == AppLifecycleState.resumed) {
      // 应用恢复到前台，重置对话框状态
      _isDialogOpen = false;
    }
  }

  // 应用最小化方法
  Future<void> _minimizeApp() async {
    // 如果对话框打开，不执行最小化操作
    if (_isDialogOpen) {
      print('Flutter: 对话框开启中，忽略返回键');
      return;
    }

    try {
      print('Flutter: 尝试最小化应用');
      final result = await platform.invokeMethod('minimizeApp');
      print('Flutter: 最小化应用结果: $result');
    } catch (e) {
      print('Flutter: 无法最小化应用: $e');
      // 尝试备用方式最小化
      try {
        await SystemNavigator.pop(animated: true);
      } catch (e2) {
        print('Flutter: 备用最小化方法也失败: $e2');
      }
    }
  }

  // 执行系统返回操作
  Future<void> _performSystemBack() async {
    try {
      print('Flutter: 请求原生层执行系统返回操作');
      await platform.invokeMethod('performSystemBack');
    } catch (e) {
      print('Flutter: 执行系统返回操作失败: $e');
      // 尝试备用方法
      Navigator.maybePop(context);
    }
  }

  // 显示带有跟踪状态的对话框
  Future<T?> _showDialogWithTracking<T>(
    BuildContext context,
    Widget dialog,
  ) async {
    setState(() {
      _isDialogOpen = true;
    });

    try {
      return await showDialog<T>(
        context: context,
        builder: (context) => dialog,
      );
    } finally {
      // 确保对话框关闭后重置状态
      setState(() {
        _isDialogOpen = false;
      });
      print('Flutter: 对话框已关闭，恢复返回键处理');
    }
  }

  // 公开给其他类使用的API
  void setDialogOpen(bool isOpen) {
    if (mounted) {
      setState(() {
        _isDialogOpen = isOpen;
        print('Flutter: 对话框状态设置为: $_isDialogOpen');
      });
    }
  }

  // 设置计时器运行状态
  void setTimerRunning(bool isRunning) {
    if (mounted) {
      setState(() {
        _isTimerRunning = isRunning;
        print('Flutter: 计时器运行状态设置为: $_isTimerRunning');
      });
    }
  }

  bool get isDialogOpen => _isDialogOpen;
  bool get isTimerRunning => _isTimerRunning;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        print('Flutter: WillPopScope触发，当前计时器运行状态: $_isTimerRunning');

        // 优先顺序：对话框 > 计时器运行 > 计时器暂停 > 默认返回

        // 检查对话框状态
        if (_isDialogOpen || isDialogOpenGlobal) {
          print('Flutter: 对话框开启中，允许关闭对话框');
          return true; // 允许系统关闭对话框
        }

        // 检查计时器运行状态
        if (_isTimerRunning || isTimerRunningGlobal) {
          if (timerProvider.status == TimerStatus.running) {
            print('Flutter: 计时器正在运行中，执行最小化');
            await _minimizeApp();
            return false; // 不执行默认返回
          } else {
            print('Flutter: 计时器暂停中，返回主屏幕');
            TimerScreen.handleGoBack(context);
            return false; // 不执行默认返回
          }
        }

        // 默认行为：允许系统执行返回
        print('Flutter: 默认返回行为');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          actions: [
            // 只保留深色模式切换按钮
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: themeProvider.isDarkMode ? '切换至亮色模式' : '切换至深色模式',
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          // 允许随时滑动切换页面
          physics: const AlwaysScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          // 允许在计时器运行时也能使用底部导航栏切换
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.timer), label: '计时器'),
            NavigationDestination(icon: Icon(Icons.alarm), label: '闹钟'),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              label: '秒表',
            ),
            NavigationDestination(icon: Icon(Icons.person), label: '设置'),
          ],
        ),
      ),
    );
  }
}
