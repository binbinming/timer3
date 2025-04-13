import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_model.dart';
import 'screens/home_screen.dart';
import 'providers/timer_provider.dart';
import 'providers/alarm_provider.dart';
import 'providers/stopwatch_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const TimerApp(),
    );
  }
}

class TimerApp extends StatefulWidget {
  const TimerApp({super.key});

  @override
  State<TimerApp> createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  @override
  void initState() {
    super.initState();
    // 延迟初始化，等待context准备好
    Future.microtask(() {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      // 设置context
      timerProvider.setContext(context);
      settingsProvider.setContext(context);
      
      // 加载数据
      timerProvider.loadData();
      settingsProvider.loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: '时间管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: settingsProvider.themeMode,
      home: HomeScreen(key: homeScreenKey),
    );
  }
}

// 全局函数：添加新分类
// 不依赖任何context或Provider，避免状态管理问题
Future<void> showAddCategoryDialog(BuildContext context) async {
  String? newCategory;

  // 创建一个简单的独立对话框
  newCategory = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      // 使用内部状态管理
      final controller = TextEditingController();
      String? errorMessage;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('新建分类'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '分类名称',
                hintText: '请输入分类名称',
                errorText: errorMessage,
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setState(() => errorMessage = '分类名称不能为空');
                    return;
                  }
                  Navigator.of(dialogContext).pop(name);
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );

  // 如果获取到新分类名称，延迟处理它
  if (newCategory != null && newCategory.isNotEmpty) {
    // 在对话框完全关闭后异步添加分类
    Future.delayed(Duration.zero, () {
      // 获取TimerProvider实例并添加分类
      final provider = Provider.of<TimerProvider>(context, listen: false);
      provider.addCategory(newCategory!);

      // 通知分类已添加
      AppEvents().categoryAddedNotifier.value = newCategory;
    });
  }
}
