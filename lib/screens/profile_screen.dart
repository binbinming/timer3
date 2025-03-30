import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // 头像部分
          _buildHeader(context),

          const SizedBox(height: 20),

          // 设置列表
          _buildSettingsList(context),

          const SizedBox(height: 20),

          // 应用信息
          _buildAppInfo(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 头像
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.person,
              size: 60,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(height: 16),

          // 用户名
          Text('时间管理大师', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 8),

          // 用户标语
          Text(
            '珍惜时间，提高效率',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 设置标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '设置',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 深色模式设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('深色模式'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
        ),

        // 振动设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.vibration,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('振动'),
            trailing: Switch(
              value: true, // 默认开启，可以通过Provider来管理
              onChanged: (value) {
                // TODO: 实现振动开关逻辑
              },
            ),
          ),
        ),

        // 声音设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.volume_up,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('声音'),
            trailing: Switch(
              value: true, // 默认开启，可以通过Provider来管理
              onChanged: (value) {
                // TODO: 实现声音开关逻辑
              },
            ),
          ),
        ),

        // 通知设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('通知'),
            subtitle: const Text('允许应用发送通知'),
            trailing: Switch(
              value: true, // 默认开启，可以通过Provider来管理
              onChanged: (value) {
                // TODO: 实现通知开关逻辑
              },
            ),
          ),
        ),

        // 数据备份
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.backup,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('数据备份'),
            subtitle: const Text('备份计时器和闹钟数据'),
            onTap: () {
              // TODO: 实现数据备份逻辑
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('数据备份功能即将上线')));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 关于标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '关于',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 应用版本
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('版本'),
            subtitle: const Text('1.0.0'),
          ),
        ),

        // 隐私政策
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('隐私政策'),
            onTap: () {
              // TODO: 实现隐私政策跳转逻辑
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('隐私政策页面即将上线')));
            },
          ),
        ),

        // 用户协议
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('用户协议'),
            onTap: () {
              // TODO: 实现用户协议跳转逻辑
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('用户协议页面即将上线')));
            },
          ),
        ),
      ],
    );
  }
}
